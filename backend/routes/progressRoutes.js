const express = require('express');
const router = express.Router();
const { pool } = require('../config/db');
const { buildSkillGapActions, detectCvLanguage } = require('../services/ruleBasedService');

function resolveDeviceId(req) {
  const fromHeader = req.headers['x-device-id'];
  const fromBody = req.body && req.body.deviceId;
  const fromQuery = req.query && req.query.deviceId;
  const raw = fromHeader || fromBody || fromQuery || 'default-device';
  return String(raw).trim().slice(0, 128) || 'default-device';
}

function parseJsonSafe(val, fallback) {
  if (!val) return fallback;
  if (typeof val === 'object') return val;
  try {
    return JSON.parse(val);
  } catch {
    return fallback;
  }
}

const ISSUE_QUEST_TEMPLATES = {
  no_metrics: {
    questKey: 'q_fix_no_metrics',
    title: 'Add measurable results to 3 bullets',
    description: 'Include concrete numbers, percentages, or scale metrics in your CV bullets and re-scan to verify.',
  },
  duties: {
    questKey: 'q_fix_duties',
    title: 'Rewrite passive duties into action-driven STAR bullets',
    description: 'Replace passive "Responsible for..." lines with strong action verbs and outcomes, then re-scan.',
  },
  missing_core_keywords: {
    questKey: 'q_fix_missing_keywords',
    title: 'Add missing target role keywords to your CV',
    description: 'Incorporate key competencies from your Skill Gap list into your CV and verify with a re-scan.',
  },
  missing_keywords: {
    questKey: 'q_fix_missing_keywords',
    title: 'Add missing target role keywords to your CV',
    description: 'Incorporate key competencies from your Skill Gap list into your CV and verify with a re-scan.',
  },
  cliche_words: {
    questKey: 'q_fix_cliche_words',
    title: 'Replace generic clichés with concrete evidence',
    description: 'Remove subjective phrases ("hard-working", "under pressure") and verify with a re-scan.',
  },
  cliches: {
    questKey: 'q_fix_cliche_words',
    title: 'Replace generic clichés with concrete evidence',
    description: 'Remove subjective phrases ("hard-working", "under pressure") and verify with a re-scan.',
  },
  too_short: {
    questKey: 'q_fix_too_short',
    title: 'Expand CV content depth (150+ words)',
    description: 'Add 3–4 detailed achievement bullets per role or project and verify with a re-scan.',
  },
};

const BIAS_ISSUE_KEYS = new Set([
  'photo',
  'dob_age',
  'dob_marital',
  'marital_status',
  'religion',
  'national_id',
]);

/**
 * Synchronize quests, score history, and skill gap for a deviceId from MySQL.
 */
async function syncAndLoadProgress(deviceId) {
  // 1. Ensure career_profiles entry exists
  await pool.execute(
    `INSERT INTO career_profiles (device_id)
     VALUES (?)
     ON DUPLICATE KEY UPDATE device_id = device_id`,
    [deviceId]
  );

  const [profileRows] = await pool.execute(
    `SELECT * FROM career_profiles WHERE device_id = ? LIMIT 1`,
    [deviceId]
  );
  const profileRow = profileRows[0] || {
    device_id: deviceId,
    display_name: 'Ijul',
    target_role: 'Fresh Graduate Professional',
    career_mode: 'job_hunt',
    hired_at: null,
    last_win_logged_at: null,
  };

  // 2. Load chronological scans + issues + keywords for this device
  const [scanRows] = await pool.execute(
    `SELECT id, scan_token, file_name, overall_score, summary, created_at
     FROM scans
     WHERE device_id = ?
     ORDER BY created_at ASC, id ASC`,
    [deviceId]
  );

  const scanIds = scanRows.map((s) => s.id);
  const issuesByScanId = new Map();
  const keywordsByScanId = new Map();

  if (scanIds.length > 0) {
    const placeholders = scanIds.map(() => '?').join(',');
    const [issueRows] = await pool.execute(
      `SELECT scan_id, issue_key, category, severity, title
       FROM scan_issues
       WHERE scan_id IN (${placeholders})
       ORDER BY id ASC`,
      scanIds
    );
    for (const ir of issueRows) {
      if (!issuesByScanId.has(ir.scan_id)) {
        issuesByScanId.set(ir.scan_id, []);
      }
      issuesByScanId.get(ir.scan_id).push({
        key: ir.issue_key,
        category: ir.category,
        severity: ir.severity,
        title: ir.title,
      });
    }

    const [kwRows] = await pool.execute(
      `SELECT scan_id, job_title, matched_keywords, missing_keywords
       FROM scan_keywords
       WHERE scan_id IN (${placeholders})
       ORDER BY id ASC`,
      scanIds
    );
    for (const kr of kwRows) {
      keywordsByScanId.set(kr.scan_id, {
        jobTitle: kr.job_title || 'Professional',
        matched: parseJsonSafe(kr.matched_keywords, []),
        missing: parseJsonSafe(kr.missing_keywords, []),
      });
    }
  }

  // 3. Build chronological score history with fixedIssues diff between versions
  const scoreHistory = [];
  for (let i = 0; i < scanRows.length; i++) {
    const row = scanRows[i];
    const currentIssues = issuesByScanId.get(row.id) || [];
    const currentKeys = currentIssues.map((iss) => iss.key);
    const currentKeySet = new Set(currentKeys);
    const kw = keywordsByScanId.get(row.id);

    let fixedIssues = [];
    let scoreDelta = 0;
    if (i > 0) {
      const prevRow = scanRows[i - 1];
      const prevIssues = issuesByScanId.get(prevRow.id) || [];
      scoreDelta = row.overall_score - prevRow.overall_score;
      fixedIssues = prevIssues
        .filter((prevIss) => !currentKeySet.has(prevIss.key))
        .map((prevIss) => ({
          key: prevIss.key,
          title: prevIss.title,
          category: prevIss.category,
        }));
    }

    scoreHistory.push({
      scanToken: row.scan_token,
      fileName: row.file_name,
      overallScore: row.overall_score,
      scoreDelta,
      language: detectCvLanguage(row.summary || ''),
      jobTitle: kw ? kw.jobTitle : profileRow.target_role,
      issueCount: currentIssues.length,
      issueKeys: currentKeys,
      issues: currentIssues,
      fixedIssues,
      createdAt: row.created_at,
    });
  }

  const scoreTimeline = scoreHistory.map((s) => s.overallScore);
  const timelineLabel = scoreTimeline.join(' -> ');

  // 4. Check wins count for win-verified quests
  const [winStatsRows] = await pool.execute(
    `SELECT COUNT(*) AS totalWins,
            SUM(CASE WHEN merged_into_scan_token IS NOT NULL THEN 1 ELSE 0 END) AS mergedWins
     FROM work_wins
     WHERE device_id = ?`,
    [deviceId]
  );
  const totalWins = Number(winStatsRows[0]?.totalWins || 0);
  const mergedWins = Number(winStatsRows[0]?.mergedWins || 0);

  // 5. Compute verified status for scan_verified and win_verified quests
  const hasScanned = scoreHistory.length >= 1;
  const latestScan = hasScanned ? scoreHistory[scoreHistory.length - 1] : null;
  const latestKeySet = new Set(latestScan ? latestScan.issueKeys : []);

  const hasBiasIssueInLatest = latestScan
    ? latestScan.issues.some(
        (iss) => iss.category === 'personal_info' || BIAS_ISSUE_KEYS.has(iss.key)
      )
    : true;
  const isBiasPurged = hasScanned && !hasBiasIssueInLatest;

  // Base quests to upsert
  const questsToUpsert = [
    // Job Hunt: Core Scan-Verified Quests
    {
      questKey: 'q_first_scan',
      title: 'Run Your First ATS Scan',
      description: 'Upload your CV PDF in the Scanner to benchmark your ATS score and detect hidden issues.',
      careerMode: 'job_hunt',
      verificationType: 'scan_verified',
      linkedIssueKey: null,
      isCompleted: hasScanned,
    },
    {
      questKey: 'q_purge_bias',
      title: 'Purge Personal Bias Data',
      description: 'Remove headshot photo, Date of Birth (TTL), Religion, Marital Status, and NIK — verified automatically by scan.',
      careerMode: 'job_hunt',
      verificationType: 'scan_verified',
      linkedIssueKey: 'personal_info',
      isCompleted: isBiasPurged,
    },
  ];

  // Dynamic issue quests from scan history
  const everSeenIssueFirstScore = new Map();
  for (const scan of scoreHistory) {
    for (const key of scan.issueKeys) {
      if (ISSUE_QUEST_TEMPLATES[key] && !everSeenIssueFirstScore.has(key)) {
        everSeenIssueFirstScore.set(key, scan.overallScore);
      }
    }
  }

  for (const [issueKey, firstScore] of everSeenIssueFirstScore.entries()) {
    const tpl = ISSUE_QUEST_TEMPLATES[issueKey];
    const issueGoneInLatest = hasScanned && !latestKeySet.has(issueKey);
    const scoreImprovedAndGone =
      issueGoneInLatest && latestScan.overallScore >= firstScore;

    questsToUpsert.push({
      questKey: tpl.questKey,
      title: tpl.title,
      description: tpl.description,
      careerMode: 'job_hunt',
      verificationType: 'scan_verified',
      linkedIssueKey: issueKey,
      isCompleted: scoreImprovedAndGone,
    });
  }

  // If user has never scanned yet, seed default scan-verified issue quest ('Add measurable results to 3 bullets')
  if (!hasScanned) {
    questsToUpsert.push({
      questKey: 'q_fix_no_metrics',
      title: 'Add measurable results to 3 bullets',
      description: 'Include concrete numbers, percentages, or scale metrics in your CV bullets and re-scan to verify.',
      careerMode: 'job_hunt',
      verificationType: 'scan_verified',
      linkedIssueKey: 'no_metrics',
      isCompleted: false,
    });
  }

  // Job Hunt: Secondary Self-Reported Quests
  const selfReportedJobHuntQuests = [
    {
      questKey: 'q_self_linkedin',
      title: 'Update LinkedIn headline with target role keywords',
      description: 'Align your LinkedIn headline and summary with the matched keywords from your CV scan.',
      careerMode: 'job_hunt',
    },
    {
      questKey: 'q_self_portfolio',
      title: 'Showcase 3 documented projects or portfolio samples',
      description: 'Highlight 3 real projects (case studies, GitHub repos, campaigns, or models) with clear outcomes.',
      careerMode: 'job_hunt',
    },
    {
      questKey: 'q_self_applications',
      title: 'Send 5 tailored job applications',
      description: 'Apply to 5 target roles using your newly exported ATS-ready PDF CV.',
      careerMode: 'job_hunt',
    },
  ];

  // Hired Mode: First 90 Days Checklist
  const hiredWinVerifiedQuests = [
    {
      questKey: 'hired_log_first_win',
      title: 'Log your first work win in the Brag Doc',
      description: 'Record a real deliverable in the Wins tab to generate a Zero-Hallucination STAR bullet.',
      careerMode: 'hired',
      verificationType: 'win_verified',
      linkedIssueKey: null,
      isCompleted: totalWins >= 1,
    },
    {
      questKey: 'hired_merge_win_cv',
      title: 'Merge a logged work win into your living CV',
      description: 'Use "Add to my CV" in the Wins tab so your CV stays updated while employed.',
      careerMode: 'hired',
      verificationType: 'win_verified',
      linkedIssueKey: null,
      isCompleted: mergedWins >= 1,
    },
  ];

  const selfReportedHiredQuests = [
    {
      questKey: 'hired_align_goals',
      title: 'Meet manager & define 30/60/90-day goals',
      description: 'Align on clear expectations, KPIs, and first-quarter priorities with your manager.',
      careerMode: 'hired',
    },
    {
      questKey: 'hired_first_deliverable',
      title: 'Document your first completed project or workflow',
      description: 'Capture the problem solved, tools used, and measurable outcome of your first task.',
      careerMode: 'hired',
    },
    {
      questKey: 'hired_30day_feedback',
      title: 'Request 30-day feedback from your manager or peer',
      description: 'Ask for early feedback on execution, communication, and collaboration.',
      careerMode: 'hired',
    },
  ];

  // Upsert verified quests (always reflects real scan/win state)
  for (const q of [...questsToUpsert, ...hiredWinVerifiedQuests]) {
    await pool.execute(
      `INSERT INTO career_quests
        (device_id, quest_key, title, description, career_mode, verification_type, linked_issue_key, is_completed, completed_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE
        title = VALUES(title),
        description = VALUES(description),
        verification_type = VALUES(verification_type),
        linked_issue_key = VALUES(linked_issue_key),
        is_completed = VALUES(is_completed),
        completed_at = CASE WHEN VALUES(is_completed) = TRUE THEN COALESCE(completed_at, NOW()) ELSE NULL END`,
      [
        deviceId,
        q.questKey,
        q.title,
        q.description,
        q.careerMode,
        q.verificationType,
        q.linkedIssueKey,
        q.isCompleted,
        q.isCompleted ? new Date() : null,
      ]
    );
  }

  // Insert self-reported quests without overwriting existing completion state
  for (const sq of [...selfReportedJobHuntQuests, ...selfReportedHiredQuests]) {
    await pool.execute(
      `INSERT INTO career_quests
        (device_id, quest_key, title, description, career_mode, verification_type, linked_issue_key, is_completed)
       VALUES (?, ?, ?, ?, ?, 'self_reported', NULL, FALSE)
       ON DUPLICATE KEY UPDATE
        title = VALUES(title),
        description = VALUES(description)`,
      [deviceId, sq.questKey, sq.title, sq.description, sq.careerMode]
    );
  }

  // Load all quests for device
  const [questRows] = await pool.execute(
    `SELECT quest_key, title, description, career_mode, verification_type, linked_issue_key, is_completed, completed_at
     FROM career_quests
     WHERE device_id = ?
     ORDER BY
       CASE verification_type
         WHEN 'scan_verified' THEN 1
         WHEN 'win_verified' THEN 2
         ELSE 3
       END,
       id ASC`,
    [deviceId]
  );

  const quests = questRows.map((qr) => ({
    id: qr.quest_key,
    questKey: qr.quest_key,
    title: qr.title,
    description: qr.description,
    careerMode: qr.career_mode,
    verificationType: qr.verification_type,
    verificationLabel:
      qr.verification_type === 'scan_verified'
        ? 'Verified by Scan'
        : qr.verification_type === 'win_verified'
          ? 'Verified by Win'
          : 'Self-reported',
    linkedIssueKey: qr.linked_issue_key,
    isCompleted: Boolean(qr.is_completed),
    completedAt: qr.completed_at,
  }));

  const activeMode = profileRow.career_mode || 'job_hunt';
  const modeQuests = quests.filter((q) => q.careerMode === activeMode);
  const completedCount = modeQuests.filter((q) => q.isCompleted).length;
  const totalCount = modeQuests.length;
  const progressFraction = totalCount > 0 ? completedCount / totalCount : 0;

  // 6. Build Skill Gap from latest scan's keywords (or default target role)
  let latestKw = null;
  let latestLang = 'en';
  if (scanRows.length > 0) {
    const lastScanRow = scanRows[scanRows.length - 1];
    latestKw = keywordsByScanId.get(lastScanRow.id);
    latestLang = detectCvLanguage(lastScanRow.summary || '');
  }

  const skillGap = buildSkillGapActions(
    latestKw ? latestKw.jobTitle : profileRow.target_role,
    latestKw ? latestKw.missing : [],
    latestKw ? latestKw.matched : [],
    latestLang
  );

  return {
    deviceId,
    profile: {
      displayName: profileRow.display_name,
      targetRole: latestKw ? latestKw.jobTitle : profileRow.target_role,
      careerMode: activeMode,
      hiredAt: profileRow.hired_at,
      lastWinLoggedAt: profileRow.last_win_logged_at,
    },
    scoreHistory,
    scoreTimeline,
    timelineLabel,
    quests,
    checklistSummary: {
      mode: activeMode,
      completedCount,
      totalCount,
      progressFraction,
      progressLabel: `${completedCount} of ${totalCount} done`,
    },
    skillGap,
  };
}

/**
 * GET /api/progress
 * Returns score history timeline, scan-verified + self-reported quests,
 * accurate checklist progress ("3 of 6 done"), and role-agnostic bilingual Skill Gap.
 */
router.get('/', async (req, res, next) => {
  try {
    const deviceId = resolveDeviceId(req);
    const progress = await syncAndLoadProgress(deviceId);
    res.status(200).json(progress);
  } catch (err) {
    next(err);
  }
});

/**
 * POST /api/progress/quest-toggle
 * Toggles a self-reported quest. Rejects manual toggling on scan_verified or win_verified quests.
 */
router.post('/quest-toggle', async (req, res, next) => {
  try {
    const deviceId = resolveDeviceId(req);
    const { questKey } = req.body || {};

    if (!questKey || typeof questKey !== 'string') {
      return res.status(400).json({
        error: 'questKey wajib disertakan.',
        code: 'QUEST_KEY_REQUIRED',
      });
    }

    await syncAndLoadProgress(deviceId);

    const [rows] = await pool.execute(
      `SELECT * FROM career_quests WHERE device_id = ? AND quest_key = ? LIMIT 1`,
      [deviceId, questKey]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        error: `Quest '${questKey}' tidak ditemukan.`,
        code: 'QUEST_NOT_FOUND',
      });
    }

    const quest = rows[0];
    if (quest.verification_type !== 'self_reported') {
      return res.status(400).json({
        error: 'Quest ini diverifikasi otomatis dari hasil scan CV atau pencatatan Win dan tidak dapat dicentang manual.',
        code: 'QUEST_NOT_MANUAL',
      });
    }

    const nextState = !Boolean(quest.is_completed);
    await pool.execute(
      `UPDATE career_quests
       SET is_completed = ?, completed_at = ?
       WHERE device_id = ? AND quest_key = ?`,
      [nextState, nextState ? new Date() : null, deviceId, questKey]
    );

    const updated = await syncAndLoadProgress(deviceId);
    res.status(200).json(updated);
  } catch (err) {
    next(err);
  }
});

/**
 * POST /api/progress/mode
 * Switches between 'job_hunt' and 'hired' ("I got the job" -> First 90 Days checklist).
 */
router.post('/mode', async (req, res, next) => {
  try {
    const deviceId = resolveDeviceId(req);
    const { mode, displayName, targetRole } = req.body || {};

    if (mode !== 'job_hunt' && mode !== 'hired') {
      return res.status(400).json({
        error: "Mode karir harus bernilai 'job_hunt' atau 'hired'.",
        code: 'INVALID_CAREER_MODE',
      });
    }

    await pool.execute(
      `INSERT INTO career_profiles (device_id, display_name, target_role, career_mode, hired_at)
       VALUES (?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE
        career_mode = VALUES(career_mode),
        display_name = COALESCE(?, display_name),
        target_role = COALESCE(?, target_role),
        hired_at = CASE WHEN VALUES(career_mode) = 'hired' THEN COALESCE(hired_at, NOW()) ELSE hired_at END`,
      [
        deviceId,
        displayName || 'Ijul',
        targetRole || 'Fresh Graduate Professional',
        mode,
        mode === 'hired' ? new Date() : null,
        displayName || null,
        targetRole || null,
      ]
    );

    const updated = await syncAndLoadProgress(deviceId);
    res.status(200).json({
      ...updated,
      badgeUnlocked:
        mode === 'hired'
          ? {
              id: 'b_first_job',
              title: 'Offer Secured!',
              description: 'Unlocked your First 90 Days onboarding checklist.',
            }
          : null,
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
module.exports.syncAndLoadProgress = syncAndLoadProgress;


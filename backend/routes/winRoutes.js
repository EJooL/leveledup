const express = require('express');
const router = express.Router();
const { pool } = require('../config/db');
const { generateStarBullet, mergeWinsIntoCvObject } = require('../services/aiWinService');
const { formatBilingualError, resolveRequestLanguage } = require('../services/bilingualValidation');

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

/**
 * GET /api/wins
 * Lists all saved Brag Doc wins for the user/device and checks whether the
 * 90-day periodic living-CV reminder should be shown.
 */
router.get('/', async (req, res, next) => {
  try {
    const deviceId = resolveDeviceId(req);
    const simulateReminder = req.query.simulateReminder === 'true';

    let wins = [];
    let lastWinLoggedAt = null;

    try {
      const [rows] = await pool.execute(
        `SELECT id, device_id, title, impact_metric, category, language, star_bullet, merged_into_scan_token, created_at
         FROM work_wins
         WHERE device_id = ?
         ORDER BY created_at DESC, id DESC`,
        [deviceId]
      );

      wins = rows.map((r) => ({
        id: String(r.id),
        deviceId: r.device_id,
        title: r.title,
        impactMetric: r.impact_metric || '',
        category: r.category || 'project_delivery',
        language: r.language || 'en',
        starBullet: r.star_bullet,
        mergedIntoScanToken: r.merged_into_scan_token || null,
        createdAt: r.created_at,
      }));

      if (wins.length > 0) {
        lastWinLoggedAt = wins[0].createdAt;
      } else {
        const [profRows] = await pool.execute(
          `SELECT last_win_logged_at FROM career_profiles WHERE device_id = ? LIMIT 1`,
          [deviceId]
        );
        if (profRows.length > 0 && profRows[0].last_win_logged_at) {
          lastWinLoggedAt = profRows[0].last_win_logged_at;
        }
      }
    } catch (dbErr) {
      console.warn(`[Database Warning] Could not query work_wins: ${dbErr.message}`);
    }

    const now = Date.now();
    const lastTs = lastWinLoggedAt ? new Date(lastWinLoggedAt).getTime() : null;
    const daysSinceLastWin = lastTs
      ? Math.floor((now - lastTs) / (1000 * 60 * 60 * 24))
      : null;

    const needsQuarterlyReminder =
      simulateReminder ||
      (daysSinceLastWin !== null && daysSinceLastWin >= 90) ||
      wins.length === 0;

    res.status(200).json({
      deviceId,
      wins,
      lastWinLoggedAt,
      daysSinceLastWin,
      needsQuarterlyReminder,
      reminderMessageEn: "It's been 3 months — any new wins? Log your latest achievements so your living CV stays ready.",
      reminderMessageId: 'Sudah 3 bulan berlalu — ada pencapaian baru? Catat sekarang agar CV Anda selalu siap setiap saat.',
    });
  } catch (err) {
    next(err);
  }
});

/**
 * POST /api/wins
 * Logs a new work/academic win, converts it to a Zero-Hallucination STAR bullet,
 * persists it in MySQL, and updates any win-verified onboarding quests.
 */
router.post('/', async (req, res, next) => {
  try {
    const deviceId = resolveDeviceId(req);
    const {
      title,
      impactMetric = '',
      category = 'project_delivery',
      language,
    } = req.body || {};

    if (!title || typeof title !== 'string' || title.trim().length < 3) {
      const reqLang = resolveRequestLanguage({
        language,
        text: typeof title === 'string' ? title : '',
        acceptLanguage: req.headers['accept-language'],
      });
      const { status, body } = formatBilingualError('WIN_TITLE_REQUIRED', reqLang);
      return res.status(status).json(body);
    }

    const cleanTitle = title.trim();
    const cleanImpact = typeof impactMetric === 'string' ? impactMetric.trim() : '';
    const validCategories = [
      'project_delivery',
      'metrics_growth',
      'process_quality',
      'leadership_teamwork',
    ];
    const cleanCategory = validCategories.includes(category)
      ? category
      : 'project_delivery';

    const generated = await generateStarBullet({
      title: cleanTitle,
      impactMetric: cleanImpact,
      category: cleanCategory,
      language,
    });

    let insertedId = Date.now();
    let isFirstWin = false;

    try {
      const [countRows] = await pool.execute(
        `SELECT COUNT(*) AS cnt FROM work_wins WHERE device_id = ?`,
        [deviceId]
      );
      isFirstWin = (countRows[0]?.cnt || 0) === 0;

      const [insertRes] = await pool.execute(
        `INSERT INTO work_wins (device_id, title, impact_metric, category, language, star_bullet)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [
          deviceId,
          cleanTitle,
          cleanImpact,
          cleanCategory,
          generated.language,
          generated.starBullet,
        ]
      );
      insertedId = insertRes.insertId;

      await pool.execute(
        `INSERT INTO career_profiles (device_id, last_win_logged_at)
         VALUES (?, NOW())
         ON DUPLICATE KEY UPDATE last_win_logged_at = NOW()`,
        [deviceId]
      );

      // Mark win-verified quest 'hired_log_first_win' complete if it exists
      await pool.execute(
        `UPDATE career_quests
         SET is_completed = TRUE, completed_at = COALESCE(completed_at, NOW())
         WHERE device_id = ? AND quest_key = 'hired_log_first_win'`,
        [deviceId]
      );
    } catch (dbErr) {
      console.warn(`[Database Warning] Could not save work win to MySQL: ${dbErr.message}`);
    }

    const win = {
      id: String(insertedId),
      deviceId,
      title: cleanTitle,
      impactMetric: cleanImpact,
      category: cleanCategory,
      language: generated.language,
      starBullet: generated.starBullet,
      hasPlaceholder: generated.hasPlaceholder,
      engine: generated.engine,
      mergedIntoScanToken: null,
      createdAt: new Date().toISOString(),
    };

    res.status(201).json({
      win,
      badgeUnlocked: isFirstWin
        ? {
            id: 'b_first_win',
            title: 'Impact Documented',
            description: 'Converted your first real achievement into an ATS-ready STAR bullet.',
          }
        : null,
    });
  } catch (err) {
    next(err);
  }
});

/**
 * POST /api/wins/merge-cv
 * Merges selected Brag Doc wins into the user's latest rewritten CV ("Add to my CV")
 * so they can immediately export an updated Word (.docx) CV.
 */
router.post('/merge-cv', async (req, res, next) => {
  try {
    const deviceId = resolveDeviceId(req);
    const {
      winIds = [],
      winBullets = [],
      scanToken = null,
      cv: providedCv = null,
      language = 'en',
    } = req.body || {};

    let winsToMerge = [];

    // 1. Load selected wins from MySQL if winIds provided
    if (Array.isArray(winIds) && winIds.length > 0) {
      try {
        const placeholders = winIds.map(() => '?').join(',');
        const [rows] = await pool.execute(
          `SELECT id, title, star_bullet, category, language
           FROM work_wins
           WHERE device_id = ? AND id IN (${placeholders})
           ORDER BY created_at DESC, id DESC`,
          [deviceId, ...winIds.map((id) => String(id).replace(/^w_/, ''))]
        );
        winsToMerge = rows.map((r) => ({
          id: String(r.id),
          title: r.title,
          starBullet: r.star_bullet,
          category: r.category,
          language: r.language,
        }));
      } catch (dbErr) {
        console.warn(`[Database Warning] Could not load selected wins for merge: ${dbErr.message}`);
      }
    }

    // 2. Fallback to winBullets passed directly in request body
    if (winsToMerge.length === 0 && Array.isArray(winBullets) && winBullets.length > 0) {
      winsToMerge = winBullets.map((b, i) =>
        typeof b === 'string'
          ? { id: `inline_${i}`, starBullet: b, language }
          : {
              id: String(b.id || `inline_${i}`),
              title: b.title || '',
              starBullet: b.starBullet || b.star_bullet || b.title || '',
              language: b.language || language,
            }
      );
    }

    // 3. If neither winIds nor winBullets matched, load the user's most recent wins
    if (winsToMerge.length === 0) {
      try {
        const [rows] = await pool.execute(
          `SELECT id, title, star_bullet, category, language
           FROM work_wins
           WHERE device_id = ?
           ORDER BY created_at DESC, id DESC
           LIMIT 5`,
          [deviceId]
        );
        winsToMerge = rows.map((r) => ({
          id: String(r.id),
          title: r.title,
          starBullet: r.star_bullet,
          category: r.category,
          language: r.language,
        }));
      } catch (dbErr) {
        console.warn(`[Database Warning] Could not load recent wins for merge: ${dbErr.message}`);
      }
    }

    if (winsToMerge.length === 0) {
      const reqLang = resolveRequestLanguage({
        language,
        acceptLanguage: req.headers['accept-language'],
      });
      const { status, body } = formatBilingualError('NO_WINS_SELECTED', reqLang);
      return res.status(status).json(body);
    }

    // 4. Resolve base CV to merge into (request body -> scan_rewrites by scanToken -> latest scan_rewrites for deviceId -> skeleton)
    let baseCv = providedCv;
    let targetScanId = null;
    let targetScanToken = scanToken;

    if (!baseCv) {
      try {
        let rewriteRows = [];
        if (scanToken) {
          const [rows] = await pool.execute(
            `SELECT sr.*, s.id AS s_id, s.scan_token
             FROM scan_rewrites sr
             JOIN scans s ON s.id = sr.scan_id
             WHERE s.scan_token = ?
             ORDER BY sr.created_at DESC, sr.id DESC
             LIMIT 1`,
            [scanToken]
          );
          rewriteRows = rows;
        }
        if (rewriteRows.length === 0) {
          const [rows] = await pool.execute(
            `SELECT sr.*, s.id AS s_id, s.scan_token
             FROM scan_rewrites sr
             JOIN scans s ON s.id = sr.scan_id
             WHERE s.device_id = ?
             ORDER BY sr.created_at DESC, sr.id DESC
             LIMIT 1`,
            [deviceId]
          );
          rewriteRows = rows;
        }

        if (rewriteRows.length > 0) {
          const row = rewriteRows[0];
          targetScanId = row.s_id;
          targetScanToken = row.scan_token;
          baseCv = {
            language: winsToMerge[0]?.language || language,
            name: row.applicant_name,
            title: row.applicant_title,
            contact: parseJsonSafe(row.contact_lines, []),
            summary: row.summary,
            sections: parseJsonSafe(row.sections, []),
            changes: parseJsonSafe(row.changes, []),
          };
        } else {
          // Check if user has a scan record so we can infer their target job title
          const [scanRows] = await pool.execute(
            `SELECT s.id, s.scan_token, sk.job_title, sk.matched_keywords
             FROM scans s
             LEFT JOIN scan_keywords sk ON sk.scan_id = s.id
             WHERE s.device_id = ?
             ORDER BY s.created_at DESC, s.id DESC
             LIMIT 1`,
            [deviceId]
          );
          if (scanRows.length > 0) {
            targetScanId = scanRows[0].id;
            targetScanToken = scanRows[0].scan_token;
            const matched = parseJsonSafe(scanRows[0].matched_keywords, []);
            const isId = (winsToMerge[0]?.language || language) === 'id';
            baseCv = {
              language: isId ? 'id' : 'en',
              name: 'Ijul',
              title: scanRows[0].job_title || 'Professional Candidate',
              contact: [
                'ijul@leveledup.id',
                '+62 812 XXXX XXXX',
                isId ? 'Indonesia' : 'Indonesia (Open to Remote)',
              ],
              summary: isId
                ? `Profesional di bidang ${scanRows[0].job_title || 'Industri'} dengan rekam jejak pencapaian terukur.`
                : `Results-driven ${scanRows[0].job_title || 'Professional'} with a track record of quantified achievements.`,
              sections: [
                {
                  heading: isId ? 'Pengalaman' : 'Experience',
                  type: 'experience',
                  entries: [
                    {
                      title: isId ? 'Pengalaman & Pencapaian Terbaru' : 'Recent Experience & Achievements',
                      date: isId ? 'Sekarang' : 'Present',
                      subtitle: '',
                      bullets: [],
                    },
                  ],
                  bullets: [],
                },
                {
                  heading: isId ? 'Keahlian' : 'Skills',
                  type: 'skills',
                  skillGroups: [
                    {
                      category: isId ? 'Keahlian Utama' : 'Core Skills',
                      items: matched.length > 0
                        ? matched.join(', ')
                        : (isId ? 'Manajemen Proyek, Analisis Data, Kolaborasi Tim' : 'Project Execution, Data Analysis, Team Collaboration'),
                    },
                  ],
                  bullets: matched.length > 0
                    ? [matched.join(', ')]
                    : [isId ? 'Manajemen Proyek, Analisis Data, Kolaborasi Tim' : 'Project Execution, Data Analysis, Team Collaboration'],
                },
              ],
              changes: [],
            };
          }
        }
      } catch (dbErr) {
        console.warn(`[Database Warning] Could not load base CV from DB: ${dbErr.message}`);
      }
    }

    const { cv: updatedCv, mergedCount } = mergeWinsIntoCvObject(baseCv, winsToMerge);
    const effectiveToken = targetScanToken || 'living_cv';

    // 5. Persist updated CV into scan_rewrites and mark wins as merged
    try {
      if (targetScanId) {
        await pool.execute(
          `INSERT INTO scan_rewrites
            (scan_id, applicant_name, applicant_title, contact_lines, summary, sections, changes)
           VALUES (?, ?, ?, ?, ?, ?, ?)`,
          [
            targetScanId,
            updatedCv.name,
            updatedCv.title,
            JSON.stringify(updatedCv.contact || []),
            updatedCv.summary || '',
            JSON.stringify(updatedCv.sections || []),
            JSON.stringify(updatedCv.changes || []),
          ]
        );
      }

      const numericWinIds = winsToMerge
        .map((w) => Number(String(w.id).replace(/^w_/, '')))
        .filter((n) => Number.isInteger(n) && n > 0);

      if (numericWinIds.length > 0) {
        const placeholders = numericWinIds.map(() => '?').join(',');
        await pool.execute(
          `UPDATE work_wins
           SET merged_into_scan_token = ?
           WHERE device_id = ? AND id IN (${placeholders})`,
          [effectiveToken, deviceId, ...numericWinIds]
        );
      }

      // Mark win-verified quest 'hired_merge_win_cv' complete
      await pool.execute(
        `UPDATE career_quests
         SET is_completed = TRUE, completed_at = COALESCE(completed_at, NOW())
         WHERE device_id = ? AND quest_key = 'hired_merge_win_cv'`,
        [deviceId]
      );
    } catch (dbErr) {
      console.warn(`[Database Warning] Could not persist merged CV state: ${dbErr.message}`);
    }

    res.status(200).json({
      cv: updatedCv,
      mergedCount,
      mergedWinIds: winsToMerge.map((w) => String(w.id)),
      scanToken: effectiveToken,
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;


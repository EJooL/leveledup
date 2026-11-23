const express = require('express');
const router = express.Router();
const { analyzeCv, computeCvContentHash } = require('../services/aiAnalysisService');
const { encryptToken, decryptToken, generateScanToken } = require('../services/tokenService');
const { formatBilingualError, resolveRequestLanguage, normalizeLanguage } = require('../services/bilingualValidation');
const { pool } = require('../config/db');

/**
 * Build a normalized analysis result object from an anchored MySQL scan row.
 */
function buildAnchoredResultFromRow(row, payload, { mode, expectedLang, fileName, contentHash }) {
  const lang = payload.language || expectedLang || 'en';
  const isId = lang === 'id';
  const missing = Array.isArray(payload.missingKeywords) ? payload.missingKeywords : [];
  const matched = Array.isArray(payload.matchedKeywords) ? payload.matchedKeywords : [];
  const engine = payload.engine || row.engine || 'gemini';

  return {
    mode: row.mode || mode || 'global',
    language: lang,
    overallScore: Number(payload.overallScore ?? row.overall_score),
    summary: payload.summary || row.summary || '',
    issues: Array.isArray(payload.issues) ? payload.issues : [],
    keywordMatch: {
      jobTitle: payload.jobTitle || 'Professional',
      matched,
      missing,
      missingCount: missing.length,
    },
    meta: {
      fileName,
      language: lang,
      analyzedAtLabel:
        engine === 'gemini'
          ? (isId ? 'Dianalisis AI Gemini (Bahasa Indonesia)' : 'Analyzed by Gemini AI (English)')
          : (isId ? 'Evaluasi Bahasa Indonesia' : 'English ATS Evaluation'),
      engine,
      contentHash,
      cachedAnchor: true,
    },
  };
}

/**
 * Look up previous scans with the exact same SHA-256 contentHash so re-uploading
 * an unchanged CV file returns a consistent score and feedback across sessions and
 * server restarts.
 *
 * Returns `{ geminiAnchor, ruleAnchor }` separately so a transient `rule-based`
 * fallback scan can NEVER poison or override an authoritative `gemini` analysis
 * or block future Gemini retries.
 */
async function findAnchoredScanInDb({ deviceId, contentHash, mode, expectedLang, fileName }) {
  if (!contentHash) return { geminiAnchor: null, ruleAnchor: null };
  try {
    const query = deviceId
      ? `SELECT overall_score, summary, mode, engine, encrypted_token
         FROM scans
         WHERE mode = ? AND encrypted_token IS NOT NULL
         ORDER BY CASE WHEN engine = 'gemini' THEN 0 ELSE 1 END ASC,
                  CASE WHEN device_id = ? THEN 0 ELSE 1 END ASC,
                  id DESC
         LIMIT 100`
      : `SELECT overall_score, summary, mode, engine, encrypted_token
         FROM scans
         WHERE mode = ? AND encrypted_token IS NOT NULL
         ORDER BY CASE WHEN engine = 'gemini' THEN 0 ELSE 1 END ASC,
                  id DESC
         LIMIT 100`;
    const params = deviceId ? [mode, deviceId] : [mode];

    const [rows] = await pool.execute(query, params);

    let geminiAnchor = null;
    let ruleAnchor = null;

    for (const row of rows) {
      try {
        const payload = decryptToken(row.encrypted_token);
        if (!payload || payload.contentHash !== contentHash) continue;
        if (expectedLang && payload.language && payload.language !== expectedLang) continue;

        const engine = payload.engine || row.engine || 'rule-based';
        if (engine === 'gemini') {
          if (!geminiAnchor) {
            geminiAnchor = buildAnchoredResultFromRow(row, payload, {
              mode,
              expectedLang,
              fileName,
              contentHash,
            });
            // Authoritative Gemini anchor found — no need to inspect older rows
            break;
          }
        } else if (!ruleAnchor) {
          ruleAnchor = buildAnchoredResultFromRow(row, payload, {
            mode,
            expectedLang,
            fileName,
            contentHash,
          });
        }
      } catch {
        // Ignore undecryptable legacy tokens
      }
    }

    return { geminiAnchor, ruleAnchor };
  } catch (err) {
    console.warn(`[Anchor Lookup Warning] Could not check prior scans in MySQL: ${err.message}`);
  }
  return { geminiAnchor: null, ruleAnchor: null };
}

/**
 * POST /api/analyze
 * Analyzes CV text against 5 global ATS standards, persists scan in MySQL,
 * and returns the free preview result along with an AES-256 encrypted token.
 */
router.post('/', async (req, res, next) => {
  try {
    const {
      text,
      fileName = 'CV.pdf',
      deviceId = null,
      numPages = 1,
      hasPhoto = false,
      language,
      mode = 'global',
      region = null,
    } = req.body;
    const effectiveDeviceId = deviceId || req.headers['x-device-id'] || null;

    if (!text || typeof text !== 'string' || text.trim().length < 80) {
      const lang = resolveRequestLanguage({
        language,
        text: typeof text === 'string' ? text : '',
        acceptLanguage: req.headers['accept-language'],
      });
      const { status, body } = formatBilingualError('TEXT_TOO_SHORT', lang);
      return res.status(status).json(body);
    }

    const cleanText = text.trim();
    const cleanFileName = (typeof fileName === 'string' && fileName.trim()) ? fileName.trim() : 'CV.pdf';
    const normalizedMode = (typeof mode === 'string' && mode.trim()) ? mode.trim().toLowerCase() : 'global';
    const normalizedRegion = (typeof region === 'string' && region.trim()) ? region.trim().toLowerCase() : null;
    const explicitLang = language && String(language).toLowerCase() !== 'auto'
      ? normalizeLanguage(language, cleanText)
      : null;

    const contentHash = computeCvContentHash({
      text: cleanText,
      mode: normalizedMode,
      region: normalizedRegion,
      hasPhoto: Boolean(hasPhoto),
    });

    // Check DB anchor first (protects exact-content consistency across sessions & server restarts).
    // Always prioritize an authoritative Gemini anchor so a transient rule-based fallback
    // can never poison subsequent scans or prevent Gemini from retrying.
    const { geminiAnchor, ruleAnchor } = await findAnchoredScanInDb({
      deviceId: effectiveDeviceId,
      contentHash,
      mode: normalizedMode,
      expectedLang: explicitLang,
      fileName: cleanFileName,
    });

    let fullResult = geminiAnchor;

    if (!fullResult) {
      const analyzedResult = await analyzeCv(cleanText, cleanFileName, {
        hasPhoto: Boolean(hasPhoto),
        language: explicitLang || undefined,
        mode: normalizedMode,
        region: normalizedRegion,
      });

      const analyzedEngine = analyzedResult.meta ? analyzedResult.meta.engine : 'rule-based';
      if (analyzedEngine === 'gemini') {
        fullResult = analyzedResult;
      } else if (ruleAnchor) {
        // Gemini unavailable/offline: keep deterministic consistency with prior rule-based anchor
        fullResult = ruleAnchor;
      } else {
        fullResult = analyzedResult;
      }
    }

    const scanToken = generateScanToken();

    // Prepare encrypted token sealing the locked premium details + SHA-256 contentHash
    const sealedPayload = {
      scanToken,
      contentHash,
      language: fullResult.language || 'en',
      issues: fullResult.issues,
      missingKeywords: fullResult.keywordMatch ? fullResult.keywordMatch.missing : [],
      overallScore: fullResult.overallScore,
      summary: fullResult.summary,
      jobTitle: fullResult.keywordMatch ? fullResult.keywordMatch.jobTitle : '',
      matchedKeywords: fullResult.keywordMatch ? fullResult.keywordMatch.matched : [],
      fileName: cleanFileName,
      engine: fullResult.meta ? fullResult.meta.engine : 'rule-based',
    };
    const encryptedToken = encryptToken(sealedPayload);

    // Save scan to MySQL database
    try {
      const [scanInsert] = await pool.execute(
        `INSERT INTO scans 
          (scan_token, device_id, file_name, num_pages, num_chars, overall_score, summary, mode, engine, is_unlocked, encrypted_token)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          scanToken,
          effectiveDeviceId,
          cleanFileName,
          parseInt(numPages, 10) || 1,
          cleanText.length,
          fullResult.overallScore,
          fullResult.summary,
          normalizedMode,
          fullResult.meta ? fullResult.meta.engine : 'rule-based',
          false,
          encryptedToken,
        ]
      );

      const scanId = scanInsert.insertId;

      // Insert issues
      if (Array.isArray(fullResult.issues) && fullResult.issues.length > 0) {
        for (const issue of fullResult.issues) {
          await pool.execute(
            `INSERT INTO scan_issues 
              (scan_id, issue_key, category, severity, title, detail, fix, rewrite_before, rewrite_after)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [
              scanId,
              issue.id || 'general',
              issue.category || 'personal_info',
              issue.severity || 'warning',
              issue.title || '',
              issue.detail || null,
              issue.fix || null,
              issue.rewrite ? issue.rewrite.before : null,
              issue.rewrite ? issue.rewrite.after : null,
            ]
          );
        }
      }

      // Insert keywords
      if (fullResult.keywordMatch) {
        await pool.execute(
          `INSERT INTO scan_keywords 
            (scan_id, job_title, matched_keywords, missing_keywords)
           VALUES (?, ?, ?, ?)`,
          [
            scanId,
            fullResult.keywordMatch.jobTitle || 'Professional',
            JSON.stringify(fullResult.keywordMatch.matched || []),
            JSON.stringify(fullResult.keywordMatch.missing || []),
          ]
        );
      }
    } catch (dbErr) {
      console.warn(`[Database Warning] Could not persist scan to MySQL: ${dbErr.message}`);
      // Keep going to return result to user even if DB is momentarily unreachable
    }

    // Strip locked details for the Free Tier Preview
    const freeTierIssues = fullResult.issues.map((issue) => ({
      id: issue.id,
      category: issue.category,
      severity: issue.severity,
      title: issue.title,
    }));

    const freeTierResult = {
      mode: fullResult.mode || normalizedMode,
      language: fullResult.language || 'en',
      overallScore: fullResult.overallScore,
      summary: fullResult.summary,
      issues: freeTierIssues,
      keywordMatch: fullResult.keywordMatch ? {
        jobTitle: fullResult.keywordMatch.jobTitle,
        matched: fullResult.keywordMatch.matched,
        missingCount: fullResult.keywordMatch.missingCount,
      } : null,
      meta: {
        fileName: cleanFileName,
        language: fullResult.language || 'en',
        analyzedAtLabel: fullResult.meta ? fullResult.meta.analyzedAtLabel : 'Dianalisis Sistem',
        engine: fullResult.meta ? fullResult.meta.engine : 'rule-based',
        contentHash,
        cachedAnchor: Boolean(fullResult.meta && fullResult.meta.cachedAnchor),
      },
    };

    res.status(200).json({
      scanToken,
      result: freeTierResult,
      token: encryptedToken,
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;


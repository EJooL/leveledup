const express = require('express');
const router = express.Router();
const { analyzeCv } = require('../services/aiAnalysisService');
const { encryptToken, generateScanToken } = require('../services/tokenService');
const { pool } = require('../config/db');

/**
 * POST /api/analyze
 * Analyzes CV text against 5 global ATS standards, persists scan in MySQL,
 * and returns the free preview result along with an AES-256 encrypted token.
 */
router.post('/', async (req, res, next) => {
  try {
    const { text, fileName = 'CV.pdf', deviceId = null, numPages = 1 } = req.body;

    if (!text || typeof text !== 'string' || text.trim().length < 80) {
      return res.status(400).json({
        error: 'Teks CV tidak valid atau terlalu pendek (minimal 80 karakter teks diperlukan untuk analisis).',
        code: 'TEXT_TOO_SHORT',
      });
    }

    const cleanText = text.trim();
    const cleanFileName = (typeof fileName === 'string' && fileName.trim()) ? fileName.trim() : 'CV.pdf';

    // Run ATS analysis (Gemini or Rule-Based heuristic)
    const fullResult = await analyzeCv(cleanText, cleanFileName);
    const scanToken = generateScanToken();

    // Prepare encrypted token sealing the locked premium details
    const sealedPayload = {
      scanToken,
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
          deviceId || null,
          cleanFileName,
          parseInt(numPages, 10) || 1,
          cleanText.length,
          fullResult.overallScore,
          fullResult.summary,
          'global',
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
      mode: fullResult.mode || 'global',
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
        analyzedAtLabel: fullResult.meta ? fullResult.meta.analyzedAtLabel : 'Dianalisis Sistem',
        engine: fullResult.meta ? fullResult.meta.engine : 'rule-based',
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


const express = require('express');
const router = express.Router();
const { decryptToken } = require('../services/tokenService');
const { pool } = require('../config/db');

/**
 * POST /api/unlock
 * Unlocks full ATS issue details and missing keywords using an access code.
 */
router.post('/', async (req, res, next) => {
  try {
    const { scanToken, token, code } = req.body;

    if (!code || typeof code !== 'string' || !code.trim()) {
      return res.status(400).json({
        error: 'Kode akses wajib diisi.',
        code: 'CODE_REQUIRED',
      });
    }

    const cleanCode = code.trim().toUpperCase();

    // 1. Verify access code against MySQL database
    let isValidCode = false;
    let accessCodeRow = null;

    try {
      const [rows] = await pool.execute(
        `SELECT * FROM access_codes 
         WHERE BINARY code = ? AND is_active = TRUE 
         LIMIT 1`,
        [cleanCode]
      );

      if (rows && rows.length > 0) {
        accessCodeRow = rows[0];

        // Check quota
        if (accessCodeRow.times_used >= accessCodeRow.max_uses) {
          return res.status(402).json({
            error: 'Batas kuota pemakaian kode akses ini telah habis.',
            code: 'CODE_EXHAUSTED',
          });
        }

        // Check expiration
        if (accessCodeRow.expires_at && new Date(accessCodeRow.expires_at) < new Date()) {
          return res.status(402).json({
            error: 'Masa berlaku kode akses ini telah kedaluwarsa.',
            code: 'CODE_EXPIRED',
          });
        }

        isValidCode = true;
      }
    } catch (dbErr) {
      console.warn(`[Database Warning] Access code DB query error: ${dbErr.message}`);
      // Fallback check for default code if DB is temporarily unreachable
      if (cleanCode === 'LEVELEDUPVIP2026') {
        isValidCode = true;
      }
    }

    if (!isValidCode) {
      return res.status(402).json({
        error: 'Kode akses tidak valid atau tidak ditemukan.',
        code: 'INVALID_ACCESS_CODE',
      });
    }

    // 2. Decrypt token or fetch from database
    let decryptedData = null;
    if (token) {
      decryptedData = decryptToken(token);
    }

    let fullIssues = [];
    let missingKeywords = [];
    let matchedKeywords = [];
    let jobTitle = 'Professional';
    let overallScore = 70;
    let summary = 'Laporan analisis lengkap CV Anda.';
    let fileName = 'CV.pdf';
    let engine = 'rule-based';

    if (decryptedData && typeof decryptedData === 'object') {
      fullIssues = decryptedData.issues || [];
      missingKeywords = decryptedData.missingKeywords || [];
      matchedKeywords = decryptedData.matchedKeywords || [];
      jobTitle = decryptedData.jobTitle || 'Professional';
      overallScore = decryptedData.overallScore || 70;
      summary = decryptedData.summary || '';
      fileName = decryptedData.fileName || 'CV.pdf';
      engine = decryptedData.engine || 'rule-based';
    } else if (scanToken) {
      // Attempt to load full details from MySQL
      try {
        const [scans] = await pool.execute(
          `SELECT * FROM scans WHERE scan_token = ? LIMIT 1`,
          [scanToken]
        );
        if (scans && scans.length > 0) {
          const s = scans[0];
          overallScore = s.overall_score;
          summary = s.summary;
          fileName = s.file_name;
          engine = s.engine;

          const [issues] = await pool.execute(
            `SELECT * FROM scan_issues WHERE scan_id = ?`,
            [s.id]
          );
          fullIssues = issues.map((i) => ({
            id: i.issue_key,
            category: i.category,
            severity: i.severity,
            title: i.title,
            detail: i.detail,
            fix: i.fix,
            rewrite: (i.rewrite_before || i.rewrite_after) ? {
              before: i.rewrite_before || '',
              after: i.rewrite_after || '',
            } : null,
          }));

          const [kw] = await pool.execute(
            `SELECT * FROM scan_keywords WHERE scan_id = ? LIMIT 1`,
            [s.id]
          );
          if (kw && kw.length > 0) {
            jobTitle = kw[0].job_title;
            matchedKeywords = typeof kw[0].matched_keywords === 'string' ? JSON.parse(kw[0].matched_keywords) : kw[0].matched_keywords;
            missingKeywords = typeof kw[0].missing_keywords === 'string' ? JSON.parse(kw[0].missing_keywords) : kw[0].missing_keywords;
          }
        }
      } catch (loadErr) {
        console.warn(`[Database Warning] Could not load scan by token from DB: ${loadErr.message}`);
      }
    }

    if (fullIssues.length === 0 && (!decryptedData || !decryptedData.issues)) {
      return res.status(400).json({
        error: 'Token analisis tidak valid atau kadaluwarsa.',
        code: 'INVALID_TOKEN',
      });
    }

    // 3. Increment code usage and mark scan as unlocked in MySQL
    try {
      if (accessCodeRow) {
        await pool.execute(
          `UPDATE access_codes SET times_used = times_used + 1 WHERE id = ?`,
          [accessCodeRow.id]
        );
      }
      if (scanToken) {
        await pool.execute(
          `UPDATE scans SET is_unlocked = TRUE, unlock_code_used = ? WHERE scan_token = ?`,
          [cleanCode, scanToken]
        );
      }
    } catch (updErr) {
      console.warn(`[Database Warning] Could not update scan unlock status in DB: ${updErr.message}`);
    }

    // 4. Return complete Unlocked AnalysisResult
    const unlockedResult = {
      mode: 'global',
      overallScore,
      summary,
      issues: fullIssues,
      keywordMatch: {
        jobTitle,
        matched: matchedKeywords,
        missing: missingKeywords,
      },
      meta: {
        fileName,
        analyzedAtLabel: 'Dianalisis Sistem (Akses Penuh)',
        engine,
      },
    };

    res.status(200).json(unlockedResult);
  } catch (err) {
    next(err);
  }
});

module.exports = router;

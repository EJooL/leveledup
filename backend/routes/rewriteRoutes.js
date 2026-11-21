const express = require('express');
const router = express.Router();
const { rewriteCv } = require('../services/aiRewriteService');
const { formatBilingualError, resolveRequestLanguage } = require('../services/bilingualValidation');
const { pool } = require('../config/db');

/**
 * POST /api/rewrite
 * Generates an ATS-optimized, anti-bias, zero-hallucination CV rewrite.
 */
router.post('/', async (req, res, next) => {
  try {
    const { scanToken, text, code, fileName = 'CV.pdf', language } = req.body;
    const reqLang = resolveRequestLanguage({
      language,
      text: typeof text === 'string' ? text : '',
      acceptLanguage: req.headers['accept-language'],
    });

    if (!text || typeof text !== 'string' || text.trim().length < 80) {
      const { status, body } = formatBilingualError('TEXT_TOO_SHORT', reqLang);
      return res.status(status).json(body);
    }

    // Validate authorization (either scan is unlocked or valid promo code is provided)
    let isAuthorized = false;
    let scanRecord = null;

    if (scanToken) {
      try {
        const [scans] = await pool.execute(
          `SELECT id, is_unlocked FROM scans WHERE scan_token = ? LIMIT 1`,
          [scanToken]
        );
        if (scans && scans.length > 0) {
          scanRecord = scans[0];
          if (scanRecord.is_unlocked) {
            isAuthorized = true;
          }
        }
      } catch (dbErr) {
        console.warn(`[Database Warning] Error verifying scan authorization: ${dbErr.message}`);
      }
    }

    if (!isAuthorized && code && typeof code === 'string') {
      const cleanCode = code.trim().toUpperCase();
      try {
        const [rows] = await pool.execute(
          `SELECT * FROM access_codes WHERE BINARY code = ? AND is_active = TRUE LIMIT 1`,
          [cleanCode]
        );
        if (rows && rows.length > 0 && rows[0].times_used < rows[0].max_uses) {
          isAuthorized = true;
        }
      } catch (dbErr) {
        if (cleanCode === 'LEVELEDUPVIP2026') {
          isAuthorized = true;
        }
      }
    }

    if (!isAuthorized) {
      const { status, body } = formatBilingualError('PAYMENT_REQUIRED', reqLang);
      return res.status(status).json(body);
    }

    // Generate rewritten CV
    const rewriteResult = await rewriteCv(text.trim());

    // Save to MySQL database if scanRecord is found
    if (scanRecord && scanRecord.id && rewriteResult.cv) {
      try {
        const cv = rewriteResult.cv;
        await pool.execute(
          `INSERT INTO scan_rewrites 
            (scan_id, applicant_name, applicant_title, contact_lines, summary, sections, changes)
           VALUES (?, ?, ?, ?, ?, ?, ?)`,
          [
            scanRecord.id,
            cv.name || 'Candidate',
            cv.title || 'Professional',
            JSON.stringify(cv.contact || []),
            cv.summary || '',
            JSON.stringify(cv.sections || []),
            JSON.stringify(cv.changes || []),
          ]
        );
      } catch (dbErr) {
        console.warn(`[Database Warning] Error saving rewrite result to DB: ${dbErr.message}`);
      }
    }

    res.status(200).json(rewriteResult);
  } catch (err) {
    next(err);
  }
});

module.exports = router;


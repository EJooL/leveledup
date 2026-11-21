const express = require('express');
const router = express.Router();
const upload = require('../middleware/upload');
const { parsePdfBuffer } = require('../services/pdfService');
const { formatBilingualError, resolveRequestLanguage } = require('../services/bilingualValidation');

/**
 * POST /api/parse
 * Accepts a PDF file upload (up to 4MB) and returns extracted text, page count, and embedded photo flag.
 */
router.post('/', upload.single('file'), async (req, res, next) => {
  try {
    if (!req.file) {
      const lang = resolveRequestLanguage({
        language: req.body && req.body.language,
        acceptLanguage: req.headers['accept-language'],
      });
      const { status, body } = formatBilingualError('FILE_MISSING', lang);
      return res.status(status).json(body);
    }

    const { buffer, originalname } = req.file;
    const parsedData = await parsePdfBuffer(buffer, originalname);

    res.status(200).json({
      fileName: parsedData.fileName,
      numPages: parsedData.numPages,
      numChars: parsedData.numChars,
      hasPhoto: parsedData.hasPhoto,
      text: parsedData.text,
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;

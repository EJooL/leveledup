const express = require('express');
const router = express.Router();
const upload = require('../middleware/upload');
const { parsePdfBuffer } = require('../services/pdfService');

/**
 * POST /api/parse
 * Accepts a PDF file upload (up to 4MB) and returns extracted text and page count.
 */
router.post('/', upload.single('file'), async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        error: 'File tidak dikirim. Harap sertakan file PDF pada form-data dengan key "file".',
        code: 'FILE_MISSING',
      });
    }

    const { buffer, originalname } = req.file;
    const parsedData = await parsePdfBuffer(buffer, originalname);

    res.status(200).json({
      fileName: parsedData.fileName,
      numPages: parsedData.numPages,
      numChars: parsedData.numChars,
      text: parsedData.text,
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;

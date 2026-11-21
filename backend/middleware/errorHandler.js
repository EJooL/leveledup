const multer = require('multer');
const { formatBilingualError, resolveRequestLanguage } = require('../services/bilingualValidation');

function errorHandler(err, req, res, next) {
  const reqLang = resolveRequestLanguage({
    language: req && req.body && req.body.language,
    text: (req && req.body && (req.body.text || req.body.title)) || '',
    acceptLanguage: req && req.headers && req.headers['accept-language'],
  });

  // Handle Multer-specific errors
  if (err instanceof multer.MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      const { status, body } = formatBilingualError('FILE_TOO_LARGE', reqLang);
      return res.status(status).json(body);
    }
    const detail = err.message || 'Upload error';
    const errorEn = `File upload error: ${detail}`;
    const errorId = `Kesalahan upload berkas: ${detail}`;
    return res.status(400).json({
      error: reqLang === 'id' ? errorId : errorEn,
      errorEn,
      errorId,
      language: reqLang,
      code: err.code || 'UPLOAD_ERROR',
    });
  }

  // Handle custom status errors or general errors
  const status = err.status || 500;
  const code = err.code || (status === 500 ? 'INTERNAL_SERVER_ERROR' : 'BAD_REQUEST');

  if (status >= 500) {
    console.error('[Server Error]', err);
  }

  if (err.errorEn && err.errorId) {
    const lang = err.language || reqLang;
    return res.status(status).json({
      error: err.message || (lang === 'id' ? err.errorId : err.errorEn),
      errorEn: err.errorEn,
      errorId: err.errorId,
      language: lang,
      code,
    });
  }

  if (status === 500 && !err.message) {
    const { body } = formatBilingualError('INTERNAL_SERVER_ERROR', reqLang);
    return res.status(500).json(body);
  }

  const fallbackEn = err.message || 'An internal server error occurred.';
  const fallbackId = err.message || 'Terjadi kesalahan internal pada server.';
  res.status(status).json({
    error: reqLang === 'id' ? fallbackId : fallbackEn,
    errorEn: fallbackEn,
    errorId: fallbackId,
    language: reqLang,
    code,
  });
}

module.exports = errorHandler;


const multer = require('multer');

function errorHandler(err, req, res, next) {
  // Handle Multer-specific errors
  if (err instanceof multer.MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return res.status(413).json({
        error: 'Ukuran file melebihi batas maksimum 4 MB.',
        code: 'FILE_TOO_LARGE',
      });
    }
    return res.status(400).json({
      error: `Kesalahan upload berkas: ${err.message}`,
      code: err.code,
    });
  }

  // Handle custom status errors or general errors
  const status = err.status || 500;
  const message = err.message || 'Terjadi kesalahan internal pada server.';

  if (status >= 500) {
    console.error('[Server Error]', err);
  }

  res.status(status).json({
    error: message,
    code: err.code || (status === 500 ? 'INTERNAL_SERVER_ERROR' : 'BAD_REQUEST'),
  });
}

module.exports = errorHandler;


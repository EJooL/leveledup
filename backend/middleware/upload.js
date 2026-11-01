const multer = require('multer');
const path = require('path');

// Configure in-memory storage so raw PDF files are never persisted on disk
const storage = multer.memoryStorage();

const upload = multer({
  storage,
  limits: {
    fileSize: 4 * 1024 * 1024, // 4 MB limit
  },
  fileFilter: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const isPdfExt = ext === '.pdf';
    const isPdfMime = file.mimetype === 'application/pdf' || file.mimetype === 'application/x-pdf' || file.mimetype === 'application/octet-stream';

    if (isPdfExt && isPdfMime) {
      cb(null, true);
    } else {
      const err = new Error('Format file tidak didukung. Harap hanya unggah file berformat PDF (.pdf).');
      err.status = 415; // Unsupported Media Type
      cb(err, false);
    }
  },
});

module.exports = upload;

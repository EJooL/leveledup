const rateLimit = require('express-rate-limit');

const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP / device to 100 requests per windowMs
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => {
    // Check if client passed a deviceId header or body parameter, otherwise fall back to IP
    const deviceId = req.headers['x-device-id'] || (req.body && req.body.deviceId);
    if (deviceId && typeof deviceId === 'string' && deviceId.trim().length > 0) {
      return deviceId.trim();
    }
    return req.ip;
  },
  handler: (req, res) => {
    res.status(429).json({
      error: 'Terlalu banyak permintaan dari perangkat Anda. Silakan coba lagi dalam beberapa menit.',
      retryAfterMinutes: 15,
    });
  },
});

module.exports = {
  apiLimiter,
};


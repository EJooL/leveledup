/**
 * Shared Express route utilities for device resolution and safe JSON parsing.
 */

function resolveDeviceId(req) {
  const raw =
    req.headers['x-device-id'] ||
    (req.body && req.body.deviceId) ||
    (req.query && req.query.deviceId) ||
    'default-device';
  return String(raw).trim().slice(0, 128) || 'default-device';
}

function parseJsonSafe(val, fallback) {
  if (!val) return fallback;
  if (typeof val === 'object') return val;
  try {
    return JSON.parse(val);
  } catch {
    return fallback;
  }
}

module.exports = {
  resolveDeviceId,
  parseJsonSafe,
};

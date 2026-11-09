const crypto = require('crypto');
const dotenv = require('dotenv');

dotenv.config();

const SECRET_KEY_RAW = process.env.UNLOCK_SECRET || 'leveledup_secure_aes256_secret_key_2026_xyz';
// Derive a 32-byte key from secret
const SECRET_KEY = crypto.createHash('sha256').update(SECRET_KEY_RAW).digest();
const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 12; // Standard for GCM
const AUTH_TAG_LENGTH = 16;

/**
 * Encrypts an object or string into a base64url sealed token
 * @param {object|string} payload 
 * @returns {string} Base64URL-encoded token
 */
function encryptToken(payload) {
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv(ALGORITHM, SECRET_KEY, iv);
  
  const text = typeof payload === 'string' ? payload : JSON.stringify(payload);
  const encrypted = Buffer.concat([cipher.update(text, 'utf8'), cipher.final()]);
  const authTag = cipher.getAuthTag();

  // Format: iv (12 bytes) + authTag (16 bytes) + encryptedData
  const combined = Buffer.concat([iv, authTag, encrypted]);
  return combined.toString('base64url');
}

/**
 * Decrypts a base64url sealed token back to original object or string
 * @param {string} token 
 * @returns {object|string|null} Decrypted payload, or null if invalid
 */
function decryptToken(token) {
  try {
    const combined = Buffer.from(token, 'base64url');
    if (combined.length < IV_LENGTH + AUTH_TAG_LENGTH) {
      return null;
    }

    const iv = combined.subarray(0, IV_LENGTH);
    const authTag = combined.subarray(IV_LENGTH, IV_LENGTH + AUTH_TAG_LENGTH);
    const encryptedText = combined.subarray(IV_LENGTH + AUTH_TAG_LENGTH);

    const decipher = crypto.createDecipheriv(ALGORITHM, SECRET_KEY, iv);
    decipher.setAuthTag(authTag);

    const decrypted = Buffer.concat([decipher.update(encryptedText), decipher.final()]);
    const utf8Str = decrypted.toString('utf8');

    try {
      return JSON.parse(utf8Str);
    } catch {
      return utf8Str;
    }
  } catch (err) {
    console.error('[TokenService] Decryption failed:', err.message);
    return null;
  }
}

/**
 * Generates a unique scan token (e.g. scn_9f8e7d6c5b4a)
 * @returns {string}
 */
function generateScanToken() {
  const randomHex = crypto.randomBytes(8).toString('hex');
  return `scn_${randomHex}`;
}

module.exports = {
  encryptToken,
  decryptToken,
  generateScanToken,
};


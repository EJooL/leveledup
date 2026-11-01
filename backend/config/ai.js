const { GoogleGenAI } = require('@google/genai');
const dotenv = require('dotenv');

dotenv.config();

const apiKey = process.env.GEMINI_API_KEY || process.env.GOOGLE_GENAI_API_KEY;

let ai = null;
if (apiKey && apiKey.trim().length > 0) {
  try {
    ai = new GoogleGenAI({ apiKey: apiKey.trim() });
    console.log('[AI Config] Google GenAI SDK initialized successfully.');
  } catch (err) {
    console.warn('[AI Config Warning] Failed to initialize Google GenAI SDK:', err.message);
  }
} else {
  console.log('[AI Config] No GEMINI_API_KEY configured. Fallback to Rule-Based ATS heuristic engine is active.');
}

function isAiAvailable() {
  return ai !== null;
}

module.exports = {
  ai,
  isAiAvailable,
};

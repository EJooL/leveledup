const { ai, isAiAvailable } = require('../config/ai');
const { analyzeWithRules, inferJobRole, analyzeKeywords } = require('./ruleBasedService');
const { validateCvText, normalizeLanguage } = require('./bilingualValidation');
const {
  generateJsonWithGemini,
  hasExplicitPhotoEvidence,
  computeCvContentHash,
  calculateAtsScore,
  sanitizeAnalysisResult,
} = require('./aiGuardrails');

const ANALYSIS_TEMPERATURE = 0;
const ANALYSIS_TOP_P = 0.1;
const MAX_CACHE_ENTRIES = 250;
const CACHE_TTL_MS = 24 * 60 * 60 * 1000;

// Bounded in-memory SHA-256 consistency cache to prevent phantom score drift on unchanged CVs
const analysisCache = new Map();

function cloneResult(obj) {
  return structuredClone(obj);
}

function runRuleFallback(cleanText, fileName, { hasPhoto, lang, contentHash }) {
  const result = analyzeWithRules(cleanText, fileName, { hasPhoto, language: lang });
  if (result.meta) {
    result.meta.contentHash = contentHash;
    result.meta.cachedAnchor = false;
  }
  return result;
}

function getCachedAnalysis(cacheKey, fileName) {
  const entry = analysisCache.get(cacheKey);
  if (!entry) return null;
  if (Date.now() - entry.timestamp > CACHE_TTL_MS) {
    analysisCache.delete(cacheKey);
    return null;
  }
  // Refresh LRU order
  analysisCache.delete(cacheKey);
  analysisCache.set(cacheKey, entry);

  const cloned = cloneResult(entry.result);
  if (cloned.meta) {
    cloned.meta.fileName = fileName;
    cloned.meta.cachedAnchor = true;
  }
  return cloned;
}

function setCachedAnalysis(cacheKey, result) {
  if (analysisCache.has(cacheKey)) {
    analysisCache.delete(cacheKey);
  } else if (analysisCache.size >= MAX_CACHE_ENTRIES) {
    const oldestKey = analysisCache.keys().next().value;
    if (oldestKey !== undefined) {
      analysisCache.delete(oldestKey);
    }
  }
  analysisCache.set(cacheKey, {
    timestamp: Date.now(),
    result: cloneResult(result),
  });
}

function clearAnalysisCache() {
  analysisCache.clear();
}

function buildSystemInstruction(lang, hasPhoto) {
  const isId = lang === 'id';
  const langName = isId ? 'Bahasa Indonesia' : 'English';

  return `You are LeveledUp, an elite ATS (Applicant Tracking System) CV auditor and career coach.

LANGUAGE RULE (CRITICAL):
The uploaded CV is written in **${langName}**.
You MUST write ALL output fields (\`summary\`, \`issues[].title\`, \`issues[].detail\`, \`issues[].fix\`, \`issues[].rewrite.before\`, and \`issues[].rewrite.after\`) strictly in **${langName}**!
${isId ? 'Do NOT penalize the CV simply for being written in Bahasa Indonesia. Instead, evaluate its structure, grammar, clichés, STAR achievements, and personal bias fields in Bahasa Indonesia.' : 'Evaluate grammar, clichés, STAR achievements, and personal bias fields in fluent English.'}

STRICT ANTI-HALLUCINATION DIAGNOSTIC RULE (CRITICAL):
- Only report issues that are EXPLICITLY present in the provided CV text!
- Embedded Photo Metadata Flag for this PDF: \`hasPhoto = ${Boolean(hasPhoto)}\`.
- If \`hasPhoto\` is \`false\` and the CV text does not explicitly say "Pas Foto" or "Headshot attached", you are **STRICTLY FORBIDDEN** from reporting any issue about a photo, portrait, profile picture, or headshot!
- Similarly, do NOT report Date of Birth, Religion, Marital Status, or National ID (NIK) unless those exact fields actually appear in the CV text!

Evaluate the candidate's CV strictly according to 5 ATS Pillars:
1. personal_info: STRICTLY ONLY for actual personal bias / PII fields (date/place of birth, age, marital status, religion, gender, national ID KTP/NIK, or embedded photo when \`hasPhoto=true\`). NEVER put generic summaries or clichés under \`personal_info\`!
2. ats_readability: Detect complex tables, multi-column layouts, unusual symbols, or overly brief content (< 150 words).
3. keyword_match: Match against standard industry skills for the candidate's target job title.
4. achievements: Flag passive duties ("Responsible for...", "Bertanggung jawab...") or missing quantified metrics that lack the STAR method (Action Verb + Context + Quantified Metric).
5. language_quality: Flag generic summaries, stiff phrasing, passive voice, and clichés ("hard working", "pekerja keras", "under pressure", "di bawah tekanan").

STRICT SEVERITY DEFINITIONS (DO NOT INFLATE SEVERITY):
- \`critical\`: ONLY for objective ATS/EEOC rejection blockers explicitly found in the CV (\`photo\` when \`hasPhoto=true\`, \`dob_age\`, \`marital_status\`, \`religion\`, \`national_id\`, or severely broken/unreadable structure). NEVER mark wording polish, keyword gaps, or minor bullet improvements as \`critical\`.
- \`warning\`: Objective structural or content gaps (\`too_short\` < 150 words, \`duties\` using passive "Responsible for..." phrasing, \`no_metrics\` when quantifiable results are absent across the CV, or \`missing_core_keywords\` when >= 4 core role skills are missing).
- \`suggestion\`: Optional polish improvements (\`cliche_words\`, tightening already-strong bullets, minor phrasing/formatting tweaks). For an already strong, metric-rich CV, report ONLY genuine \`suggestion\` items (or an empty \`issues\` array if none apply).

PREFERRED CANONICAL ISSUE IDs (use when applicable):
- \`photo\`, \`dob_age\`, \`marital_status\`, \`religion\`, \`national_id\`
- \`too_short\`, \`duties\`, \`no_metrics\`, \`cliche_words\`, \`missing_core_keywords\`

ZERO-HALLUCINATION POLICY FOR REWRITES:
Do NOT fabricate numbers, metrics, tools, companies, or factual statements not present in the CV. When giving rewrite suggestions without existing metrics, you MUST use square bracket placeholders like ${isId ? '[X]% atau [jumlah]' : '[X]% or [number]'}.

DETERMINISTIC SCORING NOTE:
- The backend computes the final numeric 0-100 score deterministically from your structured \`issues\` and \`keywordMatch\` (\`critical = -11\`, \`warning = -7\`, \`suggestion = -3\`). Focus strictly on accurate, consistent issue detection, severity classification, keywords, and summary tone that matches your findings.

Return ONLY a valid JSON object matching this schema:
{
  "mode": "global",
  "language": "${lang}",
  "summary": "string in ${langName} explaining the overall readiness consistent with the issues listed",
  "issues": [
    {
      "id": "canonical_issue_key",
      "category": "personal_info" | "ats_readability" | "keyword_match" | "achievements" | "language_quality",
      "severity": "critical" | "warning" | "suggestion",
      "title": "Short title in ${langName}",
      "detail": "Detailed explanation in ${langName}",
      "fix": "Actionable step-by-step guidance in ${langName}",
      "rewrite": {
        "before": "Actual excerpt from the user's CV in ${langName}",
        "after": "Professional rewrite in ${langName} with [placeholder] for missing metrics"
      }
    }
  ],
  "keywordMatch": {
    "jobTitle": "Inferred target role",
    "matched": ["Skill1", "Skill2"],
    "missing": ["MissingSkill1", "MissingSkill2"],
    "missingCount": number
  }
}`;
}

/**
 * Analyze CV text using Gemini (matching CV language: 'en' or 'id') or fallback to Rule-Based engine.
 * Enforces deterministic Gemini sampling (temperature=0, topP=0.1), deterministic JS scoring via
 * calculateAtsScore, and SHA-256 exact-content anchoring to eliminate score drift on identical CVs.
 * @param {string} text - CV text
 * @param {string} fileName - Uploaded file name
 * @param {object} options - { hasPhoto?: boolean, language?: string, mode?: string, region?: string, bypassCache?: boolean, _aiClient?: object, models?: string[], timeoutMs?: number }
 * @returns {Promise<object>} Analysis result
 */
async function analyzeCv(text, fileName = 'CV.pdf', options = {}) {
  const { cleanText, language } = validateCvText(text, {
    language: options.language,
  });
  const lang = normalizeLanguage(options.language, cleanText) || language;
  const hasPhoto = hasExplicitPhotoEvidence(cleanText, options);
  const mode = options.mode || 'global';
  const region = options.region || null;
  const contentHash = computeCvContentHash({
    text: cleanText,
    mode,
    region,
    hasPhoto,
  });
  const cacheKey = `${contentHash}:${lang}`;

  if (!options.bypassCache) {
    const cached = getCachedAnalysis(cacheKey, fileName);
    if (cached) {
      return cached;
    }
  }

  const aiClient = options._aiClient || (isAiAvailable() ? ai : null);

  if (!aiClient) {
    return runRuleFallback(cleanText, fileName, { hasPhoto, lang, contentHash });
  }

  try {
    const prompt = `Analyze the following CV content (Detected Language: ${lang === 'id' ? 'Bahasa Indonesia' : 'English'}, Market/Region: ${region || mode}, PDF Embedded Photo Detected: ${hasPhoto}):\n\n=== CV START ===\n${cleanText}\n=== CV END ===`;

    const { parsed } = await generateJsonWithGemini({
      aiClient,
      contents: prompt,
      systemInstruction: buildSystemInstruction(lang, hasPhoto),
      models: options.models,
      timeoutMs: options.timeoutMs,
      temperature: ANALYSIS_TEMPERATURE,
      topP: ANALYSIS_TOP_P,
    });

    const sanitized = sanitizeAnalysisResult(parsed, {
      text: cleanText,
      fileName,
      lang,
      hasPhoto,
      engine: 'gemini',
      inferJobRole,
      analyzeKeywords,
    });

    sanitized.meta.contentHash = contentHash;
    sanitized.meta.cachedAnchor = false;

    if (!options.bypassCache) {
      setCachedAnalysis(cacheKey, sanitized);
    }

    return sanitized;
  } catch (err) {
    console.warn(
      `[AI Analysis Warning] Gemini API call failed: ${err.message}. Falling back to Rule-Based engine.`
    );
    return runRuleFallback(cleanText, fileName, { hasPhoto, lang, contentHash });
  }
}

module.exports = {
  analyzeCv,
  buildSystemInstruction,
  clearAnalysisCache,
  computeCvContentHash,
  calculateAtsScore,
  ANALYSIS_TEMPERATURE,
  ANALYSIS_TOP_P,
};

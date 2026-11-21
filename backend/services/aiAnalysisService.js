const { ai, isAiAvailable } = require('../config/ai');
const { analyzeWithRules, inferJobRole, analyzeKeywords } = require('./ruleBasedService');
const { validateCvText, normalizeLanguage } = require('./bilingualValidation');
const {
  generateJsonWithGemini,
  hasExplicitPhotoEvidence,
  sanitizeAnalysisResult,
} = require('./aiGuardrails');

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

PREFERRED CANONICAL ISSUE IDs (use when applicable):
- \`photo\`, \`dob_age\`, \`marital_status\`, \`religion\`, \`national_id\`
- \`too_short\`, \`duties\`, \`no_metrics\`, \`cliche_words\`, \`missing_core_keywords\`

ZERO-HALLUCINATION POLICY FOR REWRITES:
Do NOT fabricate numbers, metrics, tools, companies, or factual statements not present in the CV. When giving rewrite suggestions without existing metrics, you MUST use square bracket placeholders like ${isId ? '[X]% atau [jumlah]' : '[X]% or [number]'}.

SCORING RULES:
- Initial score: 100
- Deduct: critical = -11, warning = -7, suggestion = -3
- Minimum score capped at 10.

Return ONLY a valid JSON object matching this schema:
{
  "mode": "global",
  "language": "${lang}",
  "overallScore": number,
  "summary": "string in ${langName} explaining the overall readiness",
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
 * Analyze CV text using Gemini (matching CV language: 'en' or 'id') or fallback to Rule-Based engine
 * @param {string} text - CV text
 * @param {string} fileName - Uploaded file name
 * @param {object} options - { hasPhoto?: boolean, language?: string, _aiClient?: object, models?: string[], timeoutMs?: number }
 * @returns {Promise<object>} Analysis result
 */
async function analyzeCv(text, fileName = 'CV.pdf', options = {}) {
  const { cleanText, language } = validateCvText(text, {
    language: options.language,
  });
  const lang = normalizeLanguage(options.language, cleanText) || language;
  const hasPhoto = hasExplicitPhotoEvidence(cleanText, options);
  const aiClient = options._aiClient || (isAiAvailable() ? ai : null);

  if (!aiClient) {
    return analyzeWithRules(cleanText, fileName, { hasPhoto, language: lang });
  }

  try {
    const prompt = `Analyze the following CV content (Detected Language: ${lang === 'id' ? 'Bahasa Indonesia' : 'English'}, PDF Embedded Photo Detected: ${hasPhoto}):\n\n=== CV START ===\n${cleanText}\n=== CV END ===`;

    const { parsed } = await generateJsonWithGemini({
      aiClient,
      contents: prompt,
      systemInstruction: buildSystemInstruction(lang, hasPhoto),
      models: options.models,
      timeoutMs: options.timeoutMs,
    });

    return sanitizeAnalysisResult(parsed, {
      text: cleanText,
      fileName,
      lang,
      hasPhoto,
      engine: 'gemini',
      inferJobRole,
      analyzeKeywords,
    });
  } catch (err) {
    console.warn(
      `[AI Analysis Warning] Gemini API call failed: ${err.message}. Falling back to Rule-Based engine.`
    );
    return analyzeWithRules(cleanText, fileName, { hasPhoto, language: lang });
  }
}

module.exports = {
  analyzeCv,
  buildSystemInstruction,
};

const { ai, isAiAvailable } = require('../config/ai');
const { analyzeWithRules, detectCvLanguage } = require('./ruleBasedService');

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
- If \`hasPhoto\` is \`false\` and the CV text does not explicitly say "Pas Foto" or "Headshot attached", you are **STRICTLY FORBIDDEN** from reporting any issue about a photo or headshot!
- Similarly, do NOT report Date of Birth, Religion, Marital Status, or National ID (NIK) unless those exact fields actually appear in the CV text!

Evaluate the candidate's CV strictly according to 5 ATS Pillars:
1. personal_info: Only flag if actual personal bias fields (date/place of birth, age, marital status, religion, gender, national ID KTP/NIK, or embedded photo when \`hasPhoto=true\`) exist in the CV.
2. ats_readability: Detect complex tables, multi-column layouts, unusual symbols, or overly brief content.
3. keyword_match: Match against standard industry skills for the candidate's target job title.
4. achievements: Flag passive duties ("Responsible for...", "Bertanggung jawab...") that lack the STAR method (Action Verb + Context + Quantified Metric).
5. language_quality: Flag stiff phrasing, passive voice, and clichés ("hard working", "pekerja keras", "under pressure").

ZERO-HALLUCINATION POLICY FOR REWRITES:
Do NOT fabricate numbers, metrics, or factual statements. When giving rewrite suggestions without existing metrics, use square bracket placeholders like ${isId ? '[X]% atau [jumlah]' : '[X]% or [team size]'}.

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
      "id": "unique_issue_key",
      "category": "personal_info" | "ats_readability" | "keyword_match" | "achievements" | "language_quality",
      "severity": "critical" | "warning" | "suggestion",
      "title": "Short title in ${langName}",
      "detail": "Detailed explanation in ${langName}",
      "fix": "Actionable step-by-step guidance in ${langName}",
      "rewrite": {
        "before": "Actual excerpt from the user's CV in ${langName}",
        "after": "Professional rewrite after in ${langName}"
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
 * @param {object} options - { hasPhoto?: boolean }
 * @returns {Promise<object>} Analysis result
 */
async function analyzeCv(text, fileName = 'CV.pdf', options = {}) {
  const lang = detectCvLanguage(text);
  const explicitPhotoTextRegex = /\b(pas\s*foto|pasfoto|foto\s*diri|foto\s*4x6|foto\s*3x4|photo\s*:\s*headshot|headshot\s*attached|foto\s*terlampir)\b/i;
  const hasPhoto = Boolean(options.hasPhoto) || explicitPhotoTextRegex.test(text);

  if (!isAiAvailable()) {
    return analyzeWithRules(text, fileName, { hasPhoto });
  }

  try {
    const prompt = `Analyze the following CV content (Detected Language: ${lang === 'id' ? 'Bahasa Indonesia' : 'English'}, PDF Embedded Photo Detected: ${hasPhoto}):\n\n=== CV START ===\n${text}\n=== CV END ===`;

    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: prompt,
      config: {
        systemInstruction: buildSystemInstruction(lang, hasPhoto),
        responseMimeType: 'application/json',
      },
    });

    const outputText =
      response.text ||
      (response.candidates && response.candidates[0]?.content?.parts[0]?.text);
    if (!outputText) {
      throw new Error('Empty response from AI model');
    }

    const parsed = JSON.parse(outputText);

    parsed.mode = 'global';
    parsed.language = lang;
    parsed.issues = Array.isArray(parsed.issues) ? parsed.issues : [];

    // Hard programmatic guard: strip any hallucinated photo issue if hasPhoto is false
    if (!hasPhoto) {
      parsed.issues = parsed.issues.filter((issue) => {
        const idStr = (issue.id || '').toLowerCase();
        const titleStr = (issue.title || '').toLowerCase();
        const isPhotoIssue =
          idStr.includes('photo') ||
          idStr.includes('foto') ||
          titleStr.includes('foto') ||
          titleStr.includes('photo') ||
          titleStr.includes('headshot');
        return !isPhotoIssue;
      });
    }

    // Recalculate score cleanly from verified issues
    let score = 100;
    for (const issue of parsed.issues) {
      if (issue.severity === 'critical') score -= 11;
      else if (issue.severity === 'warning') score -= 7;
      else if (issue.severity === 'suggestion') score -= 3;
    }
    parsed.overallScore = Math.max(10, Math.min(100, score));

    parsed.summary =
      parsed.summary ||
      (lang === 'id'
        ? 'Hasil analisis ATS untuk CV Anda.'
        : 'ATS diagnostic summary for your CV.');
    parsed.keywordMatch = parsed.keywordMatch || {
      jobTitle: 'Professional',
      matched: [],
      missing: [],
      missingCount: 0,
    };
    parsed.meta = {
      fileName,
      language: lang,
      analyzedAtLabel:
        lang === 'id'
          ? 'Dianalisis AI Gemini (Bahasa Indonesia)'
          : 'Analyzed by Gemini AI (English)',
      engine: 'gemini',
    };

    return parsed;
  } catch (err) {
    console.warn(
      `[AI Analysis Warning] Gemini API call failed: ${err.message}. Falling back to Rule-Based engine.`
    );
    return analyzeWithRules(text, fileName, { hasPhoto });
  }
}

module.exports = {
  analyzeCv,
};

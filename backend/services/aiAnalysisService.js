const { ai, isAiAvailable } = require('../config/ai');
const { analyzeWithRules } = require('./ruleBasedService');

const SYSTEM_INSTRUCTION = `You are LeveledUp, an elite ATS (Applicant Tracking System) CV auditor and career coach specialized in evaluating Indonesian applicants targeting global/multinational/remote jobs (US, UK, Europe, Singapore).

You MUST evaluate the candidate's CV strictly according to 5 ATS Pillars:
1. personal_info: Detect photos, date/place of birth, age, marital status, religion, gender, national ID (KTP/NIK), blood type, height/weight, general hobbies. These violate international EEOC/anti-bias standards.
2. ats_readability: Detect complex tables, multi-column layouts, graphics, unusual symbols.
3. keyword_match: Match against standard skills for the candidate's target job title.
4. achievements: Flag passive duties ("Responsible for", "Bertanggung jawab...") that lack the STAR method (Action Verb + Context + Quantified Metric).
5. language_quality: Flag Indonesian language used for global applications, stiff translations, and clichés ("hard working", "team player", "under pressure").

ZERO-HALLUCINATION POLICY:
Do NOT fabricate numbers, metrics, or factual statements. When giving rewrite suggestions without existing metrics, use square bracket placeholders like [X]% or [team size].

SCORING RULES:
- Initial score: 100
- Deduct: critical = -11, warning = -7, suggestion = -3
- Minimum score capped at 10.

Return ONLY a valid JSON object matching this schema:
{
  "mode": "global",
  "overallScore": number,
  "summary": "string in Indonesian explaining the overall readiness",
  "issues": [
    {
      "id": "unique_issue_key",
      "category": "personal_info" | "ats_readability" | "keyword_match" | "achievements" | "language_quality",
      "severity": "critical" | "warning" | "suggestion",
      "title": "Short title in Indonesian",
      "detail": "Detailed explanation of why this violates international ATS standards",
      "fix": "Actionable step-by-step guidance in Indonesian",
      "rewrite": {
        "before": "Excerpt before",
        "after": "Professional rewrite after"
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

/**
 * Analyze CV text using Gemini or fallback to Rule-Based engine
 * @param {string} text - CV text
 * @param {string} fileName - Uploaded file name
 * @returns {Promise<object>} Analysis result
 */
async function analyzeCv(text, fileName = 'CV.pdf') {
  if (!isAiAvailable()) {
    return analyzeWithRules(text, fileName);
  }

  try {
    const prompt = `Please analyze the following CV content according to international ATS standards:\n\n=== CV START ===\n${text}\n=== CV END ===`;
    
    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: prompt,
      config: {
        systemInstruction: SYSTEM_INSTRUCTION,
        responseMimeType: 'application/json',
      },
    });

    const outputText = response.text || (response.candidates && response.candidates[0]?.content?.parts[0]?.text);
    if (!outputText) {
      throw new Error('Empty response from AI model');
    }

    const parsed = JSON.parse(outputText);
    
    // Ensure all required fields exist
    parsed.mode = 'global';
    parsed.overallScore = typeof parsed.overallScore === 'number' ? Math.max(10, Math.min(100, parsed.overallScore)) : 65;
    parsed.summary = parsed.summary || 'Hasil analisis ATS untuk CV Anda.';
    parsed.issues = Array.isArray(parsed.issues) ? parsed.issues : [];
    parsed.keywordMatch = parsed.keywordMatch || {
      jobTitle: 'Professional',
      matched: [],
      missing: [],
      missingCount: 0,
    };
    parsed.meta = {
      fileName,
      analyzedAtLabel: 'Dianalisis AI (Gemini)',
      engine: 'gemini',
    };

    return parsed;
  } catch (err) {
    console.warn(`[AI Analysis Warning] Gemini API call failed: ${err.message}. Falling back to Rule-Based engine.`);
    return analyzeWithRules(text, fileName);
  }
}

module.exports = {
  analyzeCv,
};

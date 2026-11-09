const { ai, isAiAvailable } = require('../config/ai');
const { inferJobRole } = require('./ruleBasedService');

const REWRITE_SYSTEM_PROMPT = `You are LeveledUp CV Rewrite Engine, an expert international resume writer specializing in ATS-optimized resumes for global jobs (US, UK, Europe, Singapore).

YOUR MISSION:
Transform the user's CV into an elite, single-column, ATS-friendly English resume structure.

CRITICAL RULES:
1. ZERO-HALLUCINATION / ANTI-FABRICATION:
   - NEVER fabricate numbers, companies, dates, or degrees that are not in the CV.
   - If a metric or quantified result is missing, you MUST insert an explicit bracketed placeholder like [X]%, [amount], [timeframe], or [team size] so the candidate can fill in their actual data.
2. REMOVE ALL BIAS DATA:
   - Strip out photos, age, date of birth, marital status, religion, gender, national ID (NIK), blood type, height/weight, and irrelevant hobbies.
3. TRANSFORM PASSIVE DUTIES TO STAR ACHIEVEMENTS:
   - Start bullets with strong action verbs (Architected, Engineered, Optimized, Spearheaded, Accelerated).
   - Use: Strong Verb + Context + [Quantified Impact].
4. TARGET LANGUAGE:
   - 100% fluent, professional American English.

Return ONLY a valid JSON object matching this schema:
{
  "cv": {
    "name": "Applicant Full Name",
    "title": "Target Professional Title",
    "contact": [
      "email@example.com",
      "+62 812 XXXX XXXX",
      "City, Country (Open to Remote)",
      "linkedin.com/in/username",
      "github.com/username"
    ],
    "summary": "Impactful 2-3 sentence executive summary showcasing key value proposition and core tech stack.",
    "sections": [
      {
        "heading": "Professional Experience",
        "bullets": [
          "Developed and deployed [feature] resulting in [X]% improvement in [metric].",
          "Refactored legacy modules to enhance maintainability and reduce latency by [X]%."
        ]
      },
      {
        "heading": "Education",
        "bullets": [
          "B.S. in Computer Science — [University Name] (Graduation Year / Expected)"
        ]
      },
      {
        "heading": "Skills",
        "bullets": [
          "Languages & Frameworks: ...",
          "Tools & Platforms: ..."
        ]
      }
    ],
    "changes": [
      "Menghapus data pribadi sensitif (foto, tanggal lahir, status pernikahan) sesuai standar anti-bias internasional.",
      "Mengonversi deskripsi tugas administratif pasif menjadi poin pencapaian berbasis aksi (STAR method).",
      "Menandai metrik kuantitatif dengan kurung siku [placeholder] yang wajib Anda isi dengan angka riil Anda."
    ]
  }
}`;

/**
 * Generate a rule-based fallback rewrite when AI is not configured
 */
function generateFallbackRewrite(text) {
  const role = inferJobRole(text);
  
  // Extract name (usually first non-empty line)
  const lines = text.split('\n').map(l => l.trim()).filter(Boolean);
  let applicantName = 'Professional Candidate';
  if (lines.length > 0 && lines[0].length < 40 && !/cv|resume|curriculum/i.test(lines[0])) {
    applicantName = lines[0].replace(/^(nama\s*:|name\s*:)/i, '').trim();
  }

  // Extract email & phone
  const emailMatch = text.match(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/);
  const phoneMatch = text.match(/(\+62|08|62)[\d\s-]{8,14}/);

  const contact = [
    emailMatch ? emailMatch[0] : '[your.email@example.com]',
    phoneMatch ? phoneMatch[0].replace(/\s+/g, ' ') : '[+62 8XX XXXX XXXX]',
    'Indonesia (Open to Remote / Relocation)',
    'linkedin.com/in/[your-linkedin]',
  ];

  return {
    cv: {
      name: applicantName,
      title: role,
      contact,
      summary: `Results-oriented ${role} with hands-on expertise in delivering robust, high-performance solutions. Proven track record in collaborating with agile teams to optimize workflows, improve system reliability by [X]%, and deliver high-impact features.`,
      sections: [
        {
          heading: 'Professional Experience',
          bullets: [
            `Spearheaded the development and maintenance of core ${role} components, improving execution speed by [X]%.`,
            `Collaborated with cross-functional product and engineering teams to ship [jumlah] major feature releases on schedule.`,
            `Optimized workflow processes and code quality, cutting issue resolution time from [waktu awal] to [waktu akhir].`,
            `Engineered automated tests and continuous integration checks, achieving [X]% test coverage across key services.`,
          ],
        },
        {
          heading: 'Education & Certifications',
          bullets: [
            'Bachelor Degree / Diploma in relevant discipline — [University / Institution] ([Year])',
            'Relevant Coursework / Certified Professional in [Domain Specialization]',
          ],
        },
        {
          heading: 'Technical Skills',
          bullets: [
            `Core Competencies: ${role} Best Practices, System Architecture, Code Review, Agile/Scrum`,
            'Tools & Technologies: Git, CI/CD, Cloud Infrastructure, Docker, RESTful APIs',
          ],
        },
      ],
      changes: [
        'Menghapus foto diri, tanggal lahir, status pernikahan, dan agama sesuai standar hukum anti-diskriminasi internasional.',
        'Mengonversi deskripsi tugas pasif menjadi poin pencapaian berorientasi dampak (STAR: Action Verb + Context + Quantified Metric).',
        'Menambahkan penanda [placeholder] kurung siku pada angka persentase dan metrik yang wajib Anda lengkapi dengan data riil Anda.',
      ],
    },
  };
}

/**
 * Rewrite CV with AI or fallback template
 * @param {string} text - CV text
 * @returns {Promise<object>} Rewritten CV matching the mvp.md schema
 */
async function rewriteCv(text) {
  if (!isAiAvailable()) {
    return generateFallbackRewrite(text);
  }

  try {
    const prompt = `Please rewrite the following CV into an elite, ATS-friendly structure adhering to all anti-bias and anti-fabrication guidelines:\n\n=== ORIGINAL CV ===\n${text}\n=== END ===`;

    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: prompt,
      config: {
        systemInstruction: REWRITE_SYSTEM_PROMPT,
        responseMimeType: 'application/json',
      },
    });

    const outputText = response.text || (response.candidates && response.candidates[0]?.content?.parts[0]?.text);
    if (!outputText) {
      throw new Error('Empty response from AI rewrite model');
    }

    const parsed = JSON.parse(outputText);
    if (!parsed.cv || !Array.isArray(parsed.cv.sections)) {
      throw new Error('Invalid JSON structure returned by rewrite model');
    }

    return parsed;
  } catch (err) {
    console.warn(`[AI Rewrite Warning] Gemini API call failed: ${err.message}. Using rule-based fallback rewrite.`);
    return generateFallbackRewrite(text);
  }
}

module.exports = {
  rewriteCv,
  generateFallbackRewrite,
};


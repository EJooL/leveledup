const { ai, isAiAvailable } = require('../config/ai');
const { inferJobRole } = require('./ruleBasedService');
const { validateCvText, normalizeLanguage } = require('./bilingualValidation');
const {
  generateJsonWithGemini,
  sanitizeRewriteResult,
  isBiasLine,
  isHeaderLikeBullet,
  hasQuantifiedMetric,
  hasBracketPlaceholder,
} = require('./aiGuardrails');

function buildRewriteSystemPrompt(lang) {
  const isId = lang === 'id';
  const langName = isId ? 'Bahasa Indonesia' : 'English';

  return `You are LeveledUp CV Rewrite Engine, an expert ATS resume writer.

LANGUAGE RULE (CRITICAL):
The candidate's original CV is written in **${langName}**.
You MUST write the entire rewritten CV (\`title\`, \`summary\`, \`sections[].heading\`, \`sections[].bullets\`, and \`changes\`) strictly in **${langName}**!

CRITICAL RULES:
1. ZERO-HALLUCINATION / ANTI-FABRICATION:
   - NEVER fabricate numbers, percentages, metrics, companies, dates, degrees, unmentioned sub-libraries/tools, or responsibilities not grounded in the original CV.
   - If a metric or quantified result is missing from an experience bullet, you MUST insert an explicit bracketed placeholder like ${isId ? '[X]%, [jumlah], atau [metrik target]' : '[X]%, [number], or [target metric]'} so the candidate can fill in their actual data.
2. REMOVE ALL BIAS DATA:
   - Strip out photos, age, date of birth (TTL), marital status, religion, gender, national ID (NIK), blood type, height/weight, and irrelevant hobbies.
3. TRANSFORM PASSIVE DUTIES TO STAR ACHIEVEMENTS:
   - Start experience bullets with strong action verbs (${isId ? 'Merancang, Mengoptimalkan, Memimpin, Mengembangkan, Mempercepat' : 'Architected, Engineered, Optimized, Spearheaded, Accelerated'}).
   - Use: Strong Action Verb + Grounded Context + Quantified Impact (or [placeholder]).

Return ONLY a valid JSON object matching this schema:
{
  "cv": {
    "language": "${lang}",
    "name": "Applicant Full Name",
    "title": "Target Professional Title",
    "contact": [
      "email@example.com",
      "+62 812 XXXX XXXX",
      "${isId ? 'Jakarta, Indonesia' : 'Jakarta, Indonesia (Open to Remote)'}",
      "linkedin.com/in/username"
    ],
    "summary": "Impactful 2-3 sentence executive summary in ${langName}.",
    "sections": [
      {
        "heading": "${isId ? 'Pengalaman Profesional' : 'Professional Experience'}",
        "bullets": [
          "${isId ? 'Mengembangkan dan meluncurkan [fitur] yang meningkatkan efisiensi sebesar [X]%.' : 'Developed and deployed [feature] resulting in [X]% improvement in [target metric].'}"
        ]
      },
      {
        "heading": "${isId ? 'Pendidikan' : 'Education'}",
        "bullets": [
          "${isId ? 'S1 Teknik Informatika — [Nama Universitas] ([Tahun])' : 'B.S. in Computer Science — [University Name] ([Year])'}"
        ]
      },
      {
        "heading": "${isId ? 'Keahlian Teknis' : 'Technical Skills'}",
        "bullets": [
          "${isId ? 'Keahlian Utama: ...' : 'Core Skills: ...'}"
        ]
      }
    ],
    "changes": [
      "${isId ? 'Menghapus data pribadi sensitif (foto, TTL, status pernikahan, agama, NIK) sesuai standar ATS.' : 'Removed sensitive personal bias fields (photo, DOB, marital status, religion, National ID).'}"
    ]
  }
}`;
}

/**
 * Generate a dynamic rule-based rewrite that preserves the candidate's actual
 * experience, education, and skills from [text] while upgrading passive lines
 * into STAR-method bullets with [placeholder] tags.
 */
function generateFallbackRewrite(text, options = {}) {
  const safeText = typeof text === 'string' ? text : '';
  const lang = normalizeLanguage(options.language, safeText);
  const isId = lang === 'id';
  const role = inferJobRole(safeText);

  const rawLines = safeText
    .split('\n')
    .map((l) => l.trim())
    .filter(Boolean);

  // 1. Filter out personal bias lines (photo, TTL, religion, marital status, NIK)
  const lines = rawLines.filter((l) => !isBiasLine(l));

  // 2. Extract Candidate Name & Title
  let applicantName = isId ? 'Kandidat Profesional' : 'Professional Candidate';
  if (
    lines.length > 0 &&
    lines[0].length < 48 &&
    !/^(cv|resume|curriculum|daftar\s+riwayat)/i.test(lines[0])
  ) {
    applicantName = lines[0].replace(/^(nama\s*:|name\s*:)/i, '').trim();
  } else if (lines.length > 1 && lines[1].length < 48) {
    applicantName = lines[1].replace(/^(nama\s*:|name\s*:)/i, '').trim();
  }

  let applicantTitle = role;
  if (
    lines.length > 1 &&
    lines[1].length < 55 &&
    !/@|\d{4}|\+62|08/.test(lines[1]) &&
    !/^(ringkasan|summary|tentang|profile|pengalaman|experience|pendidikan|education)/i.test(
      lines[1]
    )
  ) {
    applicantTitle = lines[1];
  }

  // 3. Extract Contact Info
  const emailMatch = safeText.match(
    /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/
  );
  const phoneMatch = safeText.match(/(\+62|08|62)[\d\s-]{8,15}/);
  const linkedinMatch = safeText.match(/linkedin\.com\/in\/[a-zA-Z0-9_-]+/i);

  const contact = [
    emailMatch ? emailMatch[0] : '[email@domain.com]',
    phoneMatch ? phoneMatch[0].replace(/\s+/g, ' ').trim() : '[+62 8XX XXXX XXXX]',
    isId ? 'Indonesia' : 'Indonesia (Open to Remote)',
    linkedinMatch
      ? linkedinMatch[0]
      : (isId ? 'linkedin.com/in/[profil-anda]' : 'linkedin.com/in/[your-profile]'),
  ];

  // 4. Bucket lines into Experience, Education, and Skills from the actual CV text
  const expBullets = [];
  const eduBullets = [];
  const skillBullets = [];
  let currentBucket = 'summary';

  const expHeadRx =
    /^(pengalaman(\s+kerja|\s+profesional|\s+organisasi)?|riwayat\s+pekerjaan|work\s+experience|professional\s+experience|experience|employment|internship|magang|organisasi)$/i;
  const eduHeadRx =
    /^(pendidikan|riwayat\s+pendidikan|education|academic|kualifikasi\s+akademik|sertifikasi|certifications)$/i;
  const skillHeadRx =
    /^(keahlian|kemampuan|keterampilan|skills|technical\s+skills|core\s+competencies|kompetensi|tools|bahasa)$/i;
  const summaryHeadRx =
    /^(ringkasan(\s+profesional)?|tentang\s+saya|profil(\s+singkat)?|summary|executive\s+summary|profile|about\s+me|objective)$/i;

  for (let i = 1; i < lines.length; i++) {
    const line = lines[i];
    const cleanHeader = line.replace(/[:\-–—•*#]/g, '').trim();

    if (summaryHeadRx.test(cleanHeader)) {
      currentBucket = 'summary';
      continue;
    }
    if (expHeadRx.test(cleanHeader)) {
      currentBucket = 'exp';
      continue;
    }
    if (eduHeadRx.test(cleanHeader)) {
      currentBucket = 'edu';
      continue;
    }
    if (skillHeadRx.test(cleanHeader)) {
      currentBucket = 'skill';
      continue;
    }

    // Skip contact lines
    if (/@|\+62|08\d{6,}|linkedin\.com/i.test(line) && line.length < 75) {
      continue;
    }

    const stripped = line.replace(/^[•\-*–—]\s*/, '').trim();
    if (stripped.length < 4 || stripped === applicantTitle) continue;

    if (
      currentBucket === 'edu' ||
      /\b(universitas|institut|politeknik|sekolah\s+tinggi|sma|smk|s1|d3|d4|bachelor|university|diploma|ipk|gpa)\b/i.test(
        stripped
      )
    ) {
      if (eduBullets.length < 5) eduBullets.push(stripped);
    } else if (currentBucket === 'skill') {
      if (skillBullets.length < 6) skillBullets.push(stripped);
    } else if (currentBucket === 'exp' || i > 2) {
      if (expBullets.length < 8) {
        expBullets.push(_upgradeBulletToStar(stripped, isId));
      }
    }
  }

  // Ensure non-empty fallbacks if CV had unlabelled sections
  if (expBullets.length === 0) {
    for (const l of lines.slice(2, 8)) {
      const s = l.replace(/^[•\-*]\s*/, '').trim();
      if (s.length > 15) expBullets.push(_upgradeBulletToStar(s, isId));
    }
  }

  if (eduBullets.length === 0) {
    eduBullets.push(
      isId
        ? '[Gelar / Jurusan] — [Nama Universitas / Institusi] ([Tahun Lulus])'
        : '[Degree / Major] — [University / Institution] ([Graduation Year])'
    );
  }

  if (skillBullets.length === 0) {
    skillBullets.push(
      isId
        ? `Kompetensi Utama: ${applicantTitle}, Manajemen Proyek, Komunikasi Profesional, Problem Solving`
        : `Core Competencies: ${applicantTitle}, Project Execution, Cross-Functional Collaboration, Problem Solving`
    );
  }

  const summaryText = isId
    ? `Profesional di bidang ${applicantTitle} yang berorientasi pada hasil dengan rekam jejak dalam meningkatkan efisiensi operasional dan kualitas kerja. Terbukti mampu beradaptasi cepat, berkolaborasi lintas fungsi, dan mencapai target terukur sebesar [X]% secara konsisten.`
    : `Results-driven ${applicantTitle} with a proven track record of executing high-impact initiatives and optimizing operational workflows. Adept at cross-functional collaboration and delivering measurable improvements of [X]% against key performance targets.`;

  return sanitizeRewriteResult(
    {
      cv: {
        language: lang,
        name: applicantName,
        title: applicantTitle,
        contact,
        summary: summaryText,
        sections: [
          {
            heading: isId ? 'Pengalaman Profesional' : 'Professional Experience',
            bullets: expBullets,
          },
          {
            heading: isId ? 'Pendidikan' : 'Education',
            bullets: eduBullets,
          },
          {
            heading: isId ? 'Keahlian & Kompetensi' : 'Skills & Competencies',
            bullets: skillBullets,
          },
        ],
        changes: isId
          ? [
              'Menghapus data pribadi sensitif (pas foto, TTL, agama, status pernikahan, NIK) agar bebas bias dan lolos filter ATS.',
              'Mengonversi poin pengalaman asli Anda menjadi kalimat aktif berpola STAR dengan penanda metrik [X]%.',
              'Menyusun ulang struktur dokumen ke dalam format satu kolom bersih yang siap diunduh sebagai PDF.',
            ]
          : [
              'Removed sensitive demographic fields (photo, DOB, religion, marital status) for global ATS compliance.',
              'Upgraded your original experience bullets into action-driven STAR statements with [X]% metric placeholders.',
              'Formatted resume into a clean single-column layout ready for direct PDF download.',
            ],
      },
    },
    { sourceText: safeText, lang, engine: 'rule-based' }
  );
}

function _upgradeBulletToStar(line, isId) {
  let out = line;
  if (isHeaderLikeBullet(out)) {
    return out;
  }

  if (isId) {
    out = out
      .replace(/^bertanggung\s+jawab\s+(dalam\s+|untuk\s+|atas\s+)?/i, 'Mengelola dan mengoptimalkan ')
      .replace(/^membantu\s+/i, 'Berkolaborasi aktif dalam ')
      .replace(/^melakukan\s+/i, 'Mengeksekusi ');
    if (!hasQuantifiedMetric(out) && !hasBracketPlaceholder(out) && out.length > 25) {
      out = out.replace(/\.$/, '') + ', meningkatkan efektivitas kerja sebesar [X]%.';
    }
  } else {
    out = out
      .replace(/^responsible\s+for\s+/i, 'Spearheaded and optimized ')
      .replace(/^assisted\s+(in|with)\s+/i, 'Collaborated in executing ')
      .replace(/^worked\s+on\s+/i, 'Engineered and delivered ');
    if (!hasQuantifiedMetric(out) && !hasBracketPlaceholder(out) && out.length > 25) {
      out = out.replace(/\.$/, '') + ', improving overall efficiency by [X]%.';
    }
  }
  return out.charAt(0).toUpperCase() + out.slice(1);
}

/**
 * Rewrite CV with AI (matching original CV language: 'en' or 'id') or fallback template
 * @param {string} text - CV text
 * @param {object} [options] - { language?: string, _aiClient?: object, models?: string[], timeoutMs?: number }
 * @returns {Promise<object>} Rewritten CV
 */
async function rewriteCv(text, options = {}) {
  const { cleanText, language } = validateCvText(text, {
    language: options.language,
  });
  const lang = normalizeLanguage(options.language, cleanText) || language;
  const aiClient = options._aiClient || (isAiAvailable() ? ai : null);

  if (!aiClient) {
    return generateFallbackRewrite(cleanText, { language: lang });
  }

  try {
    const prompt = `Rewrite the following CV into an ATS-friendly structure in ${lang === 'id' ? 'Bahasa Indonesia' : 'English'}:\n\n=== ORIGINAL CV ===\n${cleanText}\n=== END ===`;

    const { parsed } = await generateJsonWithGemini({
      aiClient,
      contents: prompt,
      systemInstruction: buildRewriteSystemPrompt(lang),
      models: options.models,
      timeoutMs: options.timeoutMs,
    });

    return sanitizeRewriteResult(parsed, {
      sourceText: cleanText,
      lang,
      engine: 'gemini',
    });
  } catch (err) {
    console.warn(
      `[AI Rewrite Warning] Gemini API call failed: ${err.message}. Using rule-based fallback rewrite.`
    );
    return generateFallbackRewrite(cleanText, { language: lang });
  }
}

module.exports = {
  rewriteCv,
  generateFallbackRewrite,
  buildRewriteSystemPrompt,
};

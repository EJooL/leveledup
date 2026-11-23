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

  return `You are LeveledUp CV Rewrite Engine, an expert ATS resume writer formatting resumes into a crisp, modern single-column ATS Word (.docx) reference layout.

LANGUAGE RULE (CRITICAL):
The candidate's original CV is written in **${langName}**.
You MUST write the entire rewritten CV (\`title\`, \`summary\`, \`sections[].heading\`, \`sections[].entries\`, \`sections[].skillGroups\`, \`sections[].bullets\`, and \`changes\`) strictly in **${langName}**!

CRITICAL RULES:
1. ZERO-HALLUCINATION / ANTI-FABRICATION:
   - NEVER fabricate numbers, percentages, metrics, companies, projects, certifications, dates, degrees, unmentioned sub-libraries/tools, or responsibilities not grounded in the original CV.
   - If a metric or quantified result is missing from an experience or project bullet, you MUST insert an explicit bracketed placeholder like ${isId ? '[X]%, [jumlah], atau [metrik target]' : '[X]%, [number], or [target metric]'} so the candidate can fill in their actual data.
2. REMOVE ALL BIAS DATA:
   - Strip out photos, age, date of birth (TTL), marital status, religion, gender, national ID (NIK), blood type, height/weight, and irrelevant hobbies.
3. TRANSFORM PASSIVE DUTIES TO STAR ACHIEVEMENTS:
   - Start experience and project bullets with strong action verbs (${isId ? 'Merancang, Mengoptimalkan, Memimpin, Mengembangkan, Mempercepat' : 'Architected, Engineered, Built, Optimized, Led, Improved'}).
   - Use: Strong Action Verb + Grounded Context + Quantified Impact (or [placeholder]).
4. EXACT REFERENCE CV STRUCTURE (follow this exact section order and entry format, omitting \`projects\` or \`certifications\` if the candidate's CV has none):
   - \`name\`: Full name in clean Title Case (not ALL CAPS).
   - \`title\`: Concise headline: "<Target Role> | <Skill 1> · <Skill 2> · <Skill 3>" using ONLY skills grounded in the CV.
   - \`contact\`: Array of clean contact items (e.g., email, linkedin, github, phone if present, city/country).
   - \`summary\`: Concise 2-3 sentence grounded professional summary.
   - Section 1 (\`type: "education"\`, heading: "${isId ? 'Pendidikan' : 'Education'}"):
     \`entries\`: [{ "title": "Institution Name", "date": "2024 – 2028", "subtitle": "", "bullets": ["Major / Degree | GPA ... | Coursework: ..."] }]
   - Section 2 (\`type: "projects"\`, heading: "${isId ? 'Proyek' : 'Projects'}") — ONLY include if the original CV mentions projects:
     \`entries\`: [{ "title": "Project Name", "date": "Jan – May 2026", "subtitle": "", "bullets": ["STAR bullet..."] }]
   - Section 3 (\`type: "experience"\`, heading: "${isId ? 'Pengalaman' : 'Experience'}"):
     \`entries\`: [{ "title": "Role — Organization", "date": "Aug 2025 – Present", "subtitle": "Program / Location (optional)", "bullets": ["STAR bullet..."] }]
   - Section 4 (\`type: "skills"\`, heading: "${isId ? 'Keahlian' : 'Skills'}"):
     \`skillGroups\`: [{ "category": "${isId ? 'Kategori Keahlian' : 'Skill Category'}", "items": "Comma-separated grounded skills" }]
   - Section 5 (\`type: "certifications"\`, heading: "${isId ? 'Sertifikasi' : 'Certifications'}") — ONLY include if the original CV mentions certifications, courses, bootcamps, or awards:
     \`bullets\`: ["Certification Name — Issuer, Year", ...]

Return ONLY a valid JSON object matching this schema:
{
  "cv": {
    "language": "${lang}",
    "name": "Applicant Full Name",
    "title": "Target Role | Core Skill 1 · Core Skill 2 · Core Skill 3",
    "contact": [
      "email@example.com",
      "linkedin.com/in/username",
      "github.com/username",
      "${isId ? 'Surabaya, Indonesia' : 'Jakarta, Indonesia'}"
    ],
    "summary": "Concise 2-3 sentence grounded summary in ${langName}.",
    "sections": [
      {
        "heading": "${isId ? 'Pendidikan' : 'Education'}",
        "type": "education",
        "entries": [
          {
            "title": "${isId ? '[Nama Universitas]' : '[University Name]'}",
            "date": "${isId ? '[Tahun Masuk] – [Tahun Lulus]' : '[Start Year] – [End Year]'}",
            "subtitle": "",
            "bullets": [
              "${isId ? '[Jurusan / Gelar] | IPK [X.XX] / 4.00' : '[Major / Degree] | GPA [X.XX] / 4.00'}"
            ]
          }
        ]
      },
      {
        "heading": "${isId ? 'Pengalaman' : 'Experience'}",
        "type": "experience",
        "entries": [
          {
            "title": "${isId ? '[Posisi] — [Nama Perusahaan/Organisasi]' : '[Role] — [Company/Organization]'}",
            "date": "${isId ? '[Bulan Tahun] – Sekarang' : '[Month Year] – Present'}",
            "subtitle": "",
            "bullets": [
              "${isId ? 'Mengembangkan dan meluncurkan [fitur] yang meningkatkan efisiensi sebesar [X]%.' : 'Developed and deployed [feature] resulting in [X]% improvement in [target metric].'}"
            ]
          }
        ]
      },
      {
        "heading": "${isId ? 'Keahlian' : 'Skills'}",
        "type": "skills",
        "skillGroups": [
          {
            "category": "${isId ? 'Keahlian Utama' : 'Core Skills'}",
            "items": "Skill 1, Skill 2, Skill 3"
          }
        ]
      }
    ],
    "changes": [
      "${isId ? 'Menghapus data pribadi sensitif (foto, TTL, status pernikahan, agama, NIK) sesuai standar ATS.' : 'Removed sensitive personal bias fields (photo, DOB, marital status, religion, National ID).'}",
      "${isId ? 'Menyusun ulang struktur CV mengikuti format referensi ATS modern siap unduh sebagai Word (.docx).' : 'Structured resume into the modern ATS reference format ready for Word (.docx) export.'}"
    ]
  }
}`;
}

const DATE_RANGE_RX =
  /(\(?\b(?:(?:jan|feb|mar|apr|mei|may|jun|jul|agu|aug|sep|okt|oct|nov|des|dec)[a-z]*\.?\s+)?(?:19|20)\d{2}\s*(?:[-–—]|to|s\.?d\.?)\s*(?:(?:(?:jan|feb|mar|apr|mei|may|jun|jul|agu|aug|sep|okt|oct|nov|des|dec)[a-z]*\.?\s+)?(?:19|20)\d{2}(?:\s*\((?:expected|perkiraan)\))?|present|sekarang|now|current)\)?|\(?\b(?:jan|feb|mar|apr|mei|may|jun|jul|agu|aug|sep|okt|oct|nov|des|dec)[a-z]*\.?\s+(?:19|20)\d{2}\)?|\((?:19|20)\d{2}\)|\b(?:19|20)\d{2}\s*$)/i;

function _extractTitleAndDate(line) {
  const clean = String(line || '').replace(/^[•\-*–—]\s*/, '').trim();
  const match = clean.match(DATE_RANGE_RX);
  if (!match) {
    return { title: clean, date: '' };
  }
  const rawDate = match[0].replace(/^\(|\)$/g, '').trim();
  const title = clean
    .replace(match[0], '')
    .replace(/[\s|,\-–—]+$/, '')
    .replace(/^[\s|,\-–—]+/, '')
    .trim();
  return { title: title || clean, date: rawDate };
}

function _looksLikeEntryHeader(rawLine) {
  const trimmed = String(rawLine || '').trim();
  if (!trimmed) return false;
  if (/^[•\-*]\s+/.test(trimmed)) return false;
  if (trimmed.length > 110) return false;
  if (DATE_RANGE_RX.test(trimmed)) return true;
  if (
    /^(pt|cv|inc|corp|ltd|yayasan|universitas|institut|politeknik|sma|smk)\b/i.test(
      trimmed
    )
  ) {
    return true;
  }
  return false;
}

function _buildStructuredEntries(rawItems, { isId, upgradeBullets = false, defaultTitle = '' }) {
  const entries = [];
  let current = null;

  for (const rawLine of rawItems) {
    const isExplicitBullet = /^[•\-*–—]\s+/.test(rawLine);
    const stripped = rawLine.replace(/^[•\-*–—]\s*/, '').trim();
    if (stripped.length < 3) continue;

    if (!isExplicitBullet && _looksLikeEntryHeader(rawLine)) {
      const { title, date } = _extractTitleAndDate(stripped);
      current = { title, date, subtitle: '', bullets: [] };
      entries.push(current);
      continue;
    }

    // If previous entry has a title & date, no bullets yet, and this line is a short non-bullet role/subtitle
    if (
      current &&
      !isExplicitBullet &&
      current.bullets.length === 0 &&
      !current.subtitle &&
      stripped.length < 72 &&
      !/[.!?]$/.test(stripped)
    ) {
      // Combine role & company cleanly if current.title is a company name
      if (/^(pt|cv|inc|corp|ltd|yayasan)\b/i.test(current.title) && !current.title.includes('—')) {
        current.title = `${stripped} — ${current.title}`;
      } else {
        current.subtitle = stripped;
      }
      continue;
    }

    if (!current) {
      current = {
        title: defaultTitle || (isId ? 'Pengalaman Relevan' : 'Relevant Experience'),
        date: '',
        subtitle: '',
        bullets: [],
      };
      entries.push(current);
    }

    const bulletText = upgradeBullets ? _upgradeBulletToStar(stripped, isId) : stripped;
    if (bulletText) current.bullets.push(bulletText);
  }

  return entries.filter((e) => e.title || e.bullets.length > 0);
}

/**
 * Generate a dynamic rule-based rewrite following the reference CV structure
 * (Summary, Education, Projects, Experience, Skills, Certifications) while
 * upgrading passive lines into STAR bullets with [placeholder] tags.
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
    lines[1].length < 95 &&
    !/@|\d{4}|\+62|08/.test(lines[1]) &&
    !/^(ringkasan|summary|tentang|profile|pengalaman|experience|pendidikan|education|proyek|projects)/i.test(
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
  const githubMatch = safeText.match(/github\.com\/[a-zA-Z0-9_-]+/i);

  const contact = [
    emailMatch ? emailMatch[0] : '[email@domain.com]',
    linkedinMatch
      ? linkedinMatch[0]
      : (isId ? 'linkedin.com/in/[profil-anda]' : 'linkedin.com/in/[your-profile]'),
  ];
  if (githubMatch) {
    contact.push(githubMatch[0]);
  }
  if (phoneMatch) {
    contact.push(phoneMatch[0].replace(/\s+/g, ' ').trim());
  }
  contact.push(isId ? 'Indonesia' : 'Indonesia (Open to Remote)');

  // 4. Bucket lines into Reference CV sections from the actual CV text
  const expLines = [];
  const projLines = [];
  const eduLines = [];
  const skillLines = [];
  const certLines = [];
  let currentBucket = 'summary';

  const expHeadRx =
    /^(pengalaman(\s+kerja|\s+profesional|\s+organisasi)?|riwayat\s+pekerjaan|work\s+experience|professional\s+experience|experience|employment|internship|magang|organisasi)$/i;
  const projHeadRx =
    /^(proyek(\s+pilihan|\s+utama)?|projects?|selected\s+projects?|portofolio|portfolio)$/i;
  const eduHeadRx =
    /^(pendidikan|riwayat\s+pendidikan|education|academic|kualifikasi\s+akademik)$/i;
  const certHeadRx =
    /^(sertifikasi|certifications?|licenses?\s*(&|and)\s*certifications?|kursus|courses?|pelatihan|training|penghargaan|awards?)$/i;
  const skillHeadRx =
    /^(keahlian(\s+teknis)?|kemampuan|keterampilan|skills|technical\s+skills|core\s+competencies|kompetensi|tools|bahasa)$/i;
  const summaryHeadRx =
    /^(ringkasan(\s+profesional)?|tentang\s+saya|profil(\s+singkat)?|summary|executive\s+summary|profile|about\s+me|objective)$/i;

  for (let i = 1; i < lines.length; i++) {
    const line = lines[i];
    const cleanHeader = line.replace(/[:\-–—•*#]/g, '').trim();

    if (summaryHeadRx.test(cleanHeader)) {
      currentBucket = 'summary';
      continue;
    }
    if (projHeadRx.test(cleanHeader)) {
      currentBucket = 'proj';
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
    if (certHeadRx.test(cleanHeader)) {
      currentBucket = 'cert';
      continue;
    }
    if (skillHeadRx.test(cleanHeader)) {
      currentBucket = 'skill';
      continue;
    }

    // Skip contact lines
    if (/@|\+62|08\d{6,}|linkedin\.com|github\.com/i.test(line) && line.length < 90) {
      continue;
    }

    const stripped = line.replace(/^[•\-*–—]\s*/, '').trim();
    if (stripped.length < 4 || stripped === applicantTitle) continue;

    if (currentBucket === 'cert') {
      if (certLines.length < 12) certLines.push(stripped);
    } else if (
      currentBucket === 'edu' ||
      (currentBucket !== 'exp' &&
        currentBucket !== 'proj' &&
        /\b(universitas|institut|politeknik|sekolah\s+tinggi|sma|smk|s1|d3|d4|bachelor|university|diploma|ipk|gpa)\b/i.test(
          stripped
        ))
    ) {
      if (eduLines.length < 8) eduLines.push(line);
    } else if (currentBucket === 'proj') {
      if (projLines.length < 16) projLines.push(line);
    } else if (currentBucket === 'skill') {
      if (skillLines.length < 8) skillLines.push(stripped);
    } else if (currentBucket === 'exp' || i > 2) {
      if (expLines.length < 16) expLines.push(line);
    }
  }

  // Build structured Education entries
  let eduEntries = _buildStructuredEntries(eduLines, {
    isId,
    upgradeBullets: false,
    defaultTitle: isId ? '[Nama Universitas / Institusi]' : '[University / Institution]',
  });
  if (eduEntries.length === 0) {
    eduEntries = [
      {
        title: isId ? '[Nama Universitas / Institusi]' : '[University / Institution]',
        date: isId ? '[Tahun Masuk] – [Tahun Lulus]' : '[Start Year] – [End Year]',
        subtitle: '',
        bullets: [
          isId
            ? '[Gelar / Jurusan] | IPK [X.XX] / 4.00'
            : '[Degree / Major] | GPA [X.XX] / 4.00',
        ],
      },
    ];
  } else {
    // Normalize single-line education entries like "S1 Teknik Informatika - Universitas Indonesia (2018 - 2022)"
    eduEntries = eduEntries.map((entry) => {
      if (entry.bullets.length === 0 && /\s[-–—]\s/.test(entry.title)) {
        const parts = entry.title.split(/\s[-–—]\s/);
        if (parts.length >= 2) {
          const left = parts[0].trim();
          const right = parts.slice(1).join(' — ').trim();
          const leftIsInst = /\b(universitas|institut|politeknik|university|college|school)\b/i.test(left);
          return {
            title: leftIsInst ? left : right,
            date: entry.date,
            subtitle: '',
            bullets: [leftIsInst ? right : left],
          };
        }
      }
      return entry;
    });
  }

  // Build structured Projects entries (optional — only when present in CV)
  const projEntries = _buildStructuredEntries(projLines, {
    isId,
    upgradeBullets: true,
    defaultTitle: isId ? 'Proyek Pilihan' : 'Selected Project',
  });

  // Build structured Experience entries
  let expEntries = _buildStructuredEntries(expLines, {
    isId,
    upgradeBullets: true,
    defaultTitle: `${applicantTitle} — ${isId ? '[Nama Perusahaan]' : '[Company Name]'}`,
  });
  if (expEntries.length === 0) {
    const fallbackExpLines = lines.slice(2, 8).filter((l) => l.length > 15);
    expEntries = _buildStructuredEntries(fallbackExpLines, {
      isId,
      upgradeBullets: true,
      defaultTitle: `${applicantTitle} — ${isId ? '[Nama Perusahaan]' : '[Company Name]'}`,
    });
  }

  // Build structured Skills groups
  const skillGroups = [];
  if (skillLines.length > 0) {
    for (const sLine of skillLines) {
      const colonIdx = sLine.indexOf(':');
      if (colonIdx > 1 && colonIdx < 36) {
        skillGroups.push({
          category: sLine.slice(0, colonIdx).trim(),
          items: sLine.slice(colonIdx + 1).trim(),
        });
      } else if (skillGroups.length > 0 && skillGroups[skillGroups.length - 1].category === (isId ? 'Keahlian Utama' : 'Core Skills')) {
        skillGroups[skillGroups.length - 1].items += `, ${sLine}`;
      } else {
        skillGroups.push({
          category: isId ? 'Keahlian Utama' : 'Core Skills',
          items: sLine,
        });
      }
    }
  } else {
    skillGroups.push({
      category: isId ? 'Kompetensi Utama' : 'Core Competencies',
      items: isId
        ? `${applicantTitle}, Manajemen Proyek, Komunikasi Profesional, Problem Solving`
        : `${applicantTitle}, Project Execution, Cross-Functional Collaboration, Problem Solving`,
    });
  }

  // Enrich headline with top grounded skills if title is short
  if (!applicantTitle.includes('|') && skillGroups.length > 0) {
    const topSkills = skillGroups
      .flatMap((g) => g.items.split(','))
      .map((s) => s.trim())
      .filter((s) => s.length > 1 && s.length <= 24)
      .slice(0, 4);
    if (topSkills.length >= 2) {
      applicantTitle = `${applicantTitle} | ${topSkills.join(' · ')}`;
    }
  }

  const summaryText = isId
    ? `Profesional di bidang ${role} yang berorientasi pada hasil dengan rekam jejak dalam meningkatkan efisiensi operasional dan kualitas kerja. Terbukti mampu beradaptasi cepat, berkolaborasi lintas fungsi, dan mencapai target terukur sebesar [X]% secara konsisten.`
    : `Results-driven ${role} with a proven track record of executing high-impact initiatives and optimizing operational workflows. Adept at cross-functional collaboration and delivering measurable improvements of [X]% against key performance targets.`;

  // Assemble sections in exact reference order: Education -> Projects (if any) -> Experience -> Skills -> Certifications (if any)
  const sections = [];

  sections.push({
    heading: isId ? 'Pendidikan' : 'Education',
    type: 'education',
    entries: eduEntries,
  });

  if (projEntries.length > 0) {
    sections.push({
      heading: isId ? 'Proyek' : 'Projects',
      type: 'projects',
      entries: projEntries,
    });
  }

  if (expEntries.length > 0) {
    sections.push({
      heading: isId ? 'Pengalaman' : 'Experience',
      type: 'experience',
      entries: expEntries,
    });
  }

  sections.push({
    heading: isId ? 'Keahlian' : 'Skills',
    type: 'skills',
    skillGroups,
  });

  if (certLines.length > 0) {
    sections.push({
      heading: isId ? 'Sertifikasi' : 'Certifications',
      type: 'certifications',
      bullets: certLines,
    });
  }

  return sanitizeRewriteResult(
    {
      cv: {
        language: lang,
        name: applicantName,
        title: applicantTitle,
        contact,
        summary: summaryText,
        sections,
        changes: isId
          ? [
              'Menghapus data pribadi sensitif (pas foto, TTL, agama, status pernikahan, NIK) agar bebas bias dan lolos filter ATS.',
              'Mengonversi poin pengalaman asli Anda menjadi kalimat aktif berpola STAR dengan penanda metrik [X]%.',
              'Menyusun ulang struktur CV mengikuti format referensi ATS modern (Ringkasan, Pendidikan, Proyek, Pengalaman, Keahlian, Sertifikasi) siap diunduh sebagai Word (.docx).',
            ]
          : [
              'Removed sensitive demographic fields (photo, DOB, religion, marital status) for global ATS compliance.',
              'Upgraded your original experience bullets into action-driven STAR statements with [X]% metric placeholders.',
              'Formatted resume into the clean modern ATS reference layout (Summary, Education, Projects, Experience, Skills, Certifications) ready for direct Word (.docx) download.',
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

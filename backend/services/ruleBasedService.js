/**
 * Rule-Based ATS Analysis Engine for LeveledUp Mobile
 * Automatically detects CV language ('en' vs 'id') and returns evaluation in the matching language.
 * Implements 5 International ATS Pillars:
 * 1. personal_info
 * 2. ats_readability
 * 3. keyword_match
 * 4. achievements
 * 5. language_quality
 */

const ROLE_KEYWORDS = {
  'Software Engineer': [
    'Git', 'CI/CD', 'REST API', 'Unit Testing', 'System Architecture',
    'Docker', 'Agile/Scrum', 'Data Structures', 'Microservices', 'Code Review'
  ],
  'Mobile Developer': [
    'Flutter', 'Dart', 'Android', 'iOS', 'State Management',
    'REST API', 'Git', 'Firebase', 'Clean Architecture', 'Mobile UI/UX'
  ],
  'Backend Engineer': [
    'Node.js', 'Express', 'MySQL', 'PostgreSQL', 'Docker',
    'REST API', 'Redis', 'Microservices', 'Authentication', 'Database Indexing'
  ],
  'Frontend Engineer': [
    'JavaScript', 'TypeScript', 'React', 'HTML5', 'CSS3',
    'TailwindCSS', 'Responsive Design', 'State Management', 'Web Performance', 'Git'
  ],
  'Data Analyst': [
    'SQL', 'Python', 'Tableau', 'Power BI', 'Data Cleaning',
    'Statistical Analysis', 'Excel', 'Data Visualization', 'ETL', 'Business Intelligence'
  ],
  'Product Manager': [
    'User Research', 'Product Roadmap', 'A/B Testing', 'Agile/Scrum', 'KPI Tracking',
    'Wireframing', 'Stakeholder Management', 'Sprint Planning', 'Data Analytics', 'PRD'
  ],
  'UI/UX Designer': [
    'Figma', 'User Research', 'Wireframing', 'Prototyping', 'Design Systems',
    'Usability Testing', 'Information Architecture', 'Interaction Design', 'Accessibility', 'User Journey'
  ],
};

/**
 * Detect whether CV text is primarily in Bahasa Indonesia ('id') or English ('en')
 * @param {string} text
 * @returns {'id' | 'en'}
 */
function detectCvLanguage(text) {
  const lower = (text || '').toLowerCase();
  const idPatterns = [
    /\bpengalaman\s+kerja\b/, /\bpendidikan\b/, /\bkeahlian\b/, /\bkemampuan\b/,
    /\bringkasan\b/, /\btentang\s+saya\b/, /\bbertanggung\s+jawab\b/, /\btempat\b/,
    /\btanggal\s+lahir\b/, /\bagama\b/, /\bstatus\s+pernikahan\b/, /\bbekerja\b/,
    /\bperusahaan\b/, /\bmengelola\b/, /\bmembantu\b/, /\blulusan\b/, /\bsekarang\b/,
    /\bpekerja\s+keras\b/, /\bdibawah\s+tekanan\b/, /\bdi\s+bawah\s+tekanan\b/,
  ];
  const enPatterns = [
    /\bexperience\b/, /\beducation\b/, /\bskills\b/, /\bsummary\b/,
    /\bresponsible\s+for\b/, /\buniversity\b/, /\bbachelor\b/, /\bpresent\b/,
    /\bengineered\b/, /\bdeveloped\b/, /\bmanaged\b/, /\bdesigned\b/,
    /\bcollaborated\b/, /\bprojects\b/, /\bcertifications\b/, /\bachievements\b/,
  ];

  let idScore = 0;
  let enScore = 0;
  for (const rx of idPatterns) {
    if (rx.test(lower)) idScore++;
  }
  for (const rx of enPatterns) {
    if (rx.test(lower)) enScore++;
  }

  return idScore > enScore ? 'id' : 'en';
}

/**
 * Infer job role based on keywords present in the CV text
 */
function inferJobRole(text) {
  const lower = text.toLowerCase();
  let bestRole = 'Software Engineer';
  let highestScore = 0;

  for (const [role, keywords] of Object.entries(ROLE_KEYWORDS)) {
    let score = 0;
    if (lower.includes(role.toLowerCase())) score += 5;
    for (const kw of keywords) {
      if (lower.includes(kw.toLowerCase())) score += 1;
    }
    if (score > highestScore) {
      highestScore = score;
      bestRole = role;
    }
  }

  return bestRole;
}

/**
 * Analyze keywords for a given role
 */
function analyzeKeywords(text, role) {
  const keywords = ROLE_KEYWORDS[role] || ROLE_KEYWORDS['Software Engineer'];
  const lower = text.toLowerCase();

  const matched = [];
  const missing = [];

  for (const kw of keywords) {
    if (lower.includes(kw.toLowerCase())) {
      matched.push(kw);
    } else {
      missing.push(kw);
    }
  }

  return {
    jobTitle: role,
    matched,
    missing,
    missingCount: missing.length,
  };
}

/**
 * Main Rule-Based Evaluation (Bilingual: 'id' or 'en')
 * @param {string} text - Raw CV text
 * @param {string} fileName - File name
 * @returns {object} Full analysis result
 */
function analyzeWithRules(text, fileName = 'CV.pdf') {
  const lang = detectCvLanguage(text);
  const isId = lang === 'id';
  const issues = [];

  // 1. Personal Info Bias Checks
  if (/foto|photo|pasfoto|pas foto|image|picture|headshot/i.test(text) || /\b(fotocopy|foto\s*diri)\b/i.test(text)) {
    issues.push({
      id: 'photo',
      category: 'personal_info',
      severity: 'critical',
      title: isId ? 'CV menyertakan foto diri atau penanda foto' : 'CV includes a headshot photo or photo indicator',
      detail: isId
        ? 'Standar ATS modern memprioritaskan kualifikasi objektif. Menyertakan foto dapat memicu bias rekrutmen dan merusak tata letak parser teks.'
        : 'In international ATS standards (US, UK, EU), resumes with photos risk automatic rejection due to anti-discrimination (EEOC) compliance rules.',
      fix: isId
        ? 'Hapus pas foto dan fokuskan bagian atas CV pada nama lengkap, kontak profesional, serta tautan LinkedIn/GitHub.'
        : 'Remove the headshot photo and dedicate your header strictly to your name, contact info, and LinkedIn/GitHub links.',
      rewrite: {
        before: isId ? '[Pas Foto 4x6 di sudut atas]' : '[Headshot Photo in Top Header]',
        after: isId ? '[Hanya teks nama lengkap, email, telepon, dan tautan portofolio]' : '[Clean text header: Name • Email • Phone • LinkedIn • GitHub]',
      },
    });
  }

  if (/tanggal lahir|tempat lahir|date of birth|birth date|tgl lahir|t\.t\.l|ttl\b|usia\s*:\s*\d+|umur\s*:\s*\d+|\bage\s*:\s*\d+/i.test(text)) {
    issues.push({
      id: 'dob_age',
      category: 'personal_info',
      severity: 'critical',
      title: isId ? 'Tercantum tanggal lahir, tempat lahir, atau umur' : 'Contains Date of Birth, Place of Birth, or Age',
      detail: isId
        ? 'Menyertakan usia atau tempat/tanggal lahir (TTL) tidak relevan dengan kompetensi teknis dan berisiko memicu bias usia (ageism).'
        : 'Including your age or date of birth exposes you to age bias and violates international equal-opportunity resume guidelines.',
      fix: isId
        ? 'Hapus bagian Tempat/Tanggal Lahir (TTL) dan Usia dari header profil.'
        : 'Remove Date of Birth and Age from your personal details.',
      rewrite: {
        before: isId ? 'Jakarta, 14 Mei 2001 (Usia: 24 Tahun)' : 'DOB: May 14, 2001 (Age: 24)',
        after: isId ? 'Domisili: Jakarta, Indonesia' : 'Location: Jakarta, Indonesia (Open to Remote)',
      },
    });
  }

  if (/status pernikahan|marital status|status perkawinan|status\s*:\s*(lajang|menikah|single|married|belum menikah)/i.test(text)) {
    issues.push({
      id: 'marital_status',
      category: 'personal_info',
      severity: 'critical',
      title: isId ? 'Menyertakan status pernikahan/perkawinan' : 'Includes marital status information',
      detail: isId
        ? 'Status pernikahan adalah informasi privasi yang tidak memiliki korelasi dengan performa kerja Anda.'
        : 'Marital status is protected personal information and has no bearing on job qualification.',
      fix: isId
        ? 'Hapus baris Status Pernikahan sepenuhnya dari CV.'
        : 'Delete the Marital Status line completely from your resume.',
      rewrite: {
        before: isId ? 'Status: Belum Menikah' : 'Marital Status: Single',
        after: isId ? '[Dihapus sepenuhnya dari header kontak]' : '[Removed completely from header]',
      },
    });
  }

  if (/agama\s*:|religion\s*:|islam|kristen|katolik|hindu|buddha|khonghucu/i.test(text)) {
    issues.push({
      id: 'religion',
      category: 'personal_info',
      severity: 'critical',
      title: isId ? 'Menyertakan informasi agama atau keyakinan' : 'Includes religious affiliation',
      detail: isId
        ? 'Mencantumkan agama pada CV profesional berisiko menimbulkan bias subjektif pada tahap seleksi.'
        : 'Listing religious affiliation violates global anti-bias hiring practices.',
      fix: isId ? 'Hapus baris Agama dari CV Anda.' : 'Remove religion from your resume header.',
      rewrite: {
        before: isId ? 'Agama: Islam' : 'Religion: Islam',
        after: isId ? '[Dihapus sepenuhnya]' : '[Removed completely]',
      },
    });
  }

  if (/\b(nik|ktp|no\.?\s*ktp|national id|nomor induk kependudukan)\b/i.test(text)) {
    issues.push({
      id: 'national_id',
      category: 'personal_info',
      severity: 'critical',
      title: isId ? 'Terdapat nomor identitas kependudukan (NIK/KTP)' : 'Exposes National ID number (NIK/KTP)',
      detail: isId
        ? 'NIK/KTP adalah data privasi sensitif (PII). Mencantumkannya di CV berisiko penyalahgunaan data pribadi.'
        : 'National ID numbers are sensitive Personally Identifiable Information (PII) and should never appear on a resume.',
      fix: isId ? 'Hapus NIK atau nomor KTP dari dokumen CV.' : 'Remove any National ID or passport number from your CV.',
      rewrite: {
        before: 'NIK: 317405XXXXXXXXXX',
        after: isId ? '[Dihapus demi keamanan data pribadi]' : '[Removed for PII data security]',
      },
    });
  }

  // 2. ATS Readability Checks
  const wordCount = text.split(/\s+/).filter(Boolean).length;
  if (wordCount < 150) {
    issues.push({
      id: 'too_short',
      category: 'ats_readability',
      severity: 'warning',
      title: isId ? 'Konten CV terlalu singkat (< 150 kata)' : 'Resume content is too brief (< 150 words)',
      detail: isId
        ? 'CV yang terlalu pendek kurang memberikan konteks mengenai proyek, teknologi, dan dampak kerja Anda.'
        : 'A resume under 150 words lacks sufficient project context and technical depth for ATS ranking.',
      fix: isId
        ? 'Tambahkan 3–4 poin pencapaian terukur pada setiap pengalaman kerja.'
        : 'Expand each work experience entry with 3–4 quantified STAR bullet points.',
      rewrite: {
        before: isId ? 'Software Engineer di PT XYZ (2023)' : 'Software Engineer at XYZ Corp (2023)',
        after: isId
          ? 'Software Engineer — PT XYZ (2023)\n• Mengembangkan layanan API dengan Node.js yang melayani [jumlah] transaksi harian.'
          : 'Software Engineer — XYZ Corp (2023)\n• Engineered Node.js REST APIs serving [number]+ daily requests with [X]% uptime.',
      },
    });
  }

  // 3. Achievements Checks (STAR Method)
  const passivePhrasesRegex = /\b(bertanggung jawab|responsible for|tugas saya|mengelola tugas|duty includes|duties were|melakukan pekerjaan|assisted in|worked on)\b/i;
  if (passivePhrasesRegex.test(text)) {
    issues.push({
      id: 'duties',
      category: 'achievements',
      severity: 'warning',
      title: isId
        ? 'Poin pengalaman masih bergaya daftar tugas pasif, belum pencapaian terukur'
        : 'Experience bullets read like passive duties instead of quantified achievements',
      detail: isId
        ? 'Kalimat seperti "Bertanggung jawab..." hanya menjelaskan deskripsi jabatan, bukan dampak keberhasilan Anda.'
        : 'Phrases like "Responsible for..." describe job expectations rather than your measurable impact (STAR method).',
      fix: isId
        ? 'Gunakan kata kerja aktif di awal kalimat (Mengoptimalkan, Merancang, Memimpin) diikuti hasil terukur.'
        : 'Start bullets with strong action verbs (Architected, Optimized, Spearheaded) followed by quantified metrics.',
      rewrite: {
        before: isId
          ? 'Bertanggung jawab mengelola dan memelihara sistem database perusahaan.'
          : 'Responsible for managing and maintaining the company MySQL database.',
        after: isId
          ? 'Mengoptimalkan indeks query database MySQL, memangkas waktu respons API sebesar [X]% untuk [jumlah] pengguna aktif.'
          : 'Optimized MySQL query indexing, cutting API response latency by [X]% across [number]+ active users.',
      },
    });
  }

  const hasNumbers = /\b\d+(\.\d+)?%|\b\d+\+\s*(users|clients|proyek|projects|pengguna|klien)\b/i.test(text);
  if (!hasNumbers) {
    issues.push({
      id: 'no_metrics',
      category: 'achievements',
      severity: 'warning',
      title: isId
        ? 'Minim metrik angka dan hasil terukur (quantified impact)'
        : 'Lacks quantifiable metrics and measurable outcomes',
      detail: isId
        ? 'Tanpa persentase peningkatan, efisiensi waktu, atau skala pengguna, rekruter sulit menilai skala kontribusi Anda.'
        : 'Without percentages, latency reductions, or user scale, recruiters cannot gauge the magnitude of your work.',
      fix: isId
        ? 'Sertakan angka konkret atau gunakan penanda [X]% pada pencapaian utama Anda.'
        : 'Include concrete metrics (e.g., [X]% faster, [number] users impacted) in at least 3 bullets.',
      rewrite: {
        before: isId ? 'Meningkatkan performa aplikasi mobile.' : 'Improved mobile application performance.',
        after: isId
          ? 'Mempercepat waktu muat layar utama sebesar [X]% dan menurunkan tingkat crash hingga [X]%.'
          : 'Accelerated app cold-start time by [X]% and maintained a [X]% crash-free session rate.',
      },
    });
  }

  // 4. Language Quality & Clichés Checks
  const clichesRegex = /\b(hard-working|hard working|pekerja keras|team player|bisa bekerja di bawah tekanan|mampu bekerja di bawah tekanan|able to work under pressure|out of the box|detail-oriented)\b/i;
  if (clichesRegex.test(text)) {
    issues.push({
      id: 'cliche_words',
      category: 'language_quality',
      severity: 'suggestion',
      title: isId
        ? 'Penggunaan frasa klise ("pekerja keras", "bekerja di bawah tekanan")'
        : 'Uses subjective buzzwords ("hard-working", "work under pressure")',
      detail: isId
        ? 'Klaim subjektif tanpa bukti proyek nyata sering diabaikan oleh rekruter.'
        : 'Generic buzzwords are overused and ignored by recruiters unless backed by concrete delivery metrics.',
      fix: isId
        ? 'Ganti klaim sifat subjektif dengan ringkasan keahlian teknis dan rekam jejak proyek.'
        : 'Replace subjective traits with concrete technical specializations and sprint delivery evidence.',
      rewrite: {
        before: isId
          ? 'Pekerja keras yang mampu bekerja di bawah tekanan tinggi.'
          : 'Hard-working team player able to work under pressure.',
        after: isId
          ? 'Software Engineer dengan fokus pada pengembangan backend Node.js dan aplikasi lintas platform Flutter.'
          : 'Software Engineer specializing in high-throughput Node.js microservices and cross-platform Flutter apps.',
      },
    });
  }

  // 5. Keyword Matching Evaluation
  const detectedRole = inferJobRole(text);
  const keywordAnalysis = analyzeKeywords(text, detectedRole);

  if (keywordAnalysis.missing.length >= 4) {
    issues.push({
      id: 'missing_core_keywords',
      category: 'keyword_match',
      severity: 'warning',
      title: isId
        ? `Beberapa kata kunci industri untuk posisi ${detectedRole} belum tercantum`
        : `Missing core industry keywords for ${detectedRole}`,
      detail: isId
        ? `Sistem ATS memeringkat CV berdasarkan kecocokan kata kunci teknis untuk posisi ${detectedRole}.`
        : `ATS parsers score your resume against core technical competencies expected for a ${detectedRole}.`,
      fix: isId
        ? `Tambahkan keahlian relevan yang Anda kuasai seperti: ${keywordAnalysis.missing.slice(0, 3).join(', ')}.`
        : `Incorporate relevant skills you possess such as: ${keywordAnalysis.missing.slice(0, 3).join(', ')}.`,
      rewrite: {
        before: isId ? 'Keahlian: Pemrograman dasar' : 'Skills: General programming',
        after: `Skills: ${keywordAnalysis.matched.slice(0, 3).concat(keywordAnalysis.missing.slice(0, 2)).join(', ')}`,
      },
    });
  }

  // Score Calculation
  let overallScore = 100;
  for (const issue of issues) {
    if (issue.severity === 'critical') overallScore -= 11;
    else if (issue.severity === 'warning') overallScore -= 7;
    else if (issue.severity === 'suggestion') overallScore -= 3;
  }
  overallScore = Math.max(10, Math.min(100, overallScore));

  let summary = '';
  if (isId) {
    if (overallScore >= 80) {
      summary = 'CV Anda memiliki struktur ATS yang sangat kuat dalam Bahasa Indonesia. Hanya diperlukan sedikit penyempurnaan metrik sebelum dikirim.';
    } else if (overallScore >= 60) {
      summary = 'CV Anda memiliki fondasi yang cukup baik, namun beberapa bagian masih bergaya daftar tugas pasif dan memerlukan tambahan kata kunci teknis.';
    } else {
      summary = 'CV Anda memerlukan perbaikan penting, terutama penghapusan data pribadi sensitif (foto, TTL, agama, NIK) dan konversi tugas menjadi pencapaian terukur.';
    }
  } else {
    if (overallScore >= 80) {
      summary = 'Your English CV has a strong ATS-compliant structure. Only minor metric refinements are needed before applying.';
    } else if (overallScore >= 60) {
      summary = 'Your CV has a solid foundation, but several bullets read like passive duties and miss key role keywords.';
    } else {
      summary = 'Your CV requires substantial fixes: remove personal bias fields and convert passive responsibilities into quantified STAR achievements.';
    }
  }

  return {
    mode: 'global',
    language: lang,
    overallScore,
    summary,
    issues,
    keywordMatch: {
      jobTitle: keywordAnalysis.jobTitle,
      matched: keywordAnalysis.matched,
      missing: keywordAnalysis.missing,
      missingCount: keywordAnalysis.missingCount,
    },
    meta: {
      fileName,
      language: lang,
      analyzedAtLabel: isId ? 'Evaluasi Bahasa Indonesia' : 'English ATS Evaluation',
      engine: 'rule-based',
    },
  };
}

module.exports = {
  analyzeWithRules,
  detectCvLanguage,
  inferJobRole,
  analyzeKeywords,
  ROLE_KEYWORDS,
};

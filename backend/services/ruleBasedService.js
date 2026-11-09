/**
 * Rule-Based ATS Analysis Engine for LeveledUp Mobile
 * Implements 5 International ATS Pillars conforming to mvp.md:
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
 * Infer job role based on keywords present in the CV text
 */
function inferJobRole(text) {
  const lower = text.toLowerCase();
  let bestRole = 'Software Engineer';
  let highestScore = 0;

  for (const [role, keywords] of Object.entries(ROLE_KEYWORDS)) {
    let score = 0;
    // Check if role name itself is mentioned
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
 * Main Rule-Based Evaluation
 * @param {string} text - Raw CV text
 * @param {string} fileName - File name
 * @returns {object} Full analysis result conforming to mvp.md
 */
function analyzeWithRules(text, fileName = 'CV.pdf') {
  const issues = [];
  const lower = text.toLowerCase();

  // ----------------------------------------------------
  // 1. Personal Info Bias Checks (Indonesian CV Habitudes)
  // ----------------------------------------------------
  
  // Photo indicator
  if (/foto|photo|pasfoto|pas foto|image|picture|headshot/i.test(text) || /\b(fotocopy|foto\s*diri)\b/i.test(text)) {
    issues.push({
      id: 'photo',
      category: 'personal_info',
      severity: 'critical',
      title: 'CV menyertakan foto diri atau penanda foto',
      detail: 'Di pasar kerja global (AS, Inggris, Kanada, dll.), HR dilarang menerima CV yang memuat foto demi mematuhi undang-undang ketenagakerjaan non-diskriminasi (EEOC). CV dengan foto berisiko langsung disingkirkan tanpa ditinjau.',
      fix: 'Hapus pas foto dan fokuskan layout CV murni pada konten teks profesional dan riwayat kerja.',
      rewrite: {
        before: '[Pas Foto 4x6 di sudut kanan atas]',
        after: '[Hanya teks nama lengkap, kontak profesional, dan tautan LinkedIn/GitHub]',
      },
    });
  }

  // Date of Birth / Place of Birth / Age
  if (/tanggal lahir|tempat lahir|date of birth|birth date|tgl lahir|t\.t\.l|ttl\b|usia\s*:\s*\d+|umur\s*:\s*\d+|\bage\s*:\s*\d+/i.test(text)) {
    issues.push({
      id: 'dob_age',
      category: 'personal_info',
      severity: 'critical',
      title: 'Tercantum tanggal lahir, tempat lahir, atau umur',
      detail: 'Menyertakan usia atau tanggal lahir memicu bias usia (ageism). Rekruter internasional tidak boleh menilai kandidat berdasarkan usia, melainkan kualifikasi kompetensi.',
      fix: 'Hapus bagian Tempat/Tanggal Lahir (TTL) dan Umur dari informasi profil.',
      rewrite: {
        before: 'Jakarta, 14 Mei 2001 (Usia: 24 Tahun)',
        after: 'Lokasi: Jakarta, Indonesia (Open to Remote / Relocation)',
      },
    });
  }

  // Marital Status
  if (/status pernikahan|marital status|status perkawinan|status\s*:\s*(lajang|menikah|single|married|belum menikah)/i.test(text)) {
    issues.push({
      id: 'marital_status',
      category: 'personal_info',
      severity: 'critical',
      title: 'Menyertakan status pernikahan/perkawinan',
      detail: 'Status perkawinan adalah informasi privasi sensitif yang dilindungi hukum ketenagakerjaan internasional. Hal ini tidak memiliki korelasi dengan kompetensi teknis pekerjaan Anda.',
      fix: 'Hapus baris Status Pernikahan/Perkawinan sepenuhnya dari CV.',
      rewrite: {
        before: 'Status: Belum Menikah / Single',
        after: '[Dihapus sepenuhnya dari header kontak]',
      },
    });
  }

  // Religion
  if (/agama\s*:|religion\s*:|islam|kristen|katolik|hindu|buddha|khonghucu/i.test(text)) {
    issues.push({
      id: 'religion',
      category: 'personal_info',
      severity: 'critical',
      title: 'Menyertakan informasi agama atau keyakinan',
      detail: 'Mencantumkan agama dapat memunculkan kecurigaan bias keyakinan pada rekruter global. Perusahaan multinasional menerapkan standar ketat kesetaraan hak (Equal Opportunity Employer).',
      fix: 'Hapus baris Agama dari CV Anda.',
      rewrite: {
        before: 'Agama: Islam',
        after: '[Dihapus sepenuhnya]',
      },
    });
  }

  // Gender / Sex
  if (/jenis kelamin|gender\s*:|sex\s*:\s*(male|female|pria|wanita|laki-laki|perempuan)/i.test(text)) {
    issues.push({
      id: 'gender',
      category: 'personal_info',
      severity: 'warning',
      title: 'Tercantum jenis kelamin (gender)',
      detail: 'Di pasar kerja Barat, jenis kelamin tidak boleh menjadi pertimbangan rekrutmen. Menyertakannya terkesan kuno bagi standar ATS modern.',
      fix: 'Hapus keterangan jenis kelamin.',
      rewrite: {
        before: 'Jenis Kelamin: Laki-laki / Male',
        after: '[Dihapus sepenuhnya]',
      },
    });
  }

  // NIK / National Identity / KTP
  if (/\b(nik|ktp|no\.?\s*ktp|national id|nomor induk kependudukan)\b/i.test(text)) {
    issues.push({
      id: 'national_id',
      category: 'personal_info',
      severity: 'critical',
      title: 'Terdapat nomor identitas kependudukan (NIK/KTP)',
      detail: 'NIK/KTP adalah data pribadi yang sangat rahasia (PII). Mempublikasikannya di CV berisiko pencurian identitas dan melanggar praktik keamanan data internasional.',
      fix: 'Hapus NIK atau nomor identitas nasional apapun dari dokumen lamaran kerja.',
      rewrite: {
        before: 'NIK: 317405XXXXXXXXXX',
        after: '[Dihapus sepenuhnya demi keamanan data pribadi]',
      },
    });
  }

  // Physical attributes (Blood type, height, weight)
  if (/golongan darah|gol\.?\s*darah|tinggi badan|berat badan|blood type|height\s*:|weight\s*:/i.test(text)) {
    issues.push({
      id: 'physical_attributes',
      category: 'personal_info',
      severity: 'warning',
      title: 'Mencantumkan data fisik (tinggi, berat badan, atau golongan darah)',
      detail: 'Karakteristik fisik tidak relevan untuk sebagian besar pekerjaan profesional internasional dan dapat memicu bias penampilan.',
      fix: 'Hapus data tinggi badan, berat badan, dan golongan darah.',
      rewrite: {
        before: 'Tinggi: 175 cm | Berat: 68 kg | Gol. Darah: O',
        after: '[Dihapus sepenuhnya]',
      },
    });
  }

  // Hobbies / Interests (often filler)
  if (/\b(hobi|hobby|hobbies|kegemaran)\b/i.test(text) && !/technical projects|open source/i.test(text)) {
    issues.push({
      id: 'hobbies',
      category: 'personal_info',
      severity: 'suggestion',
      title: 'Menyertakan bagian hobi non-profesional',
      detail: 'Hobi umum seperti membaca, menonton film, atau traveling membuang ruang berharga pada resume satu halaman (one-page resume).',
      fix: 'Ganti bagian hobi dengan proyek portofolio, kontribusi open source, atau sertifikasi yang relevan.',
      rewrite: {
        before: 'Hobi: Membaca buku teknologi dan fotografi',
        after: 'Projects: Kontributor open-source pada repository Flutter & Express dengan 200+ stars.',
      },
    });
  }

  // ----------------------------------------------------
  // 2. ATS Readability & Structure Checks
  // ----------------------------------------------------
  
  // Table or complex layout indicators
  if (/\|\s*---|\+\-\-\-\+/i.test(text) || (/tabel|table/i.test(text) && /kolom|column/i.test(text))) {
    issues.push({
      id: 'table_layout',
      category: 'ats_readability',
      severity: 'critical',
      title: 'Terdeteksi struktur tabel atau multi-kolom yang kompleks',
      detail: 'Sistem ATS membaca dokumen dari kiri ke kanan secara linear. Tabel dan tata letak multi-kolom dapat memecah baris teks sehingga pengalaman kerja dan tanggal bercampur aduk.',
      fix: 'Gunakan tata letak satu kolom (single-column layout) berbasis heading teks standar yang bersih.',
      rewrite: {
        before: '| Perusahaan | Posisi | Tahun |\n| PT ABC | Dev | 2023 |',
        after: 'Software Engineer — PT ABC (Jan 2023 – Sekarang)',
      },
    });
  }

  // Length check: CV should ideally be concise
  const wordCount = text.split(/\s+/).filter(Boolean).length;
  if (wordCount < 150) {
    issues.push({
      id: 'too_short',
      category: 'ats_readability',
      severity: 'warning',
      title: 'Konten CV terlalu singkat atau kurang rincian deskripsi',
      detail: 'CV dengan kata yang terlalu sedikit (< 150 kata) mengindikasikan ketiadaan rincian proyek dan tanggung jawab penting.',
      fix: 'Tambahkan poin-poin penjelasan pengalaman kerja yang menjelaskan teknologi dan pencapaian Anda.',
      rewrite: {
        before: 'Magang IT di PT XYZ (2023)',
        after: 'IT Software Intern — PT XYZ (Jun – Agu 2023)\n• Mengembangkan modul autentikasi backend...',
      },
    });
  }

  // ----------------------------------------------------
  // 3. Achievements & Action Verbs Checks (STAR Method)
  // ----------------------------------------------------
  
  // Passive responsibility phrases (Daftar Tugas vs Pencapaian)
  const passivePhrasesRegex = /\b(bertanggung jawab|responsible for|tugas saya|mengelola tugas|duty includes|duties were|melakukan pekerjaan)\b/i;
  if (passivePhrasesRegex.test(text)) {
    issues.push({
      id: 'duties',
      category: 'achievements',
      severity: 'warning',
      title: 'Poin pengalaman kerja masih bergaya daftar tugas pasif',
      detail: 'Standar resume global mengharuskan penulisan berbasis dampak dan pencapaian menggunakan kata kerja aksi (Action Verb + Context + Quantifiable Result), bukan sekadar daftar tugas pasif ("Responsible for").',
      fix: 'Tulis ulang poin pengalaman menggunakan pola STAR: mulai dengan kata kerja aktif kuat dan sertakan dampak hasil kerja.',
      rewrite: {
        before: 'Bertanggung jawab mengelola dan memelihara sistem database perusahaan.',
        after: 'Mengoptimalkan performa query database MySQL, memangkas waktu respon sebesar [X]% untuk [jumlah] pengguna aktif.',
      },
    });
  }

  // Lack of metrics / numbers
  const hasNumbers = /\b\d+(\.\d+)?%|\b\d+\+\s*(users|clients|proyek|projects|jt|juta|k|m)\b|\b(meningkatkan|memangkas|reduced|increased|improved)\s+sebesar\b/i.test(text);
  if (!hasNumbers) {
    issues.push({
      id: 'no_metrics',
      category: 'achievements',
      severity: 'warning',
      title: 'Ketiadaan metrik dan pencapaian terukur (quantified results)',
      detail: 'Tanpa angka persentase, penghematan waktu, atau skala pengguna, rekruter tidak dapat mengukur seberapa signifikan kontribusi nyata Anda.',
      fix: 'Sertakan metrik terukur pada setidaknya 2–3 poin pengalaman kerja utama (misal: persentase efisiensi, volume data, atau jumlah pengguna).',
      rewrite: {
        before: 'Memperbaiki performa aplikasi mobile.',
        after: 'Mempercepat waktu startup aplikasi sebesar [X]% dan mengurangi tingkat crash hingga [X]%.',
      },
    });
  }

  // ----------------------------------------------------
  // 4. Language Quality & Clichés Checks
  // ----------------------------------------------------
  
  // Indonesian language detected in global mode
  const indonesianWordsRegex = /\b(pengalaman kerja|pendidikan|kemampuan|keahlian|riwayat pendidikan|tentang saya|kontak)\b/i;
  if (indonesianWordsRegex.test(text)) {
    issues.push({
      id: 'indonesian_language',
      category: 'language_quality',
      severity: 'critical',
      title: 'CV masih menggunakan Bahasa Indonesia untuk lamaran global',
      detail: 'Untuk melamar lowongan remote internasional atau perusahaan multinasional, CV wajib ditulis 100% dalam Bahasa Inggris profesional yang natural.',
      fix: 'Terjemahkan seluruh CV ke dalam Bahasa Inggris berstandar industri dengan terminologi teknis yang tepat.',
      rewrite: {
        before: 'Pengalaman Kerja: Pengembang Perangkat Lunak',
        after: 'Professional Experience: Software Engineer',
      },
    });
  }

  // Cliché buzzwords
  const clichesRegex = /\b(hard-working|hard working|pekerja keras|team player|bisa bekerja di bawah tekanan|able to work under pressure|out of the box|detail-oriented|detail oriented|motivated self-starter)\b/i;
  if (clichesRegex.test(text)) {
    issues.push({
      id: 'cliche_words',
      category: 'language_quality',
      severity: 'suggestion',
      title: 'Penggunaan frasa klise yang menurunkan impresi profesional',
      detail: 'Frasa seperti "hard-working", "team player", atau "work under pressure" adalah kata klise (buzzwords) yang dipakai oleh jutaan pelamar dan diabaikan rekruter.',
      fix: 'Tunjukkan etos kerja melalui bukti konkret proyek nyata, bukan sekadar klaim sifat subjektif.',
      rewrite: {
        before: 'A hard-working team player able to work under high pressure.',
        after: 'Collaborated across cross-functional engineering teams to ship high-priority releases on tight 2-week sprint cycles.',
      },
    });
  }

  // ----------------------------------------------------
  // 5. Keyword Matching Evaluation
  // ----------------------------------------------------
  const detectedRole = inferJobRole(text);
  const keywordAnalysis = analyzeKeywords(text, detectedRole);

  if (keywordAnalysis.missing.length >= 4) {
    issues.push({
      id: 'missing_core_keywords',
      category: 'keyword_match',
      severity: 'warning',
      title: `Banyak kata kunci standar industri untuk posisi ${detectedRole} belum ditemukan`,
      detail: `ATS mencocokkan CV Anda dengan standar kata kunci posisi ${detectedRole}. Dokumen Anda belum memuat beberapa keahlian esensial.`,
      fix: `Tambahkan keahlian teknis terkait seperti: ${keywordAnalysis.missing.slice(0, 3).join(', ')} jika memang Anda menguasainya.`,
      rewrite: {
        before: 'Keahlian: Pemrograman umum dan komputer',
        after: `Skills: ${keywordAnalysis.matched.slice(0, 3).concat(keywordAnalysis.missing.slice(0, 2)).join(', ')}`,
      },
    });
  }

  // ----------------------------------------------------
  // Score Calculation (Rule-Based Penalty)
  // Section 4.2: Initial 100, critical: -11, warning: -7, suggestion: -3, min: 10
  // ----------------------------------------------------
  let overallScore = 100;
  for (const issue of issues) {
    if (issue.severity === 'critical') {
      overallScore -= 11;
    } else if (issue.severity === 'warning') {
      overallScore -= 7;
    } else if (issue.severity === 'suggestion') {
      overallScore -= 3;
    }
  }

  overallScore = Math.max(10, Math.min(100, overallScore));

  // Build high-level summary
  let summary = '';
  if (overallScore >= 80) {
    summary = 'CV Anda memiliki struktur yang sangat kuat dan mendekati standar ATS global. Tinggal sedikit polesan minor sebelum siap dikirim.';
  } else if (overallScore >= 60) {
    summary = 'CV Anda memiliki fondasi yang cukup baik, namun terdapat beberapa masalah format dan kata kunci yang perlu dipoles agar lolos filter ATS internasional.';
  } else if (overallScore >= 40) {
    summary = 'CV Anda memerlukan perbaikan substansial pada struktur, penghapusan data bias pribadi, dan konversi daftar tugas menjadi pencapaian terukur.';
  } else {
    summary = 'CV Anda berisiko tinggi langsung tersaring oleh ATS internasional karena menyertakan data pribadi berisiko bias hukum atau format yang tidak kompatibel.';
  }

  return {
    mode: 'global',
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
      analyzedAtLabel: 'Dianalisis Sistem (Aturan ATS Global)',
      engine: 'rule-based',
    },
  };
}

module.exports = {
  analyzeWithRules,
  inferJobRole,
  analyzeKeywords,
  ROLE_KEYWORDS,
};


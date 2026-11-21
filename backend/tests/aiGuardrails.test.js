const {
  normalizeLanguage,
  detectTextLanguage,
  resolveRequestLanguage,
  formatBilingualError,
  createServiceError,
  validateCvText,
  validateWinInput,
} = require('../services/bilingualValidation');
const {
  parseGeminiJson,
  hasQuantifiedMetric,
  hasBracketPlaceholder,
  sanitizeFabricatedMetrics,
} = require('../services/aiGuardrails');
const { parsePdfBuffer } = require('../services/pdfService');
const { analyzeWithRules, buildSkillGapActions } = require('../services/ruleBasedService');
const { analyzeCv } = require('../services/aiAnalysisService');
const { rewriteCv, generateFallbackRewrite } = require('../services/aiRewriteService');
const {
  generateStarBullet,
  generateFallbackStarBullet,
  mergeWinsIntoCvObject,
} = require('../services/aiWinService');

const CLEAN_EN_CV = `
Jane Doe
Backend Engineer
Email: jane.doe@example.com | Jakarta, Indonesia

Summary:
Backend Engineer building Node.js and MySQL web services for internal tools and image processing APIs.

Experience:
PT Tech Nusantara (2023 - Present)
Backend Engineer
- Responsible for maintaining REST APIs and database backups.
- Worked on user authentication module and request logging.

Education:
B.S. in Computer Science - University of Indonesia (2022)

Skills:
Node.js, Express, MySQL, Git
`;

const CLEAN_ID_CV = `
Siti Rahmawati
Data Analyst
Email: siti.rahmawati@example.com | Bandung, Indonesia

Ringkasan:
Pekerja keras dan mampu bekerja di bawah tekanan.

Pengalaman Kerja:
PT Karya Data (2023 - Sekarang)
Data Analyst
- Bertanggung jawab membuat laporan mingguan penjualan menggunakan Excel dan SQL.
- Membantu tim bisnis membersihkan data pelanggan.

Pendidikan:
S1 Statistika - Institut Teknologi Bandung (2022)

Keahlian:
SQL, Excel, Python
`;

function createMockAiClient(handler) {
  return {
    models: {
      generateContent: handler,
    },
  };
}

/**
 * Runs unit & guardrail parity tests using the caller's assert(condition, message) helper.
 */
async function runGuardrailTests(assert) {
  console.log('\n🔹 Test 8: Bilingual Validation, Detection & Standardized Errors');

  assert(normalizeLanguage('id-ID') === 'id', 'normalizeLanguage("id-ID") -> "id"');
  assert(normalizeLanguage('EN_us') === 'en', 'normalizeLanguage("EN_us") -> "en"');
  assert(
    normalizeLanguage('auto', 'Membuat dashboard laporan penjualan mingguan') === 'id',
    'normalizeLanguage("auto") detects short Indonesian Brag Doc win as "id"'
  );
  assert(
    detectTextLanguage(
      'CV Anda memiliki struktur ATS yang sangat kuat dalam Bahasa Indonesia. Hanya diperlukan sedikit penyempurnaan metrik.'
    ) === 'id',
    'detectTextLanguage classifies Indonesian rule-based ATS summary as "id"'
  );
  assert(
    detectTextLanguage('Built automated weekly sales dashboard in Excel') === 'en',
    'detectTextLanguage classifies short English win as "en"'
  );
  assert(
    resolveRequestLanguage({ acceptLanguage: 'id-ID,id;q=0.9,en;q=0.8' }) === 'id',
    'resolveRequestLanguage honors Accept-Language header when text is absent'
  );

  const errPayloadId = formatBilingualError('TEXT_TOO_SHORT', 'id');
  const errPayloadEn = formatBilingualError('TEXT_TOO_SHORT', 'en');
  assert(
    errPayloadId.status === 400 &&
      errPayloadId.body.code === 'TEXT_TOO_SHORT' &&
      errPayloadId.body.language === 'id' &&
      errPayloadId.body.error === errPayloadId.body.errorId &&
      errPayloadEn.body.error === errPayloadEn.body.errorEn,
    'formatBilingualError returns standardized bilingual payload in both id and en'
  );

  let shortCvErr = null;
  try {
    validateCvText('short', { language: 'en' });
  } catch (e) {
    shortCvErr = e;
  }
  assert(
    shortCvErr && shortCvErr.status === 400 && shortCvErr.code === 'TEXT_TOO_SHORT' && shortCvErr.errorEn && shortCvErr.errorId,
    'validateCvText throws standardized bilingual TEXT_TOO_SHORT error'
  );

  let emptyWinErr = null;
  try {
    validateWinInput({ title: 'ab', language: 'en' });
  } catch (e) {
    emptyWinErr = e;
  }
  assert(
    emptyWinErr && emptyWinErr.status === 400 && emptyWinErr.code === 'WIN_TITLE_REQUIRED',
    'validateWinInput rejects title < 3 chars with WIN_TITLE_REQUIRED'
  );

  const normalizedWin = validateWinInput({
    title: 'Menyelesaikan laporan audit bulanan',
    category: 'unknown_category',
    language: 'auto',
  });
  assert(
    normalizedWin.category === 'project_delivery' && normalizedWin.language === 'id',
    'validateWinInput normalizes invalid category to project_delivery and auto-detects id'
  );

  let emptyPdfErr = null;
  try {
    await parsePdfBuffer(Buffer.alloc(0), 'empty.pdf', { language: 'en' });
  } catch (e) {
    emptyPdfErr = e;
  }
  assert(
    emptyPdfErr &&
      emptyPdfErr.status === 400 &&
      emptyPdfErr.code === 'FILE_MISSING' &&
      emptyPdfErr.language === 'en' &&
      typeof emptyPdfErr.errorId === 'string',
    'parsePdfBuffer throws standardized bilingual FILE_MISSING error'
  );

  const skillGapId = buildSkillGapActions('Data Analyst', ['Tableau'], ['SQL'], 'ID-id');
  assert(
    skillGapId.language === 'id' && skillGapId.gaps.length === 1 && hasBracketPlaceholder(skillGapId.gaps[0].sampleBullet),
    'buildSkillGapActions normalizes "ID-id" and produces Indonesian placeholder sample bullet'
  );

  console.log('\n🔹 Test 9: Zero-Hallucination Photo & Schema Guardrails (Live Gemini Mock vs Fallback)');

  // 9a. Rule-based fallback: hasPhoto=false + "image processing" must NEVER flag a photo issue
  const ruleCleanEn = analyzeWithRules(CLEAN_EN_CV, 'Jane.pdf', { hasPhoto: false });
  assert(
    !ruleCleanEn.issues.some((i) => i.id === 'photo' || /photo|foto|headshot/i.test(i.title)),
    'Fallback engine does NOT false-flag photo when hasPhoto=false (even with "image processing" text)'
  );

  // 9b. Live Gemini mock: hallucinated photo issues (explicit & subtle portrait), misclassified personal_info cliché,
  // fabricated metrics in rewrite.after, markdown JSON fence, mismatched missingCount, and 404 model failover
  let callCount = 0;
  const mockAnalysisClient = createMockAiClient(async ({ model }) => {
    callCount++;
    if (callCount === 1) {
      const err404 = new Error(`models/${model} is no longer available`);
      err404.status = 404;
      throw err404;
    }
    const payload = {
      mode: 'global',
      language: 'id',
      overallScore: 15, // intentionally mismatched to verify recalculation
      summary: 'Ringkasan analisis CV Data Analyst.',
      issues: [
        {
          id: 'photo_detected',
          category: 'personal_info',
          severity: 'critical',
          title: 'CV mencantumkan pas foto',
          detail: 'Hapus foto profil dari CV Anda.',
          fix: 'Hapus foto.',
          rewrite: { before: 'Pas foto', after: 'Tanpa foto' },
        },
        {
          id: 'personal_bias',
          category: 'personal_info',
          severity: 'critical',
          title: 'Informasi visual tidak perlu',
          detail: 'Jangan sertakan portrait atau gambar profil di bagian atas.',
          fix: 'Hapus headshot.',
          rewrite: { before: 'Portrait', after: 'Header teks' },
        },
        {
          id: 'ISS-002',
          category: 'personal_info', // misclassified cliché (observed in real Gemini output!)
          severity: 'warning',
          title: 'Ringkasan Profil Terlalu Umum',
          detail: "Pernyataan 'Pekerja keras dan mampu bekerja di bawah tekanan' adalah klise generik.",
          fix: 'Ganti klise dengan keahlian teknis.',
          rewrite: {
            before: 'Pekerja keras dan mampu bekerja di bawah tekanan.',
            after: 'Data Analyst berpengalaman meningkatkan akurasi sebesar 45% untuk 10000 pengguna.',
          },
        },
      ],
      keywordMatch: {
        jobTitle: 'Data Analyst',
        matched: ['SQL', 'Python', 'sql'],
        missing: ['Tableau', 'SQL', 'Power BI'],
        missingCount: 99, // intentionally wrong
      },
    };
    return { text: '```json\n' + JSON.stringify(payload) + '\n```' };
  });

  const liveAnalysis = await analyzeCv(CLEAN_ID_CV, 'Siti_CV.pdf', {
    hasPhoto: false,
    _aiClient: mockAnalysisClient,
    models: ['gemini-2.5-flash', 'gemini-3-flash-preview'],
  });

  assert(callCount === 2 && liveAnalysis.meta.engine === 'gemini', 'analyzeCv automatically fails over past 404 model to next Gemini candidate');
  assert(
    liveAnalysis.issues.length === 1 &&
      !liveAnalysis.issues.some((i) => /photo|foto|portrait|headshot/i.test(`${i.id} ${i.title} ${i.detail}`)),
    'analyzeCv strictly strips both explicit and subtle photo/portrait hallucinations when hasPhoto=false'
  );
  assert(
    liveAnalysis.issues[0].category === 'language_quality',
    'analyzeCv reclassifies misclassified generic cliché out of personal_info to language_quality'
  );
  assert(
    liveAnalysis.overallScore === 93,
    `analyzeCv recalculates overallScore deterministically from verified issues (Expected 93, Got ${liveAnalysis.overallScore})`
  );
  assert(
    !liveAnalysis.issues[0].rewrite.after.includes('45%') &&
      !liveAnalysis.issues[0].rewrite.after.includes('10000') &&
      liveAnalysis.issues[0].rewrite.after.includes('[X]%') &&
      liveAnalysis.issues[0].rewrite.after.includes('[jumlah]'),
    'analyzeCv sanitizes fabricated metrics (45%, 10000 pengguna) in Gemini rewrite.after to [X]% and [jumlah]'
  );
  assert(
    liveAnalysis.keywordMatch.matched.length === 2 &&
      liveAnalysis.keywordMatch.missing.length === 2 &&
      liveAnalysis.keywordMatch.missingCount === 2,
    'analyzeCv deduplicates keywordMatch, removes overlap, and enforces missingCount === missing.length'
  );

  // 9c. Verify photo issue IS retained when hasPhoto=true
  const mockPhotoPresentClient = createMockAiClient(async () => ({
    text: JSON.stringify({
      mode: 'global',
      language: 'en',
      overallScore: 89,
      summary: 'Headshot photo detected.',
      issues: [
        {
          id: 'photo',
          category: 'personal_info',
          severity: 'critical',
          title: 'CV includes a headshot photo',
          detail: 'Remove embedded headshot.',
          fix: 'Delete photo.',
          rewrite: { before: '[Photo]', after: '[Text header]' },
        },
      ],
      keywordMatch: { jobTitle: 'Backend Engineer', matched: ['Node.js'], missing: ['Docker'], missingCount: 1 },
    }),
  }));
  const liveWithPhoto = await analyzeCv(CLEAN_EN_CV, 'Jane_Photo.pdf', {
    hasPhoto: true,
    _aiClient: mockPhotoPresentClient,
  });
  assert(
    liveWithPhoto.issues.some((i) => i.id === 'photo'),
    'analyzeCv preserves photo issue when hasPhoto=true'
  );

  console.log('\n🔹 Test 10: Zero-Hallucination Metric & Bias Parity in Rewrite & Win Services');

  // 10a. Helper checks
  assert(
    !hasQuantifiedMetric('Launched Q3 2025 API v2 (+62 812 3456 7890, Pas Foto 4x6, Usia: 25 Tahun)'),
    'hasQuantifiedMetric ignores years, quarters, versions, phone numbers, ages, and 4x6 photo dimensions'
  );
  assert(
    hasQuantifiedMetric('Increased organic leads by 35% across 1200 users'),
    'hasQuantifiedMetric recognizes genuine percentage and count+unit metrics'
  );
  assert(
    sanitizeFabricatedMetrics('Reduced latency by 42% for 500 clients and saved Rp 50 juta', 'Improved latency by 42%', 'id') ===
      'Reduced latency by 42% for [jumlah] clients and saved [nominal]',
    'sanitizeFabricatedMetrics preserves source metric (42%) while replacing ungrounded metrics with placeholders'
  );
  assert(
    parseGeminiJson('```json\n{"ok":true}\n```').ok === true,
    'parseGeminiJson strips markdown fences cleanly'
  );

  // 10b. Live Gemini Rewrite mock: leaks bias line + fabricates 60% & 500 clients + omits placeholder on bullet
  const mockRewriteClient = createMockAiClient(async () => ({
    text: JSON.stringify({
      cv: {
        language: 'en',
        name: 'Jane Doe',
        title: 'Backend Engineer',
        contact: ['jane.doe@example.com', 'Religion: Islam', 'DOB: May 14, 2000'],
        summary: 'Backend Engineer who boosted throughput by 60% for 500 clients.',
        sections: [
          {
            heading: 'Professional Experience',
            bullets: [
              'PT Tech Nusantara | Backend Engineer (2023 - Present)',
              'Engineered REST APIs reducing latency by 48% across 2000 users.',
              'Maintained user authentication module and request logging.',
              'Marital Status: Single',
            ],
          },
          {
            heading: 'Skills',
            bullets: ['Node.js, Express, MySQL, Git'],
          },
        ],
        changes: ['Upgraded bullets to STAR format.'],
      },
    }),
  }));

  const guardedRewrite = await rewriteCv(CLEAN_EN_CV, { _aiClient: mockRewriteClient });
  const rewriteExpBullets = guardedRewrite.cv.sections[0].bullets;
  assert(
    guardedRewrite.engine === 'gemini' &&
      !guardedRewrite.cv.contact.some((c) => /religion|dob/i.test(c)) &&
      !rewriteExpBullets.some((b) => /marital status/i.test(b)),
    'rewriteCv strips leaked bias lines (Religion, DOB, Marital Status) from live Gemini output'
  );
  assert(
    !guardedRewrite.cv.summary.includes('60%') &&
      !guardedRewrite.cv.summary.includes('500') &&
      guardedRewrite.cv.summary.includes('[X]%') &&
      guardedRewrite.cv.summary.includes('[number]'),
    'rewriteCv replaces fabricated metrics in Gemini summary with [X]% and [number]'
  );
  assert(
    rewriteExpBullets[0] === 'PT Tech Nusantara | Backend Engineer (2023 - Present)' &&
      !rewriteExpBullets[1].includes('48%') &&
      !rewriteExpBullets[1].includes('2000') &&
      hasBracketPlaceholder(rewriteExpBullets[1]) &&
      hasBracketPlaceholder(rewriteExpBullets[2]),
    'rewriteCv preserves company/date headers, strips fabricated metrics, and guarantees [placeholder] on metric-less bullets'
  );

  // 10c. Fallback Rewrite bilingual parity on English CV
  const fallbackEnRewrite = generateFallbackRewrite(CLEAN_EN_CV);
  assert(
    fallbackEnRewrite.engine === 'rule-based' &&
      fallbackEnRewrite.cv.language === 'en' &&
      !JSON.stringify(fallbackEnRewrite.cv.contact).includes('[profil-anda]') &&
      JSON.stringify(fallbackEnRewrite.cv.contact).includes('[your-profile]'),
    'generateFallbackRewrite uses English contact placeholder [your-profile] for English CVs'
  );

  // 10d. Live Gemini Win mock: fabricates 45% and 12 teams on a metric-less win containing year/quarter (Q3 2025)
  const mockWinFabricatedClient = createMockAiClient(async () => ({
    text: JSON.stringify({
      starBullet: 'Spearheaded Q3 2025 onboarding workflow redesign, cutting manual effort by 45% across 12 teams.',
      language: 'en',
      hasPlaceholder: false,
    }),
  }));
  const guardedWinEn = await generateStarBullet({
    title: 'Launched Q3 2025 onboarding workflow redesign',
    impactMetric: '',
    category: 'process_quality',
    language: 'en',
    _aiClient: mockWinFabricatedClient,
  });
  assert(
    guardedWinEn.engine === 'gemini' &&
      !guardedWinEn.starBullet.includes('45%') &&
      !guardedWinEn.starBullet.includes('12 teams') &&
      guardedWinEn.starBullet.includes('[X]%') &&
      guardedWinEn.starBullet.includes('[number] teams') &&
      guardedWinEn.hasPlaceholder === true,
    'generateStarBullet strips fabricated 45% & 12 teams even when title contains Q3 2025'
  );

  // 10e. Live Gemini Win mock: returns bullet with NO metric and NO placeholder on metric-less ID win
  const mockWinMissingPlaceholderClient = createMockAiClient(async () => ({
    text: JSON.stringify({
      starBullet: 'Mengoptimalkan proses rekonsiliasi laporan keuangan bulanan secara menyeluruh.',
      language: 'id',
      hasPlaceholder: false,
    }),
  }));
  const guardedWinId = await generateStarBullet({
    title: 'Mengoptimalkan proses rekonsiliasi laporan keuangan bulanan',
    impactMetric: '',
    category: 'process_quality',
    language: 'id',
    _aiClient: mockWinMissingPlaceholderClient,
  });
  assert(
    guardedWinId.language === 'id' &&
      guardedWinId.hasPlaceholder === true &&
      guardedWinId.starBullet.includes('[X]%'),
    'generateStarBullet appends Indonesian [X]% placeholder when Gemini omits placeholder on metric-less win'
  );

  // 10f. Fallback Win preserves explicit metric without overwriting it
  const fallbackWinWithMetric = generateFallbackStarBullet({
    title: 'Mengoptimalkan kampanye SEO produk',
    impactMetric: 'meningkatkan leads organik sebesar 35%',
    category: 'metrics_growth',
    language: 'id',
  });
  assert(
    fallbackWinWithMetric.starBullet.includes('35%') && fallbackWinWithMetric.hasPlaceholder === false,
    'generateFallbackStarBullet preserves explicit user metric (35%) without unnecessary placeholder'
  );

  // 10g. mergeWinsIntoCvObject without baseCv uses clean placeholders (no hardcoded identity) and deduplicates
  const merged = mergeWinsIntoCvObject(null, [
    { starBullet: 'Automated reporting pipeline, improving speed by [X]%.', language: 'en' },
    { starBullet: 'Automated reporting pipeline, improving speed by [X]%.', language: 'en' },
  ]);
  assert(
    merged.mergedCount === 1 &&
      merged.cv.name === '[Full Name]' &&
      merged.cv.contact.includes('[email@domain.com]'),
    'mergeWinsIntoCvObject deduplicates bullets and avoids fabricating hardcoded personal info'
  );
}

module.exports = {
  runGuardrailTests,
};

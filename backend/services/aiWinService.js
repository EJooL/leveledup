const { ai, isAiAvailable } = require('../config/ai');
const { detectCvLanguage } = require('./ruleBasedService');

const CATEGORY_VERBS = {
  en: {
    project_delivery: ['Delivered', 'Executed', 'Launched', 'Spearheaded'],
    metrics_growth: ['Accelerated', 'Increased', 'Grew', 'Expanded'],
    process_quality: ['Streamlined', 'Optimized', 'Standardized', 'Automated'],
    leadership_teamwork: ['Collaborated', 'Coordinated', 'Facilitated', 'Led'],
  },
  id: {
    project_delivery: ['Menyelesaikan dan meluncurkan', 'Mengeksekusi', 'Merancang', 'Mengembangkan'],
    metrics_growth: ['Meningkatkan', 'Mempercepat pertumbuhan', 'Memperluas', 'Mengoptimalkan capaian'],
    process_quality: ['Menyederhanakan dan mengoptimalkan', 'Menstandarisasi', 'Mengotomasi', 'Meningkatkan kualitas'],
    leadership_teamwork: ['Mengkoordinasikan', 'Berkolaborasi lintas fungsi dalam', 'Memimpin inisiatif', 'Memfasilitasi'],
  },
};

function buildWinSystemPrompt(lang) {
  const isId = lang === 'id';
  const langName = isId ? 'Bahasa Indonesia' : 'English';

  return `You are LeveledUp Brag Doc Engine, an expert ATS resume writer for graduates and professionals across all fields (Data, Marketing, Finance/Accounting, Design, HR, Operations, and Engineering).

LANGUAGE RULE:
Write the output STAR bullet strictly in **${langName}**!

ZERO-HALLUCINATION POLICY (CRITICAL):
1. NEVER invent or fabricate any numbers, percentages, currency amounts, or company names that the user did not provide.
2. If the user provided a specific metric in "impactMetric", incorporate that EXACT metric naturally.
3. If the user did NOT provide a number or measurable metric, you MUST insert a bracketed placeholder such as ${isId ? '[X]%, [jumlah], atau [metrik dampak]' : '[X]%, [number], or [target metric]'} so the user can fill in their true number later.
4. Keep the bullet to 1 concise, high-impact sentence following the STAR pattern: Strong Action Verb + Task/Context + Quantified Result (or [placeholder]).

Return ONLY valid JSON matching:
{
  "starBullet": "Single STAR bullet sentence in ${langName}",
  "language": "${lang}",
  "hasPlaceholder": true
}`;
}

/**
 * Deterministic Zero-Hallucination STAR bullet generator (Bilingual: 'id' or 'en').
 * Never invents numbers; uses [placeholder] brackets when metrics are omitted.
 */
function generateFallbackStarBullet({ title, impactMetric = '', category = 'project_delivery', language }) {
  const cleanTitle = (title || '').trim().replace(/^[•\-*]\s*/, '').replace(/\.$/, '');
  const cleanImpact = (impactMetric || '').trim().replace(/\.$/, '');
  const detectedLang = language === 'id' || language === 'en'
    ? language
    : detectCvLanguage(`${cleanTitle} ${cleanImpact}`);
  const isId = detectedLang === 'id';

  const verbs = (CATEGORY_VERBS[detectedLang] && CATEGORY_VERBS[detectedLang][category])
    || CATEGORY_VERBS[detectedLang].project_delivery;
  const actionVerb = verbs[0];

  // Check if title already starts with a strong verb or if we should polish it
  const lowerTitle = cleanTitle.toLowerCase();
  const startsWithPassiveId = /^(bertanggung\s+jawab|membantu|melakukan|mengerjakan|ikut\s+serta)\s+/i;
  const startsWithPassiveEn = /^(responsible\s+for|assisted\s+in|helped\s+with|worked\s+on|participated\s+in)\s+/i;

  let coreAction = cleanTitle;
  if (isId && startsWithPassiveId.test(coreAction)) {
    coreAction = `${actionVerb} ${coreAction.replace(startsWithPassiveId, '')}`;
  } else if (!isId && startsWithPassiveEn.test(coreAction)) {
    coreAction = `${actionVerb} ${coreAction.replace(startsWithPassiveEn, '')}`;
  } else if (coreAction.length > 0) {
    coreAction = coreAction.charAt(0).toUpperCase() + coreAction.slice(1);
  }

  const hasNumberInTitleOrImpact = /\d+%|\b\d+([.,]\d+)?\s*(x|k|ribu|juta|users|pengguna|klien|clients|proyek|projects|jam|hours|hari|days|minggu|weeks|bulan|months|rupiah|idr|usd|leads|transaksi|laporan|reports)\b/i.test(
    `${coreAction} ${cleanImpact}`
  );

  let starBullet = '';
  if (cleanImpact.length > 0) {
    if (hasNumberInTitleOrImpact || /\[.+\]/.test(cleanImpact)) {
      starBullet = isId
        ? `${coreAction}, menghasilkan dampak terukur berupa ${cleanImpact}.`
        : `${coreAction}, delivering measurable impact of ${cleanImpact}.`;
    } else {
      starBullet = isId
        ? `${coreAction}, meningkatkan ${cleanImpact} sebesar [X]%.`
        : `${coreAction}, improving ${cleanImpact} by [X]%.`;
    }
  } else if (hasNumberInTitleOrImpact || /\[.+\]/.test(coreAction)) {
    starBullet = `${coreAction}.`;
  } else {
    starBullet = isId
      ? `${coreAction}, meningkatkan efektivitas dan capaian target sebesar [X]% pada [metrik/jumlah].`
      : `${coreAction}, improving overall outcome efficiency by [X]% across [target metric].`;
  }

  return {
    starBullet,
    language: detectedLang,
    hasPlaceholder: /\[.+\]/.test(starBullet),
    engine: 'rule-based',
  };
}

/**
 * Convert a user's logged achievement into an ATS-ready STAR bullet via Gemini or fallback.
 */
async function generateStarBullet({ title, impactMetric = '', category = 'project_delivery', language }) {
  const detectedLang = language === 'id' || language === 'en'
    ? language
    : detectCvLanguage(`${title || ''} ${impactMetric || ''}`);

  if (!isAiAvailable()) {
    return generateFallbackStarBullet({
      title,
      impactMetric,
      category,
      language: detectedLang,
    });
  }

  try {
    const prompt = `Convert this logged work/academic achievement into a single ATS STAR bullet:
Achievement: ${title}
Impact / Metric provided by user: ${impactMetric || '(None provided — use bracketed [placeholder] for missing metrics)'}
Category: ${category}
Language: ${detectedLang === 'id' ? 'Bahasa Indonesia' : 'English'}`;

    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: prompt,
      config: {
        systemInstruction: buildWinSystemPrompt(detectedLang),
        responseMimeType: 'application/json',
      },
    });

    const outputText =
      response.text ||
      (response.candidates && response.candidates[0]?.content?.parts[0]?.text);
    if (!outputText) {
      throw new Error('Empty response from Gemini win bullet generator');
    }

    const parsed = JSON.parse(outputText);
    if (!parsed.starBullet || typeof parsed.starBullet !== 'string') {
      throw new Error('Invalid JSON structure from Gemini win bullet generator');
    }

    // Enforce Zero-Hallucination: if user gave no numbers in title or impactMetric, ensure placeholder exists
    const userHadNumber = /\d/.test(`${title || ''} ${impactMetric || ''}`);
    let bullet = parsed.starBullet.trim();
    if (!userHadNumber && !/\[.+\]/.test(bullet)) {
      bullet = bullet.replace(/\.$/, '') + (detectedLang === 'id' ? ' sebesar [X]%.' : ' by [X]%.');
    }

    return {
      starBullet: bullet,
      language: detectedLang,
      hasPlaceholder: /\[.+\]/.test(bullet),
      engine: 'gemini',
    };
  } catch (err) {
    console.warn(`[AI Win Bullet Warning] Gemini failed (${err.message}). Using deterministic STAR bullet.`);
    return generateFallbackStarBullet({
      title,
      impactMetric,
      category,
      language: detectedLang,
    });
  }
}

/**
 * Merge selected work wins into an ImprovedCV structure ("Living CV").
 * Inserts new STAR bullets at the top of the Experience/Projects section.
 */
function mergeWinsIntoCvObject(baseCv, winsToMerge = []) {
  const isId = (baseCv && baseCv.language === 'id') ||
    (winsToMerge[0] && winsToMerge[0].language === 'id');
  const lang = isId ? 'id' : 'en';

  const cv = {
    language: lang,
    name: (baseCv && baseCv.name) || 'Ijul',
    title: (baseCv && baseCv.title) || (isId ? 'Profesional & Lulusan Baru' : 'Fresh Graduate Professional'),
    contact: Array.isArray(baseCv?.contact) && baseCv.contact.length > 0
      ? [...baseCv.contact]
      : [
          'ijul@leveledup.id',
          '+62 812 XXXX XXXX',
          isId ? 'Indonesia' : 'Indonesia (Open to Remote)',
          'linkedin.com/in/ijul',
        ],
    summary: (baseCv && baseCv.summary) || (isId
      ? 'Profesional berorientasi hasil dengan rekam jejak pencapaian terukur dalam eksekusi proyek, kolaborasi tim, dan peningkatan proses kerja sebesar [X]%.'
      : 'Results-driven professional with a documented track record of delivering measurable project outcomes, workflow improvements, and [X]% efficiency gains.'),
    sections: Array.isArray(baseCv?.sections)
      ? baseCv.sections.map((s) => ({
          heading: s.heading,
          bullets: Array.isArray(s.bullets) ? [...s.bullets] : [],
        }))
      : [],
    changes: Array.isArray(baseCv?.changes) ? [...baseCv.changes] : [],
  };

  if (cv.sections.length === 0) {
    cv.sections = [
      {
        heading: isId ? 'Pengalaman Profesional & Proyek' : 'Professional Experience & Projects',
        bullets: [],
      },
      {
        heading: isId ? 'Pendidikan' : 'Education',
        bullets: [
          isId
            ? '[Gelar / Jurusan] — [Nama Universitas] ([Tahun Lulus])'
            : '[Degree / Major] — [University Name] ([Graduation Year])',
        ],
      },
      {
        heading: isId ? 'Keahlian & Kompetensi' : 'Skills & Competencies',
        bullets: [
          isId
            ? 'Kompetensi Utama: Manajemen Proyek, Analisis Data, Komunikasi Profesional, Problem Solving'
            : 'Core Competencies: Project Execution, Data Analysis, Cross-Functional Collaboration, Problem Solving',
        ],
      },
    ];
  }

  // Find the Experience / Projects section (or first section)
  const expIdx = cv.sections.findIndex((s) =>
    /pengalaman|experience|proyek|project|work|kerja/i.test(s.heading || '')
  );
  const targetIdx = expIdx !== -1 ? expIdx : 0;

  const existingBullets = cv.sections[targetIdx].bullets;
  const newBullets = [];

  for (const win of winsToMerge) {
    const bullet = (win.starBullet || win.star_bullet || win.title || '').trim();
    if (bullet && !existingBullets.includes(bullet) && !newBullets.includes(bullet)) {
      newBullets.push(bullet);
    }
  }

  cv.sections[targetIdx].bullets = [...newBullets, ...existingBullets];

  if (newBullets.length > 0) {
    const changeNote = isId
      ? `Mengintegrasikan ${newBullets.length} pencapaian baru dari Brag Doc (Log Win) ke dalam bagian ${cv.sections[targetIdx].heading}.`
      : `Merged ${newBullets.length} verified Brag Doc win(s) directly into the ${cv.sections[targetIdx].heading} section.`;
    if (!cv.changes.includes(changeNote)) {
      cv.changes.unshift(changeNote);
    }
  }

  return {
    cv,
    mergedCount: newBullets.length,
  };
}

module.exports = {
  generateStarBullet,
  generateFallbackStarBullet,
  mergeWinsIntoCvObject,
};


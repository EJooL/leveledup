const { ai, isAiAvailable } = require('../config/ai');
const { validateWinInput, normalizeLanguage } = require('./bilingualValidation');
const {
  generateJsonWithGemini,
  hasQuantifiedMetric,
  hasBracketPlaceholder,
  sanitizeWinBulletResult,
  isBiasLine,
  inferCvSectionType,
} = require('./aiGuardrails');

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
1. NEVER invent or fabricate any numbers, percentages, currency amounts, dates, or company names that the user did not provide.
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
function generateFallbackStarBullet(input = {}) {
  const { title, impactMetric, category, language } = validateWinInput(input);
  const cleanTitle = title.replace(/^[•\-*]\s*/, '').replace(/\.$/, '');
  const cleanImpact = impactMetric.replace(/\.$/, '');
  const isId = language === 'id';

  const verbs =
    (CATEGORY_VERBS[language] && CATEGORY_VERBS[language][category]) ||
    CATEGORY_VERBS[language].project_delivery;
  const actionVerb = verbs[0];

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

  const hasMetricInInput = hasQuantifiedMetric(`${coreAction} ${cleanImpact}`);

  let starBullet = '';
  if (cleanImpact.length > 0) {
    if (hasMetricInInput || hasBracketPlaceholder(cleanImpact)) {
      starBullet = isId
        ? `${coreAction}, menghasilkan dampak terukur berupa ${cleanImpact}.`
        : `${coreAction}, delivering measurable impact of ${cleanImpact}.`;
    } else {
      starBullet = isId
        ? `${coreAction}, meningkatkan ${cleanImpact} sebesar [X]%.`
        : `${coreAction}, improving ${cleanImpact} by [X]%.`;
    }
  } else if (hasMetricInInput || hasBracketPlaceholder(coreAction)) {
    starBullet = `${coreAction}.`;
  } else {
    starBullet = isId
      ? `${coreAction}, meningkatkan efektivitas dan capaian target sebesar [X]% pada [metrik/jumlah].`
      : `${coreAction}, improving overall outcome efficiency by [X]% across [target metric].`;
  }

  return sanitizeWinBulletResult(starBullet, {
    title: cleanTitle,
    impactMetric: cleanImpact,
    lang: language,
    engine: 'rule-based',
  });
}

/**
 * Convert a user's logged achievement into an ATS-ready STAR bullet via Gemini or fallback.
 * @param {{ title: string, impactMetric?: string, category?: string, language?: string, _aiClient?: object, models?: string[], timeoutMs?: number }} input
 */
async function generateStarBullet(input = {}) {
  const { title, impactMetric, category, language } = validateWinInput(input);
  const aiClient = input._aiClient || (isAiAvailable() ? ai : null);

  if (!aiClient) {
    return generateFallbackStarBullet({ title, impactMetric, category, language });
  }

  try {
    const prompt = `Convert this logged work/academic achievement into a single ATS STAR bullet:
Achievement: ${title}
Impact / Metric provided by user: ${impactMetric || '(None provided — use bracketed [placeholder] for missing metrics)'}
Category: ${category}
Language: ${language === 'id' ? 'Bahasa Indonesia' : 'English'}`;

    const { parsed } = await generateJsonWithGemini({
      aiClient,
      contents: prompt,
      systemInstruction: buildWinSystemPrompt(language),
      models: input.models,
      timeoutMs: input.timeoutMs,
    });

    if (!parsed || typeof parsed.starBullet !== 'string' || !parsed.starBullet.trim()) {
      throw new Error('Invalid JSON structure from Gemini win bullet generator');
    }

    return sanitizeWinBulletResult(parsed.starBullet, {
      title,
      impactMetric,
      lang: language,
      engine: 'gemini',
    });
  } catch (err) {
    console.warn(`[AI Win Bullet Warning] Gemini failed (${err.message}). Using deterministic STAR bullet.`);
    return generateFallbackStarBullet({ title, impactMetric, category, language });
  }
}

/**
 * Merge selected work wins into an ImprovedCV structure ("Living CV").
 * Inserts new STAR bullets at the top of the Experience/Projects section.
 */
function mergeWinsIntoCvObject(baseCv, winsToMerge = []) {
  const rawLang = (baseCv && baseCv.language) || (winsToMerge[0] && winsToMerge[0].language) || 'en';
  const lang = normalizeLanguage(rawLang);
  const isId = lang === 'id';

  const sanitizedContact =
    Array.isArray(baseCv?.contact) && baseCv.contact.length > 0
      ? baseCv.contact
          .filter((c) => typeof c === 'string' && c.trim() && !isBiasLine(c))
          .map((c) => c.trim())
      : [];

  const cv = {
    language: lang,
    name:
      (baseCv && typeof baseCv.name === 'string' && baseCv.name.trim()) ||
      (isId ? '[Nama Lengkap]' : '[Full Name]'),
    title:
      (baseCv && typeof baseCv.title === 'string' && baseCv.title.trim()) ||
      (isId ? 'Profesional & Lulusan Baru' : 'Fresh Graduate Professional'),
    contact:
      sanitizedContact.length > 0
        ? sanitizedContact
        : [
            '[email@domain.com]',
            '[+62 8XX XXXX XXXX]',
            isId ? 'Indonesia' : 'Indonesia (Open to Remote)',
            isId ? 'linkedin.com/in/[profil-anda]' : 'linkedin.com/in/[your-profile]',
          ],
    summary:
      (baseCv && typeof baseCv.summary === 'string' && baseCv.summary.trim()) ||
      (isId
        ? 'Profesional berorientasi hasil dengan rekam jejak pencapaian terukur dalam eksekusi proyek, kolaborasi tim, dan peningkatan proses kerja sebesar [X]%.'
        : 'Results-driven professional with a documented track record of delivering measurable project outcomes, workflow improvements, and [X]% efficiency gains.'),
    sections: Array.isArray(baseCv?.sections)
      ? baseCv.sections
          .filter((s) => s && typeof s === 'object')
          .map((s) => {
            const heading =
              typeof s.heading === 'string' && s.heading.trim()
                ? s.heading.trim()
                : (isId ? 'Pengalaman' : 'Experience');
            const type = inferCvSectionType(s.type, heading);
            const mapped = {
              heading,
              type,
              bullets: Array.isArray(s.bullets)
                ? s.bullets
                    .filter((b) => typeof b === 'string' && b.trim() && !isBiasLine(b))
                    .map((b) => b.trim())
                : [],
            };
            if (Array.isArray(s.entries) && s.entries.length > 0) {
              mapped.entries = s.entries
                .filter((e) => e && typeof e === 'object')
                .map((e) => ({
                  title: typeof e.title === 'string' ? e.title.trim() : '',
                  date: typeof e.date === 'string' ? e.date.trim() : '',
                  subtitle: typeof e.subtitle === 'string' ? e.subtitle.trim() : '',
                  bullets: Array.isArray(e.bullets)
                    ? e.bullets
                        .filter((b) => typeof b === 'string' && b.trim() && !isBiasLine(b))
                        .map((b) => b.trim())
                    : [],
                }));
            }
            if (Array.isArray(s.skillGroups) && s.skillGroups.length > 0) {
              mapped.skillGroups = s.skillGroups
                .filter((g) => g && typeof g === 'object')
                .map((g) => ({
                  category: typeof g.category === 'string' ? g.category.trim() : '',
                  items: typeof g.items === 'string' ? g.items.trim() : '',
                }))
                .filter((g) => g.items);
            }
            return mapped;
          })
      : [],
    changes: Array.isArray(baseCv?.changes)
      ? baseCv.changes.filter((c) => typeof c === 'string' && c.trim()).map((c) => c.trim())
      : [],
  };

  if (cv.sections.length === 0) {
    cv.sections = [
      {
        heading: isId ? 'Pendidikan' : 'Education',
        type: 'education',
        entries: [
          {
            title: isId ? '[Nama Universitas]' : '[University Name]',
            date: isId ? '[Tahun Masuk] – [Tahun Lulus]' : '[Start Year] – [End Year]',
            subtitle: '',
            bullets: [
              isId ? '[Gelar / Jurusan] | IPK [X.XX] / 4.00' : '[Degree / Major] | GPA [X.XX] / 4.00',
            ],
          },
        ],
        bullets: [
          isId
            ? '[Gelar / Jurusan] — [Nama Universitas] ([Tahun Lulus])'
            : '[Degree / Major] — [University Name] ([Graduation Year])',
        ],
      },
      {
        heading: isId ? 'Pengalaman' : 'Experience',
        type: 'experience',
        entries: [
          {
            title: isId ? 'Pencapaian & Pengalaman Terbaru' : 'Recent Experience & Achievements',
            date: isId ? 'Sekarang' : 'Present',
            subtitle: '',
            bullets: [],
          },
        ],
        bullets: [],
      },
      {
        heading: isId ? 'Keahlian' : 'Skills',
        type: 'skills',
        skillGroups: [
          {
            category: isId ? 'Kompetensi Utama' : 'Core Competencies',
            items: isId
              ? 'Manajemen Proyek, Analisis Data, Komunikasi Profesional, Problem Solving'
              : 'Project Execution, Data Analysis, Cross-Functional Collaboration, Problem Solving',
          },
        ],
        bullets: [
          isId
            ? 'Kompetensi Utama: Manajemen Proyek, Analisis Data, Komunikasi Profesional, Problem Solving'
            : 'Core Competencies: Project Execution, Data Analysis, Cross-Functional Collaboration, Problem Solving',
        ],
      },
    ];
  }

  // Find the Experience / Projects section (or first section)
  const expIdx = cv.sections.findIndex(
    (s) =>
      s.type === 'experience' ||
      /pengalaman|experience|work|kerja/i.test(s.heading || '')
  );
  const projIdx = cv.sections.findIndex(
    (s) => s.type === 'projects' || /proyek|project/i.test(s.heading || '')
  );
  const targetIdx = expIdx !== -1 ? expIdx : (projIdx !== -1 ? projIdx : 0);

  const existingBullets = cv.sections[targetIdx].bullets;
  const newBullets = [];

  for (const win of Array.isArray(winsToMerge) ? winsToMerge : []) {
    const bullet = String(win?.starBullet || win?.star_bullet || win?.title || '').trim();
    if (bullet && !existingBullets.includes(bullet) && !newBullets.includes(bullet)) {
      newBullets.push(bullet);
    }
  }

  cv.sections[targetIdx].bullets = [...newBullets, ...existingBullets];

  // Keep structured entries synchronized when present
  if (Array.isArray(cv.sections[targetIdx].entries) && newBullets.length > 0) {
    if (cv.sections[targetIdx].entries.length === 0) {
      cv.sections[targetIdx].entries.push({
        title: isId ? 'Pencapaian Terbaru' : 'Recent Achievements',
        date: isId ? 'Sekarang' : 'Present',
        subtitle: '',
        bullets: [...newBullets],
      });
    } else {
      const firstEntry = cv.sections[targetIdx].entries[0];
      const existingEntryBullets = Array.isArray(firstEntry.bullets) ? firstEntry.bullets : [];
      const uniqueEntryAdditions = newBullets.filter((b) => !existingEntryBullets.includes(b));
      firstEntry.bullets = [...uniqueEntryAdditions, ...existingEntryBullets];
    }
  }

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
  buildWinSystemPrompt,
};

/**
 * Shared AI Guardrails, Schema Sanitizers, Resilient Gemini Execution,
 * and Zero-Hallucination Parity Utilities for LeveledUp Backend Services.
 */

const { normalizeLanguage } = require('./bilingualValidation');

const VALID_ISSUE_CATEGORIES = new Set([
  'personal_info',
  'ats_readability',
  'keyword_match',
  'achievements',
  'language_quality',
]);

const VALID_ISSUE_SEVERITIES = new Set(['critical', 'warning', 'suggestion']);

// Single source of truth for explicit photo text evidence in a CV
const EXPLICIT_PHOTO_TEXT_REGEX =
  /\b(pas\s*foto|pasfoto|foto\s*diri|foto\s*4x6|foto\s*3x4|photo\s*:\s*headshot|headshot\s*attached|foto\s*terlampir)\b/i;

// Thorough bilingual matcher for photo/headshot hallucination detection
const PHOTO_ISSUE_REGEX =
  /\b(pas\s*foto|pasfoto|foto(\s*diri|\s*profil|\s*4x6|\s*3x4)?|photo(graph)?|headshot|portrait|profile\s*pic(ture)?|avatar|potret(\s*diri)?|gambar\s*profil)\b/i;

// Genuine personal bias indicators (used to prevent non-bias issues like clichés from polluting personal_info)
const PERSONAL_BIAS_REGEX =
  /\b(pas\s*foto|pasfoto|foto|photo|headshot|portrait|tanggal\s*lahir|tempat\s*lahir|ttl|date\s*of\s*birth|dob|usia|umur|age|status\s*pernikahan|status\s*perkawinan|marital\s*status|single|married|lajang|menikah|agama|religion|nik|ktp|national\s*id|jenis\s*kelamin|gender|tinggi\s*badan|berat\s*badan|golongan\s*darah|blood\s*type|bias\s*pribadi|personal\s*bias|demographic|pii)\b/i;

// Personal bias line filter for CV rewrites (contact lines & section bullets)
const BIAS_LINE_REGEX =
  /^(pas\s*foto|foto\s*:|photo\s*:|tempat\s*[/,&]?\s*tanggal\s*lahir|tanggal\s*lahir|ttl\s*:|date\s*of\s*birth|dob\s*:|agama\s*:|religion\s*:|status\s*pernikahan|status\s*perkawinan|marital\s*status|status\s*:\s*(lajang|menikah|single|married|belum\s+menikah)|nik\s*:|no\.?\s*ktp|jenis\s*kelamin|gender\s*:|tinggi\s*badan|berat\s*badan|golongan\s*darah|blood\s*type)/i;

const BRACKET_PLACEHOLDER_REGEX = /\[[^\[\]\n]{1,60}\]/;

const QUANTIFIED_UNITS_PATTERN =
  '(?:users|pengguna|clients|klien|customers|pelanggan|projects|proyek|members|anggota|orang|people|teams?|tim|leads|transaksi|transactions|orders|pesanan|endpoints|requests|hours|jam|days|hari|weeks|minggu|months|bulan|records|entri|dokumen|documents|reports|laporan|campaigns|kampanye|tickets|tiket|bugs|aplikasi|apps|sistem|systems|fitur|features|unit|skenario|scenarios)';

const QUANTIFIED_METRIC_PATTERNS = [
  /\b\d+(?:[.,]\d+)?%/,
  /(?<![\d×x])\b\d+(?:[.,]\d+)?x\b(?!\s*\d)/i,
  /(?:Rp\.?\s*\d[\d.,]*|\$\s*\d[\d.,]*|\b\d[\d.,]*\s*(?:juta|miliar|ribu|idr|usd)\b)/i,
  new RegExp(`\\b\\d[\\d.,]*\\+?\\s*${QUANTIFIED_UNITS_PATTERN}\\b`, 'i'),
];

const DEFAULT_FALLBACK_MODELS = [
  'gemini-3-flash-preview',
  'gemini-3.5-flash-lite',
  'gemini-3.5-flash',
];

function getGeminiModelChain(overrideModels) {
  if (Array.isArray(overrideModels) && overrideModels.length > 0) {
    return [...new Set(overrideModels.filter(Boolean))];
  }
  const envModel = process.env.GEMINI_MODEL && process.env.GEMINI_MODEL.trim();
  const chain = envModel ? [envModel, ...DEFAULT_FALLBACK_MODELS] : [...DEFAULT_FALLBACK_MODELS];
  return [...new Set(chain)];
}

/**
 * Strip optional markdown code fences and parse JSON safely.
 * @param {string} rawText
 * @returns {any}
 */
function parseGeminiJson(rawText) {
  if (typeof rawText !== 'string' || !rawText.trim()) {
    throw new Error('Empty response from Gemini model');
  }
  let cleaned = rawText.trim();
  // Strip ```json ... ``` or ``` ... ``` wrappers if present
  const fenceMatch = cleaned.match(/^```(?:json)?\s*([\s\S]*?)\s*```$/i);
  if (fenceMatch) {
    cleaned = fenceMatch[1].trim();
  }
  return JSON.parse(cleaned);
}

function isFatalConnectivityOrAuthError(err) {
  const msg = String(err?.message || '').toLowerCase();
  const status = Number(err?.status || err?.code || 0);
  if (status === 401 || status === 403) return true;
  if (
    msg.includes('fetch failed') ||
    msg.includes('enotfound') ||
    msg.includes('econnrefused') ||
    msg.includes('econnreset') ||
    msg.includes('api key not valid')
  ) {
    return true;
  }
  return false;
}

async function withTimeout(promise, timeoutMs) {
  let timer = null;
  try {
    return await Promise.race([
      promise,
      new Promise((_, reject) => {
        timer = setTimeout(() => {
          const timeoutErr = new Error(`Gemini request timed out after ${timeoutMs}ms`);
          timeoutErr.code = 'GEMINI_TIMEOUT';
          reject(timeoutErr);
        }, timeoutMs);
      }),
    ]);
  } finally {
    if (timer) clearTimeout(timer);
  }
}

/**
 * Call Gemini with resilient Flash model fallback chain + timeout guard.
 * @param {{ aiClient: any, contents: string, systemInstruction: string, models?: string[], timeoutMs?: number }} params
 * @returns {Promise<{ parsed: any, modelUsed: string }>}
 */
async function generateJsonWithGemini({
  aiClient,
  contents,
  systemInstruction,
  models,
  timeoutMs = Number(process.env.GEMINI_TIMEOUT_MS) || 20000,
}) {
  if (!aiClient || !aiClient.models || typeof aiClient.models.generateContent !== 'function') {
    throw new Error('AI client is not initialized');
  }

  const candidates = getGeminiModelChain(models);
  let lastError = null;

  for (const model of candidates) {
    try {
      const response = await withTimeout(
        aiClient.models.generateContent({
          model,
          contents,
          config: {
            systemInstruction,
            responseMimeType: 'application/json',
          },
        }),
        timeoutMs
      );

      const outputText =
        response?.text ||
        (response?.candidates && response.candidates[0]?.content?.parts?.[0]?.text);

      const parsed = parseGeminiJson(outputText);
      return { parsed, modelUsed: model };
    } catch (err) {
      lastError = err;
      if (isFatalConnectivityOrAuthError(err)) {
        break;
      }
      // On 404 (deprecated model), 503 (high demand), 429, timeout, or bad JSON -> try next candidate
    }
  }

  throw lastError || new Error('All Gemini model candidates failed');
}

/**
 * Check whether photo evidence exists (embedded PDF photo OR explicit text mention).
 */
function hasExplicitPhotoEvidence(text, options = {}) {
  return Boolean(options && options.hasPhoto) || EXPLICIT_PHOTO_TEXT_REGEX.test(text || '');
}

/**
 * Detect whether an ATS issue is reporting a CV photo/headshot problem.
 */
function isPhotoHallucinationIssue(issue) {
  if (!issue || typeof issue !== 'object') return false;
  const idStr = String(issue.id || '').toLowerCase();
  const titleStr = String(issue.title || '');
  const category = String(issue.category || '').toLowerCase();

  if (
    idStr.includes('photo') ||
    idStr.includes('foto') ||
    idStr.includes('headshot') ||
    idStr.includes('avatar') ||
    PHOTO_ISSUE_REGEX.test(titleStr)
  ) {
    return true;
  }

  if (category === 'personal_info') {
    const combinedPersonalText = [
      issue.detail || '',
      issue.fix || '',
      issue.rewrite?.before || '',
      issue.rewrite?.after || '',
    ].join(' ');
    if (PHOTO_ISSUE_REGEX.test(combinedPersonalText)) {
      return true;
    }
  }

  return false;
}

/**
 * Strictly strip any photo/headshot issues whenever hasPhoto is false.
 */
function stripHallucinatedPhotoIssues(issues, hasPhoto) {
  if (!Array.isArray(issues)) return [];
  if (hasPhoto) return issues;
  return issues.filter((issue) => !isPhotoHallucinationIssue(issue));
}

/**
 * Extract normalized numeric tokens from source text so legitimate candidate numbers
 * are preserved while fabricated AI metrics are replaced with bracketed placeholders.
 * @param {string} sourceText
 * @returns {Set<string>}
 */
function extractSourceNumbers(sourceText) {
  const numbers = new Set();
  const str = typeof sourceText === 'string' ? sourceText : '';
  const matches = str.match(/\d+(?:[.,]\d+)*/g) || [];
  for (const raw of matches) {
    numbers.add(raw);
    const digitsOnly = raw.replace(/[.,]/g, '');
    if (digitsOnly) numbers.add(digitsOnly);
    const dotNorm = raw.replace(/,/g, '.');
    numbers.add(dotNorm);
  }
  return numbers;
}

function isNumberInSource(rawNum, sourceNumbers) {
  if (!rawNum) return false;
  if (sourceNumbers.has(rawNum)) return true;
  const digitsOnly = rawNum.replace(/[.,]/g, '');
  if (sourceNumbers.has(digitsOnly)) return true;
  const dotNorm = rawNum.replace(/,/g, '.');
  if (sourceNumbers.has(dotNorm)) return true;
  return false;
}

/**
 * Returns true if text contains a real quantified impact metric (percentage, multiplier,
 * currency figure, or count+unit), ignoring phone numbers, years, ages, or 4x6 photo sizes.
 */
function hasQuantifiedMetric(text) {
  if (typeof text !== 'string' || !text.trim()) return false;
  return QUANTIFIED_METRIC_PATTERNS.some((rx) => rx.test(text));
}

/**
 * Returns true if text contains at least one explicit bracketed placeholder like [X]%, [jumlah], [target metric].
 */
function hasBracketPlaceholder(text) {
  if (typeof text !== 'string') return false;
  return BRACKET_PLACEHOLDER_REGEX.test(text);
}

/**
 * Replace fabricated numeric metrics (percentages, multipliers, currency, quantified counts)
 * that do NOT appear in sourceText with explicit bilingual bracketed placeholders.
 * Never alters numbers that actually exist in sourceText.
 * @param {string} candidateText
 * @param {string} sourceText
 * @param {'id' | 'en'} lang
 * @returns {string}
 */
function sanitizeFabricatedMetrics(candidateText, sourceText, lang = 'en') {
  if (typeof candidateText !== 'string' || !candidateText.trim()) return '';
  const isId = normalizeLanguage(lang) === 'id';
  const sourceNums = extractSourceNumbers(sourceText);

  let out = candidateText;

  // 1. Fabricated percentages: e.g. "45%", "12.5%"
  out = out.replace(/\b(\d+(?:[.,]\d+)?)%/g, (full, num) => {
    return isNumberInSource(num, sourceNums) ? full : '[X]%';
  });

  // 2. Fabricated multipliers: e.g. "3x", "2.5x" (exclude dimensions like 4x6)
  out = out.replace(/(?<![\d×x])\b(\d+(?:[.,]\d+)?)x\b(?!\s*\d)/gi, (full, num) => {
    return isNumberInSource(num, sourceNums) ? full : '[X]x';
  });

  // 3. Fabricated currency figures: e.g. "Rp 50 juta", "$25,000", "USD 1000"
  out = out.replace(
    /\b(Rp\.?\s*|IDR\s*|USD\s*|\$\s*)(\d[\d.,]*)(\s*(?:juta|miliar|ribu|k|m|million|billion))?/gi,
    (full, prefix, num) => {
      if (isNumberInSource(num, sourceNums)) return full;
      return isId ? '[nominal]' : '[amount]';
    }
  );

  // 4. Fabricated quantified counts: e.g. "500+ users", "12 tim", "20 laporan"
  const countUnitRx = new RegExp(
    `\\b(\\d[\\d.,]*)(\\+?)(\\s+${QUANTIFIED_UNITS_PATTERN})\\b`,
    'gi'
  );
  out = out.replace(countUnitRx, (full, num, _plus, unitPart) => {
    if (isNumberInSource(num, sourceNums)) return full;
    return `${isId ? '[jumlah]' : '[number]'}${unitPart}`;
  });

  return out;
}

/**
 * Detect whether a bullet is actually a company/role/date header line rather than an action bullet.
 */
function isHeaderLikeBullet(line) {
  if (typeof line !== 'string') return false;
  const trimmed = line.trim();
  if (trimmed.length <= 22) return true;
  if (/\|\s*.*(?:19|20)\d{2}/i.test(trimmed)) return true;
  if (/^(pt|cv|inc|corp|ltd|yayasan)\b/i.test(trimmed) && /(?:19|20)\d{2}|sekarang|present/i.test(trimmed)) {
    return true;
  }
  if (/^[^.]{3,55}\((?:jan|feb|mar|apr|mei|may|jun|jul|agu|aug|sep|okt|oct|nov|des|dec)?\s*(?:19|20)\d{2}\s*[-–—]\s*(?:(?:jan|feb|mar|apr|mei|may|jun|jul|agu|aug|sep|okt|oct|nov|des|dec)?\s*(?:19|20)\d{2}|sekarang|present)\)$/i.test(trimmed)) {
    return true;
  }
  return false;
}

/**
 * Enforce Zero-Hallucination on a single experience/STAR bullet:
 * 1) Replace any fabricated metric not present in sourceText with [placeholder].
 * 2) If neither a verified metric nor a [placeholder] exists, append a clean bilingual placeholder.
 */
function ensureMetricOrPlaceholder(bullet, sourceText, lang = 'en', options = {}) {
  const isId = normalizeLanguage(lang) === 'id';
  let out = sanitizeFabricatedMetrics(String(bullet || '').trim(), sourceText, lang);
  if (!out) return '';

  if (options.skipAppendIfHeader && isHeaderLikeBullet(out)) {
    return out;
  }

  const hasVerifiedMetric = hasQuantifiedMetric(out);
  const hasPlaceholder = hasBracketPlaceholder(out);

  if (!hasVerifiedMetric && !hasPlaceholder) {
    out =
      out.replace(/[.。]+$/, '') +
      (isId
        ? ', meningkatkan efektivitas sebesar [X]% pada [metrik target].'
        : ', improving overall efficiency by [X]% across [target metric].');
  }

  return out;
}

/**
 * Check if a line contains personal bias fields that must be stripped from rewritten CVs.
 */
function isBiasLine(line) {
  if (typeof line !== 'string') return false;
  return BIAS_LINE_REGEX.test(line.trim());
}

/**
 * Normalize issue category and prevent non-bias issues (e.g. generic clichés) from
 * being misclassified under 'personal_info'.
 */
function normalizeIssueCategory(rawCategory, issue) {
  const cat = String(rawCategory || '').trim().toLowerCase();
  const combined = `${issue.id || ''} ${issue.title || ''} ${issue.detail || ''} ${issue.fix || ''}`;

  if (cat === 'personal_info') {
    if (!PERSONAL_BIAS_REGEX.test(combined)) {
      if (/\b(klise|cliche|cliché|buzzword|generik|generic|ringkasan|summary|pekerja\s+keras|hard.?working|tekanan|pressure)\b/i.test(combined)) {
        return 'language_quality';
      }
      return 'ats_readability';
    }
    return 'personal_info';
  }

  if (VALID_ISSUE_CATEGORIES.has(cat)) return cat;

  if (PERSONAL_BIAS_REGEX.test(combined)) return 'personal_info';
  if (/\b(keyword|kata\s*kunci|skill|keahlian)\b/i.test(combined)) return 'keyword_match';
  if (/\b(metric|metrik|star|achievement|pencapaian|tanggung\s*jawab|responsible)\b/i.test(combined)) return 'achievements';
  if (/\b(klise|cliche|grammar|bahasa|passive|pasif|buzzword)\b/i.test(combined)) return 'language_quality';
  return 'ats_readability';
}

function normalizeIssueSeverity(rawSeverity) {
  const sev = String(rawSeverity || '').trim().toLowerCase();
  return VALID_ISSUE_SEVERITIES.has(sev) ? sev : 'warning';
}

function normalizeStringArray(arr) {
  if (!Array.isArray(arr)) return [];
  const seen = new Set();
  const out = [];
  for (const item of arr) {
    if (typeof item !== 'string') continue;
    const trimmed = item.trim();
    const key = trimmed.toLowerCase();
    if (trimmed && !seen.has(key)) {
      seen.add(key);
      out.push(trimmed);
    }
  }
  return out;
}

/**
 * Sanitize and enforce full JSON schema compliance & Zero-Hallucination parity
 * on ATS analysis output (both live Gemini and rule-based fallback).
 */
function sanitizeAnalysisResult(
  raw,
  { text = '', fileName = 'CV.pdf', lang = 'en', hasPhoto = false, engine = 'gemini', inferJobRole, analyzeKeywords }
) {
  const normalizedLang = normalizeLanguage(lang, text);
  const isId = normalizedLang === 'id';
  const source = raw && typeof raw === 'object' ? raw : {};

  // 1. Sanitize each issue item
  const rawIssues = Array.isArray(source.issues) ? source.issues : [];
  const usedIds = new Set();
  const cleanedIssues = [];

  for (let i = 0; i < rawIssues.length; i++) {
    const item = rawIssues[i];
    if (!item || typeof item !== 'object') continue;

    let id = String(item.id || `issue_${i + 1}`)
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9_]+/g, '_')
      .replace(/^_+|_+$/g, '');
    if (!id) id = `issue_${i + 1}`;
    if (usedIds.has(id)) id = `${id}_${i + 1}`;
    usedIds.add(id);

    const title = typeof item.title === 'string' && item.title.trim()
      ? item.title.trim()
      : (isId ? 'Perbaikan Struktur ATS' : 'ATS Optimization Issue');
    const detail = typeof item.detail === 'string' && item.detail.trim()
      ? item.detail.trim()
      : title;
    const fix = typeof item.fix === 'string' && item.fix.trim()
      ? item.fix.trim()
      : (isId ? 'Perbarui bagian ini sesuai standar ATS.' : 'Update this section to meet ATS best practices.');

    const rawBefore = typeof item.rewrite?.before === 'string' ? item.rewrite.before.trim() : '';
    const rawAfter = typeof item.rewrite?.after === 'string' ? item.rewrite.after.trim() : '';
    const sanitizedAfter = rawAfter
      ? sanitizeFabricatedMetrics(rawAfter, `${text}\n${rawBefore}`, normalizedLang)
      : (isId ? 'Sesuaikan dengan pencapaian terukur menggunakan [X]% atau [jumlah].' : 'Rewrite with quantified outcomes using [X]% or [number].');

    const normalizedIssue = {
      id,
      category: normalizeIssueCategory(item.category, { id, title, detail, fix }),
      severity: normalizeIssueSeverity(item.severity),
      title,
      detail,
      fix,
      rewrite: {
        before: rawBefore || (isId ? '[Kutipan dari CV Anda]' : '[Excerpt from your CV]'),
        after: sanitizedAfter,
      },
    };

    cleanedIssues.push(normalizedIssue);
  }

  // 2. Hard programmatic guard: strictly strip photo/headshot issues when hasPhoto is false
  const verifiedIssues = stripHallucinatedPhotoIssues(cleanedIssues, hasPhoto);

  // 3. Recalculate overallScore deterministically from verified issues
  let score = 100;
  for (const issue of verifiedIssues) {
    if (issue.severity === 'critical') score -= 11;
    else if (issue.severity === 'warning') score -= 7;
    else if (issue.severity === 'suggestion') score -= 3;
  }
  const overallScore = Math.max(10, Math.min(100, score));

  // 4. Sanitize keywordMatch
  const inferredRole = typeof inferJobRole === 'function' ? inferJobRole(text) : 'Professional';
  const fallbackKw =
    typeof analyzeKeywords === 'function'
      ? analyzeKeywords(text, inferredRole)
      : { jobTitle: inferredRole, matched: [], missing: [], missingCount: 0 };

  const rawKw = source.keywordMatch && typeof source.keywordMatch === 'object' ? source.keywordMatch : {};
  const jobTitle =
    typeof rawKw.jobTitle === 'string' && rawKw.jobTitle.trim()
      ? rawKw.jobTitle.trim()
      : fallbackKw.jobTitle;

  const matched = normalizeStringArray(rawKw.matched);
  const matchedSet = new Set(matched.map((k) => k.toLowerCase()));
  const missing = normalizeStringArray(rawKw.missing).filter(
    (k) => !matchedSet.has(k.toLowerCase())
  );

  const finalMatched = matched.length > 0 || missing.length > 0 ? matched : fallbackKw.matched;
  const finalMissing = matched.length > 0 || missing.length > 0 ? missing : fallbackKw.missing;

  const summary =
    typeof source.summary === 'string' && source.summary.trim()
      ? source.summary.trim()
      : (isId
          ? 'Hasil analisis ATS untuk CV Anda.'
          : 'ATS diagnostic summary for your CV.');

  const analyzedAtLabel =
    source.meta && typeof source.meta.analyzedAtLabel === 'string' && source.meta.analyzedAtLabel.trim()
      ? source.meta.analyzedAtLabel.trim()
      : engine === 'gemini'
        ? (isId ? 'Dianalisis AI Gemini (Bahasa Indonesia)' : 'Analyzed by Gemini AI (English)')
        : (isId ? 'Evaluasi Bahasa Indonesia' : 'English ATS Evaluation');

  return {
    mode: 'global',
    language: normalizedLang,
    overallScore,
    summary,
    issues: verifiedIssues,
    keywordMatch: {
      jobTitle,
      matched: finalMatched,
      missing: finalMissing,
      missingCount: finalMissing.length,
    },
    meta: {
      fileName: typeof fileName === 'string' && fileName.trim() ? fileName.trim() : 'CV.pdf',
      language: normalizedLang,
      analyzedAtLabel,
      engine,
    },
  };
}

/**
 * Sanitize and enforce schema compliance, bias stripping, and Zero-Hallucination
 * placeholder parity on CV Rewrite output (both live Gemini and fallback).
 */
function sanitizeRewriteResult(raw, { sourceText = '', lang = 'en', engine = 'gemini' }) {
  const normalizedLang = normalizeLanguage(lang, sourceText);
  const isId = normalizedLang === 'id';
  const rawCv = raw && typeof raw === 'object' ? raw.cv : null;

  if (!rawCv || typeof rawCv !== 'object' || !Array.isArray(rawCv.sections) || rawCv.sections.length === 0) {
    throw new Error('Invalid CV rewrite schema: missing cv.sections');
  }

  const name =
    typeof rawCv.name === 'string' && rawCv.name.trim()
      ? rawCv.name.trim()
      : (isId ? 'Kandidat Profesional' : 'Professional Candidate');

  const title =
    typeof rawCv.title === 'string' && rawCv.title.trim()
      ? rawCv.title.trim()
      : (isId ? 'Profesional' : 'Professional');

  const contact = normalizeStringArray(rawCv.contact).filter((line) => !isBiasLine(line));

  const rawSummary =
    typeof rawCv.summary === 'string' && rawCv.summary.trim()
      ? rawCv.summary.trim()
      : (isId
          ? `Profesional di bidang ${title} yang berorientasi pada hasil terukur sebesar [X]%.`
          : `Results-driven ${title} focused on delivering measurable improvements of [X]%.`);
  const summary = sanitizeFabricatedMetrics(rawSummary, sourceText, normalizedLang);

  const sourceHasMetrics = hasQuantifiedMetric(sourceText);

  const sections = rawCv.sections
    .filter((s) => s && typeof s === 'object')
    .map((sec, idx) => {
      const heading =
        typeof sec.heading === 'string' && sec.heading.trim()
          ? sec.heading.trim()
          : (idx === 0
              ? (isId ? 'Pengalaman Profesional' : 'Professional Experience')
              : (isId ? `Bagian ${idx + 1}` : `Section ${idx + 1}`));

      const isExperienceSection = /pengalaman|experience|proyek|project|work|kerja|magang|internship|organisasi/i.test(
        heading
      );

      const rawBullets = Array.isArray(sec.bullets) ? sec.bullets : [];
      const sanitizedBullets = [];

      for (const b of rawBullets) {
        if (typeof b !== 'string') continue;
        const trimmed = b.trim();
        if (!trimmed || isBiasLine(trimmed)) continue;

        if (isExperienceSection) {
          const guarded = ensureMetricOrPlaceholder(trimmed, sourceText, normalizedLang, {
            skipAppendIfHeader: true,
          });
          if (guarded) sanitizedBullets.push(guarded);
        } else {
          sanitizedBullets.push(sanitizeFabricatedMetrics(trimmed, sourceText, normalizedLang));
        }
      }

      return { heading, bullets: sanitizedBullets };
    })
    .filter((sec) => sec.bullets.length > 0);

  if (sections.length === 0) {
    throw new Error('Invalid CV rewrite schema: all sections empty after sanitization');
  }

  // Guarantee Zero-Hallucination placeholder parity: if original CV had no metrics,
  // ensure the rewritten experience section has explicit [placeholder] tags
  const sectionsJoined = JSON.stringify(sections);
  if (!sourceHasMetrics && !hasBracketPlaceholder(sectionsJoined)) {
    const expSec = sections.find((s) =>
      /pengalaman|experience|proyek|project|work|kerja/i.test(s.heading)
    ) || sections[0];
    if (expSec.bullets.length > 0) {
      const targetIdx = expSec.bullets.findIndex((b) => !isHeaderLikeBullet(b));
      const idxToPatch = targetIdx !== -1 ? targetIdx : expSec.bullets.length - 1;
      expSec.bullets[idxToPatch] = ensureMetricOrPlaceholder(
        expSec.bullets[idxToPatch],
        sourceText,
        normalizedLang,
        { skipAppendIfHeader: false }
      );
    }
  }

  const changes = normalizeStringArray(rawCv.changes);
  if (changes.length === 0) {
    changes.push(
      isId
        ? 'Menghapus data bias pribadi dan menyusun ulang poin pengalaman dengan format STAR dan penanda metrik [X]%.'
        : 'Removed personal bias fields and restructured experience bullets into STAR format with [X]% metric placeholders.'
    );
  }

  return {
    cv: {
      language: normalizedLang,
      name,
      title,
      contact:
        contact.length > 0
          ? contact
          : [
              '[email@domain.com]',
              '[+62 8XX XXXX XXXX]',
              isId ? 'Indonesia' : 'Indonesia (Open to Remote)',
              isId ? 'linkedin.com/in/[profil-anda]' : 'linkedin.com/in/[your-profile]',
            ],
      summary,
      sections,
      changes,
    },
    engine,
  };
}

/**
 * Sanitize and enforce Zero-Hallucination metric & placeholder parity on a Brag Doc STAR bullet
 * across both live Gemini and deterministic fallback paths.
 */
function sanitizeWinBulletResult(rawBullet, { title = '', impactMetric = '', lang = 'en', engine = 'gemini' }) {
  const normalizedLang = normalizeLanguage(lang, `${title} ${impactMetric}`);
  const isId = normalizedLang === 'id';
  const sourceText = `${title} ${impactMetric}`.trim();

  if (typeof rawBullet !== 'string' || !rawBullet.trim()) {
    throw new Error('Invalid STAR bullet: empty string');
  }

  // 1. Strip any fabricated numeric metrics not provided by the user
  let bullet = sanitizeFabricatedMetrics(rawBullet.trim(), sourceText, normalizedLang);

  // 2. If user provided NO genuine quantified metric, guarantee a bracketed [placeholder] exists
  const userProvidedMetric = hasQuantifiedMetric(sourceText);
  if (!userProvidedMetric && !hasBracketPlaceholder(bullet)) {
    bullet =
      bullet.replace(/[.。]+$/, '') +
      (isId
        ? ', meningkatkan efektivitas sebesar [X]% pada [metrik target].'
        : ', improving outcome efficiency by [X]% across [target metric].');
  }

  return {
    starBullet: bullet,
    language: normalizedLang,
    hasPlaceholder: hasBracketPlaceholder(bullet),
    engine,
  };
}

module.exports = {
  VALID_ISSUE_CATEGORIES,
  VALID_ISSUE_SEVERITIES,
  EXPLICIT_PHOTO_TEXT_REGEX,
  PHOTO_ISSUE_REGEX,
  PERSONAL_BIAS_REGEX,
  BIAS_LINE_REGEX,
  BRACKET_PLACEHOLDER_REGEX,
  DEFAULT_FALLBACK_MODELS,
  getGeminiModelChain,
  parseGeminiJson,
  generateJsonWithGemini,
  hasExplicitPhotoEvidence,
  isPhotoHallucinationIssue,
  stripHallucinatedPhotoIssues,
  extractSourceNumbers,
  hasQuantifiedMetric,
  hasBracketPlaceholder,
  sanitizeFabricatedMetrics,
  isHeaderLikeBullet,
  ensureMetricOrPlaceholder,
  isBiasLine,
  sanitizeAnalysisResult,
  sanitizeRewriteResult,
  sanitizeWinBulletResult,
};

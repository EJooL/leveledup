/**
 * Bilingual ('id' / 'en') Language Normalization, Detection, Validation,
 * and Standardized Error Helpers for LeveledUp Backend Services.
 */

const VALID_LANGUAGES = new Set(['id', 'en']);

const VALID_WIN_CATEGORIES = [
  'project_delivery',
  'metrics_growth',
  'process_quality',
  'leadership_teamwork',
];

const ID_STRONG_PATTERNS = [
  /\bpengalaman\s+kerja\b/,
  /\bpengalaman\s+profesional\b/,
  /\bpendidikan\b/,
  /\bkeahlian\b/,
  /\bkemampuan\b/,
  /\bketerampilan\b/,
  /\bringkasan\b/,
  /\btentang\s+saya\b/,
  /\bbertanggung\s+jawab\b/,
  /\btanggal\s+lahir\b/,
  /\btempat\s+lahir\b/,
  /\bagama\b/,
  /\bstatus\s+pernikahan\b/,
  /\bstatus\s+perkawinan\b/,
  /\bpekerja\s+keras\b/,
  /\bdi\s*bawah\s+tekanan\b/,
  /\bbahasa\s+indonesia\b/,
  /\blulusan\b/,
  /\bsekarang\b/,
];

const ID_GENERAL_PATTERNS = [
  /\bbekerja\b/,
  /\bperusahaan\b/,
  /\bmengelola\b/,
  /\bmembantu\b/,
  /\bmeningkatkan\b/,
  /\bmengoptimalkan\b/,
  /\bmerancang\b/,
  /\bmembuat\b/,
  /\bmenyelesaikan\b/,
  /\bmengembangkan\b/,
  /\bproyek\b/,
  /\blaporan\b/,
  /\bpenjualan\b/,
  /\bkeuangan\b/,
  /\bkaryawan\b/,
  /\bpelanggan\b/,
  /\bpengguna\b/,
  /\bpencapaian\b/,
  /\bperbaikan\b/,
  /\bterukur\b/,
  /\bsebesar\b/,
  /\banda\b/,
  /\bdengan\b/,
  /\buntuk\b/,
  /\byang\b/,
  /\bpada\b/,
  /\bdalam\b/,
  /\btempat\b/,
];

const EN_STRONG_PATTERNS = [
  /\bwork\s+experience\b/,
  /\bprofessional\s+experience\b/,
  /\bexperience\b/,
  /\beducation\b/,
  /\bskills\b/,
  /\bsummary\b/,
  /\bresponsible\s+for\b/,
  /\buniversity\b/,
  /\bbachelor\b/,
  /\bpresent\b/,
  /\bcertifications\b/,
  /\bachievements\b/,
  /\benglish\b/,
];

const EN_GENERAL_PATTERNS = [
  /\bengineered\b/,
  /\bdeveloped\b/,
  /\bmanaged\b/,
  /\bdesigned\b/,
  /\bcollaborated\b/,
  /\bprojects\b/,
  /\bimproved\b/,
  /\boptimized\b/,
  /\bbuilt\b/,
  /\bcreated\b/,
  /\bdelivered\b/,
  /\breduced\b/,
  /\bincreased\b/,
  /\bresults\b/,
  /\bmetrics\b/,
  /\bstrong\b/,
  /\byour\b/,
  /\bwith\b/,
  /\bfor\b/,
  /\bthe\b/,
  /\band\b/,
  /\bfrom\b/,
];

/**
 * Detect whether text (full CV, short summary, or Brag Doc win) is primarily
 * Bahasa Indonesia ('id') or English ('en').
 * @param {string} text
 * @returns {'id' | 'en'}
 */
function detectTextLanguage(text) {
  const lower = typeof text === 'string' ? text.toLowerCase() : '';
  if (!lower.trim()) return 'en';

  let idScore = 0;
  let enScore = 0;

  for (const rx of ID_STRONG_PATTERNS) {
    if (rx.test(lower)) idScore += 2;
  }
  for (const rx of ID_GENERAL_PATTERNS) {
    if (rx.test(lower)) idScore += 1;
  }
  for (const rx of EN_STRONG_PATTERNS) {
    if (rx.test(lower)) enScore += 2;
  }
  for (const rx of EN_GENERAL_PATTERNS) {
    if (rx.test(lower)) enScore += 1;
  }

  return idScore > enScore ? 'id' : 'en';
}

/**
 * Normalize explicit language input (e.g. 'id', 'ID', 'id-ID', 'en-US', 'auto')
 * into canonical 'id' | 'en', falling back to text detection when unset or 'auto'.
 * @param {string|null|undefined} rawLang
 * @param {string} [fallbackText='']
 * @returns {'id' | 'en'}
 */
function normalizeLanguage(rawLang, fallbackText = '') {
  if (typeof rawLang === 'string') {
    const cleaned = rawLang.trim().toLowerCase();
    if (cleaned === 'id' || cleaned.startsWith('id-') || cleaned.startsWith('id_') || cleaned === 'bahasa' || cleaned === 'indonesia' || cleaned === 'indonesian') {
      return 'id';
    }
    if (cleaned === 'en' || cleaned.startsWith('en-') || cleaned.startsWith('en_') || cleaned === 'english') {
      return 'en';
    }
    if (cleaned === 'auto' || cleaned === '') {
      return detectTextLanguage(fallbackText);
    }
  }
  return fallbackText ? detectTextLanguage(fallbackText) : 'en';
}

/**
 * Resolve preferred response language from explicit param, text content, or Accept-Language header.
 * @param {{ language?: string, text?: string, acceptLanguage?: string }} params
 * @returns {'id' | 'en'}
 */
function resolveRequestLanguage({ language, text = '', acceptLanguage = '' } = {}) {
  if (typeof language === 'string') {
    const cleaned = language.trim().toLowerCase();
    if (cleaned && cleaned !== 'auto') {
      const normalized = normalizeLanguage(cleaned, '');
      if (VALID_LANGUAGES.has(normalized) && (cleaned.startsWith('id') || cleaned.startsWith('en') || cleaned === 'bahasa' || cleaned === 'indonesia' || cleaned === 'indonesian' || cleaned === 'english')) {
        return normalized;
      }
    }
  }

  if (typeof text === 'string' && text.trim().length >= 10) {
    return detectTextLanguage(text);
  }

  if (typeof acceptLanguage === 'string' && acceptLanguage.trim().length > 0) {
    const primary = acceptLanguage.split(',')[0].trim().toLowerCase();
    if (primary.startsWith('id')) return 'id';
    if (primary.startsWith('en')) return 'en';
  }

  return 'en';
}

/**
 * Standardized bilingual error message catalog shared across services and available
 * for routes/middleware adoption.
 */
const ERROR_CATALOG = {
  FILE_MISSING: {
    status: 400,
    en: 'No PDF file was uploaded. Please attach a PDF file under the "file" field.',
    id: 'File tidak dikirim atau dokumen kosong. Harap sertakan file PDF pada field "file".',
  },
  FILE_TOO_LARGE: {
    status: 413,
    en: 'File size exceeds the 4 MB maximum limit.',
    id: 'Ukuran file melebihi batas maksimum 4 MB.',
  },
  PDF_UNREADABLE: {
    status: 422,
    en: 'The PDF could not be read or appears to be an image-only scan (< 80 characters extracted). Please upload a text-based PDF.',
    id: 'PDF tidak dapat dibaca atau berbasis scan gambar (< 80 karakter teks). Silakan unggah PDF berbasis teks asli.',
  },
  PDF_PARSE_FAILED: {
    status: 422,
    en: 'Failed to parse PDF document.',
    id: 'Gagal membaca file PDF.',
  },
  TEXT_TOO_SHORT: {
    status: 400,
    en: 'CV text is invalid or too short (at least 80 characters are required for analysis).',
    id: 'Teks CV tidak valid atau terlalu pendek (minimal 80 karakter teks diperlukan untuk analisis).',
  },
  WIN_TITLE_REQUIRED: {
    status: 400,
    en: 'Achievement title is required and must be at least 3 characters.',
    id: 'Judul pencapaian (achievement) wajib diisi minimal 3 karakter.',
  },
  INVALID_WIN_CATEGORY: {
    status: 400,
    en: 'Invalid win category. Must be one of: project_delivery, metrics_growth, process_quality, leadership_teamwork.',
    id: 'Kategori pencapaian tidak valid. Gunakan salah satu: project_delivery, metrics_growth, process_quality, leadership_teamwork.',
  },
  NO_WINS_SELECTED: {
    status: 400,
    en: 'Select at least 1 work win to merge into your CV.',
    id: 'Pilih minimal 1 pencapaian (Work Win) untuk digabungkan ke dalam CV Anda.',
  },
  CODE_REQUIRED: {
    status: 400,
    en: 'Access code is required.',
    id: 'Kode akses wajib diisi.',
  },
  CODE_EXHAUSTED: {
    status: 402,
    en: 'This access code has reached its usage limit.',
    id: 'Batas kuota pemakaian kode akses ini telah habis.',
  },
  CODE_EXPIRED: {
    status: 402,
    en: 'This access code has expired.',
    id: 'Masa berlaku kode akses ini telah kedaluwarsa.',
  },
  INVALID_ACCESS_CODE: {
    status: 402,
    en: 'Access code is invalid or not found.',
    id: 'Kode akses tidak valid atau tidak ditemukan.',
  },
  PAYMENT_REQUIRED: {
    status: 402,
    en: 'CV Rewrite requires an unlocked scan or a valid VIP access code.',
    id: 'Fitur Tulis Ulang CV memerlukan akses terbuka atau kode akses VIP yang valid.',
  },
  INVALID_TOKEN: {
    status: 400,
    en: 'Analysis token is invalid or expired.',
    id: 'Token analisis tidak valid atau kadaluwarsa.',
  },
  QUEST_KEY_REQUIRED: {
    status: 400,
    en: 'questKey is required.',
    id: 'questKey wajib disertakan.',
  },
  QUEST_NOT_FOUND: {
    status: 404,
    en: 'Requested quest was not found.',
    id: 'Quest yang diminta tidak ditemukan.',
  },
  QUEST_NOT_MANUAL: {
    status: 400,
    en: 'This quest is automatically verified by CV scan or logged work wins and cannot be toggled manually.',
    id: 'Quest ini diverifikasi otomatis dari hasil scan CV atau pencatatan Win dan tidak dapat dicentang manual.',
  },
  INVALID_CAREER_MODE: {
    status: 400,
    en: "Career mode must be either 'job_hunt' or 'hired'.",
    id: "Mode karir harus bernilai 'job_hunt' atau 'hired'.",
  },
  NOT_FOUND: {
    status: 404,
    en: 'Requested endpoint was not found.',
    id: 'Endpoint yang diminta tidak ditemukan.',
  },
  INTERNAL_SERVER_ERROR: {
    status: 500,
    en: 'An internal server error occurred.',
    id: 'Terjadi kesalahan internal pada server.',
  },
};

/**
 * Build a standardized bilingual error payload.
 * Preserves legacy `{ error, code }` shape while adding `{ errorEn, errorId, language }`.
 * @param {string} code
 * @param {'id' | 'en'} [lang='en']
 * @param {{ detail?: string }} [options]
 */
function formatBilingualError(code, lang = 'en', options = {}) {
  const entry = ERROR_CATALOG[code] || ERROR_CATALOG.INTERNAL_SERVER_ERROR;
  const normalizedLang = normalizeLanguage(lang);
  const suffix = options.detail ? ` (${options.detail})` : '';
  const errorEn = `${entry.en}${suffix}`;
  const errorId = `${entry.id}${suffix}`;

  return {
    status: entry.status,
    body: {
      error: normalizedLang === 'id' ? errorId : errorEn,
      errorEn,
      errorId,
      language: normalizedLang,
      code: ERROR_CATALOG[code] ? code : 'INTERNAL_SERVER_ERROR',
    },
  };
}

/**
 * Create an Error instance enriched with `.status`, `.code`, `.language`, `.errorEn`, `.errorId`.
 * @param {string} code
 * @param {'id' | 'en'} [lang='en']
 * @param {{ detail?: string }} [options]
 * @returns {Error}
 */
function createServiceError(code, lang = 'en', options = {}) {
  const { status, body } = formatBilingualError(code, lang, options);
  const err = new Error(body.error);
  err.status = status;
  err.code = body.code;
  err.language = body.language;
  err.errorEn = body.errorEn;
  err.errorId = body.errorId;
  return err;
}

/**
 * Validate CV text input for analysis or rewrite services.
 * @param {string} text
 * @param {{ minLength?: number, language?: string }} [options]
 * @returns {{ cleanText: string, language: 'id' | 'en' }}
 */
function validateCvText(text, options = {}) {
  const minLength = Number.isInteger(options.minLength) ? options.minLength : 80;
  const lang = resolveRequestLanguage({
    language: options.language,
    text: typeof text === 'string' ? text : '',
  });

  if (typeof text !== 'string' || text.trim().length < minLength) {
    throw createServiceError('TEXT_TOO_SHORT', lang);
  }

  const cleanText = text.trim();
  const detectedLang = normalizeLanguage(options.language, cleanText);
  return {
    cleanText,
    language: detectedLang,
  };
}

/**
 * Validate and normalize Brag Doc work win input.
 * @param {{ title?: string, impactMetric?: string, category?: string, language?: string }} input
 * @returns {{ title: string, impactMetric: string, category: string, language: 'id' | 'en' }}
 */
function validateWinInput(input = {}) {
  const rawTitle = typeof input.title === 'string' ? input.title.trim() : '';
  const rawImpact = typeof input.impactMetric === 'string' ? input.impactMetric.trim() : '';
  const combined = `${rawTitle} ${rawImpact}`.trim();
  const language = normalizeLanguage(input.language, combined);

  if (rawTitle.length < 3) {
    throw createServiceError('WIN_TITLE_REQUIRED', language);
  }

  const rawCategory = typeof input.category === 'string' ? input.category.trim().toLowerCase() : '';
  const category = VALID_WIN_CATEGORIES.includes(rawCategory)
    ? rawCategory
    : 'project_delivery';

  return {
    title: rawTitle,
    impactMetric: rawImpact,
    category,
    language,
  };
}

module.exports = {
  VALID_LANGUAGES,
  VALID_WIN_CATEGORIES,
  ERROR_CATALOG,
  detectTextLanguage,
  normalizeLanguage,
  resolveRequestLanguage,
  formatBilingualError,
  createServiceError,
  validateCvText,
  validateWinInput,
};

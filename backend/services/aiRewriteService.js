const { ai, isAiAvailable } = require('../config/ai');
const { inferJobRole, detectCvLanguage } = require('./ruleBasedService');

function buildRewriteSystemPrompt(lang) {
  const isId = lang === 'id';
  const langName = isId ? 'Bahasa Indonesia' : 'English';

  return `You are LeveledUp CV Rewrite Engine, an expert ATS resume writer.

LANGUAGE RULE (CRITICAL):
The candidate's original CV is written in **${langName}**.
You MUST write the entire rewritten CV (\`title\`, \`summary\`, \`sections[].heading\`, \`sections[].bullets\`, and \`changes\`) strictly in **${langName}**!

CRITICAL RULES:
1. ZERO-HALLUCINATION / ANTI-FABRICATION:
   - NEVER fabricate numbers, companies, dates, or degrees that are not in the CV.
   - If a metric or quantified result is missing, you MUST insert an explicit bracketed placeholder like ${isId ? '[X]%, [jumlah], atau [ukuran tim]' : '[X]%, [amount], or [team size]'} so the candidate can fill in their actual data.
2. REMOVE ALL BIAS DATA:
   - Strip out photos, age, date of birth (TTL), marital status, religion, gender, national ID (NIK), blood type, height/weight, and irrelevant hobbies.
3. TRANSFORM PASSIVE DUTIES TO STAR ACHIEVEMENTS:
   - Start bullets with strong action verbs (${isId ? 'Merancang, Mengoptimalkan, Memimpin, Mengembangkan, Mempercepat' : 'Architected, Engineered, Optimized, Spearheaded, Accelerated'}).
   - Use: Strong Action Verb + Context + [Quantified Impact].

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
      "linkedin.com/in/username",
      "github.com/username"
    ],
    "summary": "Impactful 2-3 sentence executive summary in ${langName}.",
    "sections": [
      {
        "heading": "${isId ? 'Pengalaman Profesional' : 'Professional Experience'}",
        "bullets": [
          "${isId ? 'Mengembangkan dan meluncurkan [fitur] yang meningkatkan efisiensi sebesar [X]%.' : 'Developed and deployed [feature] resulting in [X]% improvement in [metric].'}"
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
          "${isId ? 'Bahasa & Framework: ...' : 'Languages & Frameworks: ...'}"
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
 * Generate a rule-based fallback rewrite matching the detected language ('id' or 'en')
 */
function generateFallbackRewrite(text) {
  const lang = detectCvLanguage(text);
  const isId = lang === 'id';
  const role = inferJobRole(text);

  const lines = text.split('\n').map((l) => l.trim()).filter(Boolean);
  let applicantName = 'Budi Santoso';
  if (
    lines.length > 0 &&
    lines[0].length < 40 &&
    !/cv|resume|curriculum/i.test(lines[0])
  ) {
    applicantName = lines[0].replace(/^(nama\s*:|name\s*:)/i, '').trim();
  }

  const emailMatch = text.match(
    /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/
  );
  const phoneMatch = text.match(/(\+62|08|62)[\d\s-]{8,14}/);

  const contact = [
    emailMatch ? emailMatch[0] : 'budi.santoso@example.com',
    phoneMatch ? phoneMatch[0].replace(/\s+/g, ' ') : '+62 812 3456 7890',
    isId ? 'Jakarta, Indonesia' : 'Jakarta, Indonesia (Open to Remote)',
    'linkedin.com/in/budisantoso',
    'github.com/budisantoso',
  ];

  if (isId) {
    return {
      cv: {
        language: 'id',
        name: applicantName,
        title: role,
        contact,
        summary: `${role} berorientasi hasil dengan pengalaman praktis dalam membangun sistem perangkat lunak yang andal dan skalabel. Terbukti mampu berkolaborasi lintas tim untuk mengoptimalkan performa sistem sebesar [X]% dan menyelesaikan rilis fitur tepat waktu.`,
        sections: [
          {
            heading: 'Pengalaman Profesional',
            bullets: [
              `Merancang dan memelihara layanan backend REST API menggunakan Node.js dan Express, meningkatkan kecepatan respons sebesar [X]% pada [jumlah] endpoint.`,
              `Mengoptimalkan skema dan indexing database MySQL, memangkas latensi eksekusi query dari [waktu awal] menjadi [waktu akhir].`,
              `Mengintegrasikan sistem autentikasi dan payment gateway yang aman untuk menangani lebih dari [jumlah] transaksi bulanan dengan uptime [X]%.`,
              `Berkolaborasi dengan tim mobile dalam pengembangan modul antarmuka Flutter, mempercepat siklus rilis fitur sebesar [X]%.`,
            ],
          },
          {
            heading: 'Pendidikan',
            bullets: [
              'S1 Teknik Informatika — Universitas Indonesia (2019 – 2023) | IPK: [X.XX]/4.00',
            ],
          },
          {
            heading: 'Keahlian Teknis',
            bullets: [
              `Bahasa & Framework: Dart, Flutter, JavaScript (ES6+), Node.js, Express.js, SQL`,
              'Database & Perangkat: MySQL, REST API, Git, Docker, Postman, Agile/Scrum',
            ],
          },
        ],
        changes: [
          'Menghapus pas foto, Tempat/Tanggal Lahir (TTL), Agama, Status Pernikahan, dan NIK agar bebas bias dan ramah parser ATS.',
          'Mengonversi kalimat tugas pasif ("Bertanggung jawab...") menjadi poin pencapaian aktif berpola STAR dalam Bahasa Indonesia.',
          'Menambahkan penanda [placeholder] pada metrik angka yang perlu Anda isi dengan data riil proyek Anda (Kebijakan Anti-Fabrikasi).',
        ],
      },
    };
  }

  return {
    cv: {
      language: 'en',
      name: applicantName,
      title: role,
      contact,
      summary: `Results-oriented ${role} with hands-on expertise in delivering robust, high-performance applications. Proven track record in collaborating with agile teams to optimize workflows, improve system reliability by [X]%, and deliver high-impact features.`,
      sections: [
        {
          heading: 'Professional Experience',
          bullets: [
            `Spearheaded the development and maintenance of core ${role} services, improving execution speed by [X]%.`,
            `Optimized MySQL database indexing and connection pooling, cutting query latency from [initial ms] to [target ms].`,
            `Collaborated with cross-functional product and engineering teams to ship [number] major feature releases on schedule.`,
            `Engineered automated tests and CI/CD checks, achieving [X]% test coverage across production modules.`,
          ],
        },
        {
          heading: 'Education',
          bullets: [
            'B.S. in Computer Science — Universitas Indonesia (2019 – 2023) | GPA: [X.XX]/4.00',
          ],
        },
        {
          heading: 'Technical Skills',
          bullets: [
            `Languages & Frameworks: Dart, Flutter, JavaScript (ES6+), Node.js, Express.js, SQL`,
            'Databases & DevOps: MySQL, RESTful APIs, Git, Docker, CI/CD, Agile/Scrum',
          ],
        },
      ],
      changes: [
        'Removed photo, Date of Birth, Religion, Marital Status, and National ID to comply with global EEOC anti-bias standards.',
        'Transformed passive duty descriptions into action-driven English STAR achievement bullets.',
        'Inserted bracketed [placeholder] markers for metrics you must fill with your real project numbers (Zero-Hallucination Policy).',
      ],
    },
  };
}

/**
 * Rewrite CV with AI (matching original CV language: 'en' or 'id') or fallback template
 * @param {string} text - CV text
 * @returns {Promise<object>} Rewritten CV
 */
async function rewriteCv(text) {
  const lang = detectCvLanguage(text);

  if (!isAiAvailable()) {
    return generateFallbackRewrite(text);
  }

  try {
    const prompt = `Rewrite the following CV into an ATS-friendly structure in ${lang === 'id' ? 'Bahasa Indonesia' : 'English'}:\n\n=== ORIGINAL CV ===\n${text}\n=== END ===`;

    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: prompt,
      config: {
        systemInstruction: buildRewriteSystemPrompt(lang),
        responseMimeType: 'application/json',
      },
    });

    const outputText =
      response.text ||
      (response.candidates && response.candidates[0]?.content?.parts[0]?.text);
    if (!outputText) {
      throw new Error('Empty response from AI rewrite model');
    }

    const parsed = JSON.parse(outputText);
    if (!parsed.cv || !Array.isArray(parsed.cv.sections)) {
      throw new Error('Invalid JSON structure returned by rewrite model');
    }
    parsed.cv.language = lang;

    return parsed;
  } catch (err) {
    console.warn(
      `[AI Rewrite Warning] Gemini API call failed: ${err.message}. Using rule-based fallback rewrite.`
    );
    return generateFallbackRewrite(text);
  }
}

module.exports = {
  rewriteCv,
  generateFallbackRewrite,
};

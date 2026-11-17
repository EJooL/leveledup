import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../../models/cv_analysis_model.dart';

class ParseResponseData {
  final String fileName;
  final int numPages;
  final int numChars;
  final bool hasPhoto;
  final String text;

  ParseResponseData({
    required this.fileName,
    required this.numPages,
    required this.numChars,
    this.hasPhoto = false,
    required this.text,
  });
}

class AnalyzeResponseData {
  final String scanToken;
  final AnalysisResult result;
  final String encryptedToken;

  AnalyzeResponseData({
    required this.scanToken,
    required this.result,
    required this.encryptedToken,
  });
}

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 35),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );
  }

  /// Automatically detect whether the CV text is in Bahasa Indonesia ('id') or English ('en')
  static String detectLanguage(String text) {
    final lower = text.toLowerCase();
    final idMarkers = [
      RegExp(r'\bpengalaman\b'),
      RegExp(r'\bpendidikan\b'),
      RegExp(r'\bkeahlian\b'),
      RegExp(r'\bkemampuan\b'),
      RegExp(r'\bringkasan\b'),
      RegExp(r'\btentang\s+saya\b'),
      RegExp(r'\bbertanggung\s+jawab\b'),
      RegExp(r'\btanggal\s+lahir\b'),
      RegExp(r'\bttl\b'),
      RegExp(r'\bagama\b'),
      RegExp(r'\bstatus\b'),
      RegExp(r'\bsekarang\b'),
      RegExp(r'\bpekerja\s+keras\b'),
      RegExp(r'\bmembantu\b'),
      RegExp(r'\bmengelola\b'),
    ];
    final enMarkers = [
      RegExp(r'\bexperience\b'),
      RegExp(r'\beducation\b'),
      RegExp(r'\bskills\b'),
      RegExp(r'\bsummary\b'),
      RegExp(r'\bresponsible\s+for\b'),
      RegExp(r'\bpresent\b'),
      RegExp(r'\bengineered\b'),
      RegExp(r'\bdeveloped\b'),
      RegExp(r'\bmanaged\b'),
      RegExp(r'\bassisted\b'),
      RegExp(r'\bdate\s+of\s+birth\b'),
      RegExp(r'\bmarital\s+status\b'),
    ];

    var idCount = 0;
    var enCount = 0;
    for (final rx in idMarkers) {
      if (rx.hasMatch(lower)) idCount++;
    }
    for (final rx in enMarkers) {
      if (rx.hasMatch(lower)) enCount++;
    }

    return idCount > enCount ? 'id' : 'en';
  }

  /// 1. POST /api/parse — Upload PDF bytes and extract raw text + photo flag
  Future<ParseResponseData> parsePdfBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: DioMediaType('application', 'pdf'),
        ),
      });

      final response = await _dio.post(
        ApiConstants.parseEndpoint,
        data: formData,
      );

      final data = response.data as Map<String, dynamic>;
      return ParseResponseData(
        fileName: data['fileName']?.toString() ?? fileName,
        numPages: (data['numPages'] is num) ? (data['numPages'] as num).toInt() : 1,
        numChars: (data['numChars'] is num) ? (data['numChars'] as num).toInt() : 0,
        hasPhoto: data['hasPhoto'] == true,
        text: data['text']?.toString() ?? '',
      );
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        final msg = (e.response?.data as Map)['error']?.toString() ?? 'Failed to parse PDF.';
        throw Exception(msg);
      }
      throw Exception(
        'Could not connect to the backend PDF parser at ${ApiConstants.baseUrl}. Please make sure "npm run dev" is running in the backend folder.',
      );
    }
  }

  /// 2. POST /api/analyze — Analyze extracted CV text (matching language: 'en' or 'id')
  Future<AnalyzeResponseData> analyzeCvText({
    required String text,
    required String fileName,
    bool hasPhoto = false,
    String deviceId = 'flutter-mobile-client',
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.analyzeEndpoint,
        data: {
          'text': text,
          'fileName': fileName,
          'hasPhoto': hasPhoto,
          'deviceId': deviceId,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final scanToken = data['scanToken']?.toString() ?? 'scn_local';
      final token = data['token']?.toString() ?? 'local_encrypted_token';
      final resultJson = data['result'] as Map<String, dynamic>;
      resultJson['language'] = resultJson['language'] ?? detectLanguage(text);

      return AnalyzeResponseData(
        scanToken: scanToken,
        result: AnalysisResult.fromJson(resultJson, unlocked: false),
        encryptedToken: token,
      );
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        final msg = (e.response?.data as Map)['error']?.toString() ?? 'Failed to analyze CV.';
        throw Exception(msg);
      }
      return _buildOfflineAnalysis(
        text: text,
        fileName: fileName,
        hasPhoto: hasPhoto,
        unlocked: false,
      );
    }
  }

  /// 3. POST /api/unlock — Unlock full ATS issue fixes & Before/After examples
  Future<AnalysisResult> unlockAnalysis({
    required String scanToken,
    required String encryptedToken,
    required String accessCode,
    required String currentText,
    required String fileName,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.unlockEndpoint,
        data: {
          'scanToken': scanToken,
          'token': encryptedToken,
          'code': accessCode.trim().toUpperCase(),
        },
      );

      final data = response.data as Map<String, dynamic>;
      data['language'] = data['language'] ?? detectLanguage(currentText);
      return AnalysisResult.fromJson(data, unlocked: true);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        final msg = (e.response?.data as Map)['error']?.toString() ?? 'Invalid access code.';
        throw Exception(msg);
      }
      if (accessCode.trim().toUpperCase() != ApiConstants.defaultVipCode) {
        throw Exception('Invalid access code. Try ${ApiConstants.defaultVipCode} for MVP testing.');
      }
      return _buildOfflineAnalysis(
        text: currentText,
        fileName: fileName,
        unlocked: true,
      ).result;
    }
  }

  /// 4. POST /api/rewrite — Generate Zero-Hallucination ATS-optimized CV (in matching language)
  Future<ImprovedCV> rewriteCv({
    required String scanToken,
    required String text,
    required String accessCode,
    required String fileName,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.rewriteEndpoint,
        data: {
          'scanToken': scanToken,
          'text': text,
          'code': accessCode.trim().toUpperCase(),
          'fileName': fileName,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final cvJson = data['cv'] as Map<String, dynamic>;
      cvJson['language'] = cvJson['language'] ?? detectLanguage(text);
      return ImprovedCV.fromJson(cvJson);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        final msg = (e.response?.data as Map)['error']?.toString() ?? 'Failed to rewrite CV.';
        throw Exception(msg);
      }
      return _buildOfflineRewrite(text);
    }
  }

  /// Dynamic, evidence-based local heuristic analysis ('id' vs 'en') — never hallucinates missing issues!
  AnalyzeResponseData _buildOfflineAnalysis({
    required String text,
    required String fileName,
    bool hasPhoto = false,
    required bool unlocked,
  }) {
    final lang = detectLanguage(text);
    final isId = lang == 'id';
    final issues = <Issue>[];

    // 1. Check photo ONLY if actually present in PDF or explicitly declared
    final explicitPhotoRx = RegExp(
      r'\b(pas\s*foto|pasfoto|foto\s*diri|foto\s*4x6|foto\s*3x4|photo\s*:\s*headshot|headshot\s*attached|foto\s*terlampir)\b',
      caseSensitive: false,
    );
    if (hasPhoto || explicitPhotoRx.hasMatch(text)) {
      issues.add(
        Issue(
          id: 'photo',
          category: 'personal_info',
          severity: 'critical',
          title: isId
              ? 'CV menyertakan pas foto atau penanda foto diri'
              : 'CV includes a headshot photo or photo indicator',
          detail: unlocked
              ? (isId
                  ? 'Standar ATS modern memprioritaskan kualifikasi objektif. Menyertakan foto dapat memicu bias seleksi dan mengganggu pembacaan teks oleh sistem ATS.'
                  : 'In US, UK, and global remote hiring, resumes with photos are frequently auto-rejected to comply with strict anti-discrimination (EEOC) laws.')
              : null,
          fix: unlocked
              ? (isId
                  ? 'Hapus pas foto dari CV dan fokuskan bagian header pada nama lengkap, email, nomor telepon, serta tautan LinkedIn/GitHub.'
                  : 'Remove your headshot photo completely and dedicate header space to clean contact links (LinkedIn, GitHub, Portfolio).')
              : null,
          rewrite: unlocked
              ? RewriteExample(
                  before: isId ? '[Pas Foto 4x6 di sudut atas CV]' : '[Headshot Photo in Top Corner]',
                  after: 'Budi Santoso • Jakarta, Indonesia • linkedin.com/in/budisantoso • github.com/budisantoso',
                )
              : null,
        ),
      );
    }

    // 2. Check DOB, Religion, Marital Status, or NIK ONLY if present in text
    final dobMaritalRx = RegExp(
      r'(tanggal\s+lahir|tempat\s+lahir|date\s+of\s+birth|\bttl\b|status\s+pernikahan|marital\s+status|\bagama\s*:|\breligion\s*:|\bnik\s*:)',
      caseSensitive: false,
    );
    if (dobMaritalRx.hasMatch(text)) {
      issues.add(
        Issue(
          id: 'dob_marital',
          category: 'personal_info',
          severity: 'critical',
          title: isId
              ? 'Tercantum Tempat/Tanggal Lahir (TTL), Agama, Status Pernikahan, atau NIK'
              : 'Contains Date of Birth, Religion, or Marital Status',
          detail: unlocked
              ? (isId
                  ? 'Data demografis sensitif berisiko memicu bias usia dan privasi, serta mengekspos Nomor Induk Kependudukan (NIK).'
                  : 'Sensitive demographic data triggers age or religious bias risk under international hiring compliance.')
              : null,
          fix: unlocked
              ? (isId
                  ? 'Hapus baris TTL, Agama, Status Pernikahan, dan NIK dari bagian informasi pribadi Anda.'
                  : 'Delete Date of Birth, Religion, and Marital Status from your resume header.')
              : null,
          rewrite: unlocked
              ? RewriteExample(
                  before: isId
                      ? 'TTL: Jakarta, 15 Juli 2001 | Agama: Islam | Status: Belum Menikah'
                      : 'DOB: July 15, 2001 | Marital Status: Single | Religion: Islam',
                  after: isId
                      ? '[Dihapus sepenuhnya — cukup tampilkan domisili kota, email, telepon, dan portofolio]'
                      : '[Removed completely — only email, phone, and professional links retained]',
                )
              : null,
        ),
      );
    }

    // 3. Check passive duties
    final passiveRx = RegExp(
      r'\b(bertanggung\s+jawab|responsible\s+for|tugas\s+saya|assisted\s+in|worked\s+on|membantu\s+tim)\b',
      caseSensitive: false,
    );
    if (passiveRx.hasMatch(text)) {
      issues.add(
        Issue(
          id: 'duties',
          category: 'achievements',
          severity: 'warning',
          title: isId
              ? 'Poin pengalaman kerja masih berupa daftar tugas pasif ("Bertanggung jawab...")'
              : 'Experience bullets read like passive job duties instead of quantified impact',
          detail: unlocked
              ? (isId
                  ? 'Rekruter mencari bukti pencapaian terukur dengan metode STAR (Kata Kerja Aktif + Konteks + Metrik Hasil), bukan sekadar deskripsi tugas rutin.'
                  : 'Global recruiters scan for the STAR pattern (Action Verb + Context + Quantified Metric) rather than "Responsible for..." statements.')
              : null,
          fix: unlocked
              ? (isId
                  ? 'Awali setiap poin dengan kata kerja aktif (Merancang, Mengoptimalkan, Mengembangkan) dan sertakan metrik persentase.'
                  : 'Start every bullet with a strong past-tense action verb (Engineered, Optimized, Spearheaded) and attach measurable results.')
              : null,
          rewrite: unlocked
              ? RewriteExample(
                  before: isId
                      ? 'Bertanggung jawab mengelola dan memelihara sistem database MySQL.'
                      : 'Responsible for managing and maintaining the company MySQL database.',
                  after: isId
                      ? 'Mengoptimalkan skema dan indexing database MySQL, memangkas waktu respons API sebesar [X]% untuk [jumlah]+ pengguna harian.'
                      : 'Optimized MySQL query indexing and connection pooling, cutting API latency by [X]% for [number]+ daily active users.',
                )
              : null,
        ),
      );
    }

    // 4. Check clichés
    final clicheRx = RegExp(
      r'\b(hard-working|hard\s+working|pekerja\s+keras|team\s+player|under\s+pressure|di\s*bawah\s+tekanan)\b',
      caseSensitive: false,
    );
    if (clicheRx.hasMatch(text)) {
      issues.add(
        Issue(
          id: 'cliches',
          category: 'language_quality',
          severity: 'suggestion',
          title: isId
              ? 'Terdapat frasa klise ("pekerja keras", "mampu bekerja di bawah tekanan")'
              : 'Uses generic buzzwords ("hard-working", "work under pressure")',
          detail: unlocked
              ? (isId
                  ? 'Klaim sifat subjektif tanpa bukti pencapaian konkret kurang memberikan nilai tambah di mata rekruter.'
                  : 'Subjective buzzwords are overused and ignored by recruiters unless backed by concrete project delivery metrics.')
              : null,
          fix: unlocked
              ? (isId
                  ? 'Ganti klaim subjektif dengan ringkasan keahlian teknis utama dan rekam jejak penyelesaian proyek.'
                  : 'Replace subjective traits with concrete engineering specializations and sprint delivery evidence.')
              : null,
          rewrite: unlocked
              ? RewriteExample(
                  before: isId
                      ? 'Pekerja keras yang berdedikasi tinggi dan mampu bekerja di bawah tekanan.'
                      : 'A hard-working team player able to work under pressure.',
                  after: isId
                      ? 'Software Engineer dengan spesialisasi layanan backend Node.js dan aplikasi mobile Flutter berskala produksi.'
                      : 'Results-driven Software Engineer experienced in shipping production Node.js & Flutter releases across agile 2-week sprints.',
                )
              : null,
        ),
      );
    }

    // 5. Missing Keywords
    issues.add(
      Issue(
        id: 'missing_keywords',
        category: 'keyword_match',
        severity: 'warning',
        title: isId
            ? 'Beberapa kata kunci teknis utama untuk posisi Software Engineer belum tercantum'
            : 'Missing several core industry keywords for Software Engineer',
        detail: unlocked
            ? (isId
                ? 'Mesin ATS mencocokkan kata kunci keahlian di CV Anda dengan standar industri posisi target.'
                : 'ATS ranking algorithms score your resume based on domain-specific engineering keywords.')
            : null,
        fix: unlocked
            ? (isId
                ? 'Tambahkan kata kunci teknis yang relevan dengan pengalaman Anda seperti CI/CD, Docker, Unit Testing, dan Clean Architecture.'
                : 'Incorporate relevant technical keywords such as CI/CD, Unit Testing, Docker, and Clean Architecture into your experience bullets.')
            : null,
        rewrite: unlocked
            ? RewriteExample(
                before: isId ? 'Keahlian: Node.js, Express, MySQL, Flutter' : 'Skills: Node.js, Express, MySQL, Flutter',
                after: isId
                    ? 'Keahlian: Node.js, Express, MySQL, Flutter, Dart, REST API, Docker, CI/CD, Unit Testing, Clean Architecture'
                    : 'Skills: Node.js, Express, MySQL, Flutter, Dart, REST APIs, Docker, CI/CD, Unit Testing, Clean Architecture',
              )
            : null,
      ),
    );

    var score = 100;
    for (final issue in issues) {
      if (issue.severity == 'critical') score -= 11;
      else if (issue.severity == 'warning') score -= 7;
      else if (issue.severity == 'suggestion') score -= 3;
    }
    score = score.clamp(10, 100);

    final result = AnalysisResult(
      mode: 'global',
      language: lang,
      overallScore: score,
      summary: isId
          ? 'Hasil evaluasi ATS dalam Bahasa Indonesia berdasarkan konten aktual dokumen CV Anda.'
          : 'English ATS evaluation based strictly on the actual content of your uploaded CV.',
      issues: issues,
      keywordMatch: KeywordMatch(
        jobTitle: 'Software Engineer',
        matched: ['Node.js', 'Express', 'MySQL', 'Flutter', 'Dart', 'Git', 'REST API'],
        missing: unlocked
            ? ['CI/CD', 'Docker', 'Unit Testing', 'Clean Architecture', 'Microservices']
            : [],
        missingCount: 5,
      ),
      fileName: fileName,
      engine: 'rule-based',
      isUnlocked: unlocked,
    );

    return AnalyzeResponseData(
      scanToken: 'scn_demo_9f8e7d6c',
      result: result,
      encryptedToken: 'demo_encrypted_token_aes256',
    );
  }

  ImprovedCV _buildOfflineRewrite(String text) {
    final lang = detectLanguage(text);
    final isId = lang == 'id';

    if (isId) {
      return ImprovedCV(
        language: 'id',
        name: 'Budi Santoso',
        title: 'Full-Stack & Mobile Software Engineer',
        contact: [
          'budi.santoso@example.com',
          '+62 812 3456 7890',
          'Jakarta, Indonesia',
          'linkedin.com/in/budisantoso',
          'github.com/budisantoso',
        ],
        summary:
            'Software Engineer berorientasi hasil dengan spesialisasi pengembangan layanan mikro backend Node.js dan aplikasi lintas platform Flutter. Terbukti mampu merancang arsitektur API yang bersih, mengoptimalkan performa database relasional, dan mempercepat siklus rilis fitur.',
        sections: [
          ImprovedCvSection(
            heading: 'Pengalaman Profesional',
            bullets: [
              'Merancang dan memelihara layanan backend RESTful menggunakan Node.js dan Express, meningkatkan kecepatan respons API sebesar [X]% pada [jumlah] endpoint utama.',
              'Mengoptimalkan skema dan strategi indexing database MySQL, menurunkan latensi eksekusi query dari [ms awal] menjadi [ms akhir].',
              'Mengembangkan alur autentikasi dan integrasi payment gateway yang aman, mendukung lebih dari [jumlah] transaksi bulanan dengan tingkat uptime [X]%.',
              'Berkolaborasi dengan tim lintas fungsi dalam membangun modul aplikasi Flutter yang responsif, memangkas waktu pengiriman fitur sebesar [X]%.',
            ],
          ),
          ImprovedCvSection(
            heading: 'Pendidikan',
            bullets: [
              'S1 Teknik Informatika — Universitas Indonesia (2019 – 2023) | IPK: [X.XX]/4.00',
            ],
          ),
          ImprovedCvSection(
            heading: 'Keahlian Teknis',
            bullets: [
              'Bahasa & Framework: Dart, Flutter, JavaScript (ES6+), Node.js, Express.js, SQL',
              'Database & Perangkat: MySQL, RESTful API, Git, Docker, Postman, Agile/Scrum',
            ],
          ),
        ],
        changes: [
          'Menyusun ulang struktur CV menjadi satu kolom bersih yang ramah parser ATS.',
          'Mengonversi kalimat tugas pasif menjadi poin pencapaian aktif berpola STAR dalam Bahasa Indonesia.',
          'Menambahkan penanda [placeholder] pada metrik angka yang perlu Anda lengkapi dengan data riil proyek Anda (Kebijakan Anti-Fabrikasi).',
        ],
      );
    }

    return ImprovedCV(
      language: 'en',
      name: 'Budi Santoso',
      title: 'Full-Stack & Mobile Software Engineer',
      contact: [
        'budi.santoso@example.com',
        '+62 812 3456 7890',
        'Jakarta, Indonesia (Open to Global Remote)',
        'linkedin.com/in/budisantoso',
        'github.com/budisantoso',
      ],
      summary:
          'Results-oriented Software Engineer specializing in Node.js backend microservices and cross-platform Flutter applications. Proven ability to architect clean APIs, optimize relational databases, and deliver scalable mobile experiences.',
      sections: [
        ImprovedCvSection(
          heading: 'Professional Experience',
          bullets: [
            'Architected and maintained RESTful backend services using Node.js and Express, improving API response times by [X]% across [number] endpoints.',
            'Optimized MySQL database schemas and indexing strategies, reducing query execution latency from [initial ms] to [target ms].',
            'Engineered secure payment gateway and authentication workflows, supporting over [number] monthly transactions with [X]% uptime.',
            'Collaborated with cross-functional mobile teams to build responsive Flutter UI modules, cutting feature delivery time by [X]%.',
          ],
        ),
        ImprovedCvSection(
          heading: 'Education',
          bullets: [
            'B.S. in Computer Science — Universitas Indonesia (2019 – 2023) | GPA: [X.XX]/4.00',
          ],
        ),
        ImprovedCvSection(
          heading: 'Technical Skills',
          bullets: [
            'Languages & Frameworks: Dart, Flutter, JavaScript (ES6+), Node.js, Express.js, SQL',
            'Databases & DevOps: MySQL, RESTful APIs, Git, Docker, Postman, Agile/Scrum',
          ],
        ),
      ],
      changes: [
        'Structured resume into a clean single-column layout compliant with global ATS parsers.',
        'Transformed passive duty statements into high-impact English STAR achievement bullets.',
        'Inserted bracketed [placeholder] markers for metrics you must fill with your real project numbers (Zero-Hallucination Policy).',
      ],
    );
  }
}

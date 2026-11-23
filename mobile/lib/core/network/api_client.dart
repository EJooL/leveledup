import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../../models/career_companion_model.dart';
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
  static const String _deviceIdPrefKey = 'leveledup_device_id';
  static String? _cachedDeviceId;

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

  /// Resolves a stable device-scoped identity persisted in SharedPreferences
  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null && _cachedDeviceId!.isNotEmpty) {
      return _cachedDeviceId!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString(_deviceIdPrefKey);
      if (existing != null && existing.trim().isNotEmpty) {
        _cachedDeviceId = existing.trim();
        return _cachedDeviceId!;
      }
      final generated = 'ag_dev_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(_deviceIdPrefKey, generated);
      _cachedDeviceId = generated;
      return generated;
    } catch (_) {
      _cachedDeviceId ??= 'ag_dev_fallback';
      return _cachedDeviceId!;
    }
  }

  /// Role-agnostic keyword catalog across diverse Indonesian fresh-graduate fields
  static const Map<String, List<String>> roleKeywordsCatalog = {
    'Software Engineer': [
      'Git',
      'CI/CD',
      'REST API',
      'Unit Testing',
      'System Architecture',
      'Docker',
      'Agile/Scrum',
      'Data Structures',
      'Microservices',
      'Code Review',
    ],
    'Mobile Developer': [
      'Flutter',
      'Dart',
      'Android',
      'iOS',
      'State Management',
      'REST API',
      'Git',
      'Firebase',
      'Clean Architecture',
      'Mobile UI/UX',
    ],
    'Data Analyst': [
      'SQL',
      'Python',
      'Tableau',
      'Power BI',
      'Data Cleaning',
      'Statistical Analysis',
      'Excel',
      'Data Visualization',
      'ETL',
      'Business Intelligence',
    ],
    'Digital Marketing Specialist': [
      'SEO',
      'SEM',
      'Google Analytics',
      'Meta Ads',
      'Content Strategy',
      'Copywriting',
      'Conversion Rate Optimization',
      'Social Media Marketing',
      'Email Marketing',
      'Campaign Analytics',
    ],
    'Accounting & Finance Associate': [
      'Financial Reporting',
      'General Ledger',
      'Tax Compliance',
      'Account Reconciliation',
      'Budgeting',
      'SAP / Accurate',
      'Auditing',
      'Financial Modeling',
      'Cost Analysis',
      'Excel Pivot / VLOOKUP',
    ],
    'UI/UX Designer': [
      'Figma',
      'User Research',
      'Wireframing',
      'Prototyping',
      'Design Systems',
      'Usability Testing',
      'Information Architecture',
      'Interaction Design',
      'Accessibility',
      'User Journey',
    ],
    'Product Manager': [
      'User Research',
      'Product Roadmap',
      'A/B Testing',
      'Agile/Scrum',
      'KPI Tracking',
      'Wireframing',
      'Stakeholder Management',
      'Sprint Planning',
      'Data Analytics',
      'PRD',
    ],
    'Human Resources & People Ops': [
      'Talent Acquisition',
      'End-to-End Recruitment',
      'Onboarding',
      'Employee Relations',
      'HRIS',
      'Performance Appraisal',
      'Employer Branding',
      'Training & Development',
      'Labor Law Compliance',
      'Behavioral Interviewing',
    ],
  };

  /// Build role-agnostic, bilingual ('id' or 'en') Skill Gap actions from scan data
  static SkillGapReport buildSkillGapReport({
    required String jobTitle,
    required List<String> missingKeywords,
    required List<String> matchedKeywords,
    String language = 'en',
  }) {
    final isId = language == 'id';
    final role = jobTitle.trim().isEmpty ? 'Professional' : jobTitle.trim();
    final catalog =
        roleKeywordsCatalog[role] ?? roleKeywordsCatalog['Software Engineer']!;
    final effectiveMissing = missingKeywords.isNotEmpty
        ? missingKeywords
        : catalog.where((k) => !matchedKeywords.contains(k)).take(5).toList();

    final gaps = <SkillGapItem>[];
    for (var i = 0; i < effectiveMissing.length; i++) {
      final kw = effectiveMissing[i];
      final modeIndex = i % 3;
      late final String actionType;
      late final String actionTitle;
      late final String concreteAction;
      late final String sampleBullet;

      if (modeIndex == 0) {
        actionType = 'experience_bullet';
        actionTitle = isId
            ? 'Tunjukkan bukti penggunaan $kw pada pengalaman/magang'
            : 'Reframe an internship or work bullet to highlight $kw';
        concreteAction = isId
            ? 'Jika Anda pernah menggunakan $kw saat kuliah, magang, atau proyek tim, sebutkan nama kompetensinya secara eksplisit di bagian Pengalaman.'
            : 'If you used $kw during an internship, thesis, or team project, name "$kw" explicitly inside an experience bullet so ATS parsers match it.';
        sampleBullet = isId
            ? 'Menerapkan $kw untuk mengoptimalkan alur kerja [nama proyek/divisi], meningkatkan akurasi dan efisiensi proses sebesar [X]%.'
            : 'Applied $kw across [project or department workflow], improving operational accuracy and delivery speed by [X]%.';
      } else if (modeIndex == 1) {
        actionType = 'portfolio_project';
        actionTitle = isId
            ? 'Buat 1 studi kasus atau proyek mini berbasis $kw'
            : 'Add a mini project or case study demonstrating $kw';
        concreteAction = isId
            ? 'Tambahkan 1 poin proyek portofolio (tugas akhir, studi kasus bisnis, atau eksperimen mandiri) yang menggunakan $kw beserta dampaknya.'
            : 'Add a capstone, coursework, or self-initiated case study entry where $kw was used to solve a concrete problem.';
        sampleBullet = isId
            ? 'Merancang studi kasus $role menggunakan $kw untuk menganalisis [jumlah] sampel data/skenario dan menghasilkan rekomendasi dengan dampak [X]%.'
            : 'Designed a $role case study leveraging $kw across [number] test scenarios, achieving a [X]% improvement in [target metric].';
      } else {
        actionType = 'skills_section';
        actionTitle = isId
            ? 'Cantumkan $kw pada bagian Keahlian & Perangkat'
            : 'List $kw in your Skills & Competencies section';
        concreteAction = isId
            ? 'Kelompokkan $kw bersama keahlian utama Anda di bagian Keahlian/Kompetensi agar lolos filter kata kunci tahap awal.'
            : 'Group $kw alongside your existing competencies (${matchedKeywords.take(2).join(', ').isEmpty ? role : matchedKeywords.take(2).join(', ')}) in your Skills section.';
        final combined = [...matchedKeywords.take(3), kw].join(', ');
        sampleBullet = isId
            ? 'Kompetensi & Perangkat: $combined'
            : 'Core Competencies & Tools: $combined';
      }

      gaps.add(
        SkillGapItem(
          keyword: kw,
          role: role,
          actionType: actionType,
          actionTitle: actionTitle,
          concreteAction: concreteAction,
          sampleBullet: sampleBullet,
        ),
      );
    }

    return SkillGapReport(
      jobTitle: role,
      language: isId ? 'id' : 'en',
      matchedKeywords: matchedKeywords,
      missingKeywords: effectiveMissing,
      gaps: gaps,
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
      RegExp(r'\bmeningkatkan\b'),
      RegExp(r'\bkampanye\b'),
      RegExp(r'\blaporan\b'),
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
      final deviceId = await getDeviceId();
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
        options: Options(headers: {'x-device-id': deviceId}),
      );

      final data = response.data as Map<String, dynamic>;
      return ParseResponseData(
        fileName: data['fileName']?.toString() ?? fileName,
        numPages:
            (data['numPages'] is num) ? (data['numPages'] as num).toInt() : 1,
        numChars:
            (data['numChars'] is num) ? (data['numChars'] as num).toInt() : 0,
        hasPhoto: data['hasPhoto'] == true,
        text: data['text']?.toString() ?? '',
      );
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        final msg = (e.response?.data as Map)['error']?.toString() ??
            'Failed to parse PDF.';
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
    String? deviceId,
  }) async {
    final resolvedDeviceId = deviceId ?? await getDeviceId();
    try {
      final response = await _dio.post(
        ApiConstants.analyzeEndpoint,
        data: {
          'text': text,
          'fileName': fileName,
          'hasPhoto': hasPhoto,
          'deviceId': resolvedDeviceId,
        },
        options: Options(headers: {'x-device-id': resolvedDeviceId}),
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
        final msg = (e.response?.data as Map)['error']?.toString() ??
            'Failed to analyze CV.';
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
      final deviceId = await getDeviceId();
      final response = await _dio.post(
        ApiConstants.unlockEndpoint,
        data: {
          'scanToken': scanToken,
          'token': encryptedToken,
          'code': accessCode.trim().toUpperCase(),
        },
        options: Options(headers: {'x-device-id': deviceId}),
      );

      final data = response.data as Map<String, dynamic>;
      data['language'] = data['language'] ?? detectLanguage(currentText);
      return AnalysisResult.fromJson(data, unlocked: true);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        final msg = (e.response?.data as Map)['error']?.toString() ??
            'Invalid access code.';
        throw Exception(msg);
      }
      if (accessCode.trim().toUpperCase() != ApiConstants.defaultVipCode) {
        throw Exception(
          'Invalid access code. Try ${ApiConstants.defaultVipCode} for MVP testing.',
        );
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
      final deviceId = await getDeviceId();
      final response = await _dio.post(
        ApiConstants.rewriteEndpoint,
        data: {
          'scanToken': scanToken,
          'text': text,
          'code': accessCode.trim().toUpperCase(),
          'fileName': fileName,
        },
        options: Options(headers: {'x-device-id': deviceId}),
      );

      final data = response.data as Map<String, dynamic>;
      final cvJson = data['cv'] as Map<String, dynamic>;
      cvJson['language'] = cvJson['language'] ?? detectLanguage(text);
      return ImprovedCV.fromJson(cvJson);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        final msg = (e.response?.data as Map)['error']?.toString() ??
            'Failed to rewrite CV.';
        throw Exception(msg);
      }
      return _buildOfflineRewrite(text);
    }
  }

  /// 5. GET /api/wins — Fetch persisted Brag Doc wins & 90-day reminder status
  Future<Map<String, dynamic>?> fetchWins({bool simulateReminder = false}) async {
    try {
      final deviceId = await getDeviceId();
      final response = await _dio.get(
        ApiConstants.winsEndpoint,
        queryParameters: {
          'deviceId': deviceId,
          if (simulateReminder) 'simulateReminder': 'true',
        },
        options: Options(headers: {'x-device-id': deviceId}),
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 6. POST /api/wins — Log a work win & generate Zero-Hallucination STAR bullet
  Future<Map<String, dynamic>?> createWorkWin({
    required String title,
    required String impactMetric,
    required String category,
    String? language,
  }) async {
    try {
      final deviceId = await getDeviceId();
      final response = await _dio.post(
        ApiConstants.winsEndpoint,
        data: {
          'deviceId': deviceId,
          'title': title,
          'impactMetric': impactMetric,
          'category': category,
          if (language != null) 'language': language,
        },
        options: Options(headers: {'x-device-id': deviceId}),
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 7. POST /api/wins/merge-cv — Merge selected wins into living CV
  Future<ImprovedCV> mergeWinsIntoCv({
    required List<WorkWin> winsToMerge,
    String? scanToken,
    ImprovedCV? baseCv,
  }) async {
    final lang = baseCv?.language ??
        (winsToMerge.isNotEmpty ? winsToMerge.first.language : 'en');
    try {
      final deviceId = await getDeviceId();
      final response = await _dio.post(
        ApiConstants.mergeWinsCvEndpoint,
        data: {
          'deviceId': deviceId,
          'winIds': winsToMerge.map((w) => w.id).toList(),
          'winBullets': winsToMerge
              .map(
                (w) => {
                  'id': w.id,
                  'title': w.title,
                  'starBullet': w.toStarBullet(),
                  'language': w.language,
                },
              )
              .toList(),
          'scanToken': scanToken,
          'language': lang,
          if (baseCv != null)
            'cv': {
              'language': baseCv.language,
              'name': baseCv.name,
              'title': baseCv.title,
              'contact': baseCv.contact,
              'summary': baseCv.summary,
              'sections': baseCv.sections.map((s) => s.toJson()).toList(),
              'changes': baseCv.changes,
            },
        },
        options: Options(headers: {'x-device-id': deviceId}),
      );

      final data = response.data as Map<String, dynamic>;
      final cvJson = data['cv'] as Map<String, dynamic>;
      return ImprovedCV.fromJson(cvJson);
    } catch (_) {
      return mergeWinsLocally(
        baseCv: baseCv ?? _buildOfflineRewrite(ApiConstants.sampleCvText),
        winsToMerge: winsToMerge,
      );
    }
  }

  /// Local deterministic living-CV merger (fallback if offline)
  static ImprovedCV mergeWinsLocally({
    required ImprovedCV baseCv,
    required List<WorkWin> winsToMerge,
  }) {
    final isId = baseCv.isIndonesian;
    final sections = baseCv.sections
        .map(
          (s) => ImprovedCvSection(
            heading: s.heading,
            type: s.type,
            entries: s.entries
                .map(
                  (e) => ImprovedCvEntry(
                    title: e.title,
                    date: e.date,
                    subtitle: e.subtitle,
                    bullets: List<String>.from(e.bullets),
                  ),
                )
                .toList(),
            skillGroups: s.skillGroups
                .map(
                  (g) => ImprovedCvSkillGroup(
                    category: g.category,
                    items: g.items,
                  ),
                )
                .toList(),
            bullets: List<String>.from(s.bullets),
          ),
        )
        .toList();

    if (sections.isEmpty) {
      sections.add(
        ImprovedCvSection(
          heading: isId ? 'Pengalaman' : 'Experience',
          type: 'experience',
          entries: [
            ImprovedCvEntry(
              title: isId
                  ? 'Pengalaman & Pencapaian Terbaru'
                  : 'Recent Experience & Achievements',
              date: isId ? 'Sekarang' : 'Present',
              bullets: const [],
            ),
          ],
          bullets: [],
        ),
      );
    }

    final expIdx = sections.indexWhere(
      (s) =>
          s.type == 'experience' ||
          RegExp(
            r'pengalaman|experience|work|kerja',
            caseSensitive: false,
          ).hasMatch(s.heading),
    );
    final projIdx = sections.indexWhere(
      (s) =>
          s.type == 'projects' ||
          RegExp(r'proyek|project', caseSensitive: false).hasMatch(s.heading),
    );
    final targetIdx = expIdx != -1 ? expIdx : (projIdx != -1 ? projIdx : 0);

    final targetSection = sections[targetIdx];
    final existing = targetSection.bullets;
    final added = <String>[];
    for (final w in winsToMerge) {
      final b = w.toStarBullet().trim();
      if (b.isNotEmpty && !existing.contains(b) && !added.contains(b)) {
        added.add(b);
      }
    }

    final updatedEntries = List<ImprovedCvEntry>.from(targetSection.entries);
    if (added.isNotEmpty && updatedEntries.isNotEmpty) {
      final first = updatedEntries.first;
      final uniqueForEntry =
          added.where((b) => !first.bullets.contains(b)).toList();
      updatedEntries[0] = ImprovedCvEntry(
        title: first.title,
        date: first.date,
        subtitle: first.subtitle,
        bullets: [...uniqueForEntry, ...first.bullets],
      );
    }

    sections[targetIdx] = ImprovedCvSection(
      heading: targetSection.heading,
      type: targetSection.type,
      entries: updatedEntries,
      skillGroups: targetSection.skillGroups,
      bullets: [...added, ...existing],
    );

    final updatedChanges = List<String>.from(baseCv.changes);
    if (added.isNotEmpty) {
      final note = isId
          ? 'Mengintegrasikan ${added.length} pencapaian baru dari Brag Doc (Log Win) ke bagian ${sections[targetIdx].heading}.'
          : 'Merged ${added.length} verified Brag Doc win(s) into the ${sections[targetIdx].heading} section.';
      if (!updatedChanges.contains(note)) {
        updatedChanges.insert(0, note);
      }
    }

    return ImprovedCV(
      language: baseCv.language,
      name: baseCv.name,
      title: baseCv.title,
      contact: baseCv.contact,
      summary: baseCv.summary,
      sections: sections,
      changes: updatedChanges,
    );
  }

  /// 8. GET /api/progress — Fetch score history, scan-verified quests, and Skill Gap
  Future<Map<String, dynamic>?> fetchProgress() async {
    try {
      final deviceId = await getDeviceId();
      final response = await _dio.get(
        ApiConstants.progressEndpoint,
        queryParameters: {'deviceId': deviceId},
        options: Options(headers: {'x-device-id': deviceId}),
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 9. POST /api/progress/quest-toggle — Toggle self-reported quest in MySQL
  Future<Map<String, dynamic>?> toggleSelfReportedQuest(String questKey) async {
    try {
      final deviceId = await getDeviceId();
      final response = await _dio.post(
        ApiConstants.questToggleEndpoint,
        data: {
          'deviceId': deviceId,
          'questKey': questKey,
        },
        options: Options(headers: {'x-device-id': deviceId}),
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 10. POST /api/progress/mode — Switch career mode ('job_hunt' or 'hired')
  Future<Map<String, dynamic>?> switchCareerMode({
    required String mode,
    String? displayName,
    String? targetRole,
  }) async {
    try {
      final deviceId = await getDeviceId();
      final response = await _dio.post(
        ApiConstants.careerModeEndpoint,
        data: {
          'deviceId': deviceId,
          'mode': mode,
          if (displayName != null) 'displayName': displayName,
          if (targetRole != null) 'targetRole': targetRole,
        },
        options: Options(headers: {'x-device-id': deviceId}),
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Infer role across diverse fields (Data, Marketing, Finance, Design, HR, Engineering)
  static String inferRoleFromText(String text) {
    final lower = text.toLowerCase();
    var bestRole = 'Software Engineer';
    var bestScore = 0;

    roleKeywordsCatalog.forEach((role, keywords) {
      var score = 0;
      if (lower.contains(role.toLowerCase())) score += 5;
      for (final kw in keywords) {
        if (lower.contains(kw.toLowerCase())) score += 1;
      }
      if (score > bestScore) {
        bestScore = score;
        bestRole = role;
      }
    });

    return bestRole;
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
                  before: isId
                      ? '[Pas Foto 4x6 di sudut atas CV]'
                      : '[Headshot Photo in Top Corner]',
                  after:
                      'Budi Santoso • Jakarta, Indonesia • linkedin.com/in/budisantoso • github.com/budisantoso',
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
          id: 'dob_age',
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

    // 4. Check quantifiable metrics
    final hasNumbersRx = RegExp(
      r'\b\d+(\.\d+)?%|\b\d+\+?\s*(users|clients|proyek|projects|pengguna|klien|leads|reports|transaksi)\b',
      caseSensitive: false,
    );
    if (!hasNumbersRx.hasMatch(text)) {
      issues.add(
        Issue(
          id: 'no_metrics',
          category: 'achievements',
          severity: 'warning',
          title: isId
              ? 'Minim metrik angka dan hasil terukur (quantified impact)'
              : 'Lacks quantifiable metrics and measurable outcomes',
          detail: unlocked
              ? (isId
                  ? 'Tanpa persentase peningkatan, efisiensi waktu, atau skala pengguna, rekruter sulit menilai skala kontribusi Anda.'
                  : 'Without percentages, time saved, or scale metrics, recruiters cannot gauge the magnitude of your work.')
              : null,
          fix: unlocked
              ? (isId
                  ? 'Sertakan angka konkret atau gunakan penanda [X]% pada minimal 3 poin pencapaian utama Anda.'
                  : 'Include concrete metrics (e.g., [X]% faster, [number] users impacted) in at least 3 bullets.')
              : null,
          rewrite: unlocked
              ? RewriteExample(
                  before: isId
                      ? 'Meningkatkan performa aplikasi dan alur kerja tim.'
                      : 'Improved application performance and team workflow.',
                  after: isId
                      ? 'Mempercepat waktu proses sebesar [X]% dan meningkatkan kualitas hasil hingga [X]%.'
                      : 'Accelerated workflow execution by [X]% and improved deliverable accuracy by [X]%.',
                )
              : null,
        ),
      );
    }

    // 5. Check clichés
    final clicheRx = RegExp(
      r'\b(hard-working|hard\s+working|pekerja\s+keras|team\s+player|under\s+pressure|di\s*bawah\s+tekanan)\b',
      caseSensitive: false,
    );
    if (clicheRx.hasMatch(text)) {
      issues.add(
        Issue(
          id: 'cliche_words',
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
                  ? 'Ganti klaim subjektif dengan ringkasan keahlian utama dan rekam jejak penyelesaian proyek.'
                  : 'Replace subjective traits with concrete domain specializations and project delivery evidence.')
              : null,
          rewrite: unlocked
              ? RewriteExample(
                  before: isId
                      ? 'Pekerja keras yang berdedikasi tinggi dan mampu bekerja di bawah tekanan.'
                      : 'A hard-working team player able to work under pressure.',
                  after: isId
                      ? 'Profesional berorientasi hasil dengan rekam jejak pengiriman proyek tepat waktu dan peningkatan metrik kerja sebesar [X]%.'
                      : 'Results-driven professional experienced in shipping high-impact deliverables with [X]% efficiency gains.',
                )
              : null,
        ),
      );
    }

    // 6. Role-agnostic Keyword Matching
    final detectedRole = inferRoleFromText(text);
    final roleKws = roleKeywordsCatalog[detectedRole] ??
        roleKeywordsCatalog['Software Engineer']!;
    final lowerText = text.toLowerCase();
    final matchedKws = <String>[];
    final missingKws = <String>[];
    for (final kw in roleKws) {
      if (lowerText.contains(kw.toLowerCase())) {
        matchedKws.add(kw);
      } else {
        missingKws.add(kw);
      }
    }

    if (missingKws.length >= 4) {
      issues.add(
        Issue(
          id: 'missing_core_keywords',
          category: 'keyword_match',
          severity: 'warning',
          title: isId
              ? 'Beberapa kata kunci utama untuk posisi $detectedRole belum tercantum'
              : 'Missing several core industry keywords for $detectedRole',
          detail: unlocked
              ? (isId
                  ? 'Mesin ATS mencocokkan kata kunci keahlian di CV Anda dengan standar industri posisi $detectedRole.'
                  : 'ATS ranking algorithms score your resume based on domain-specific keywords for $detectedRole.')
              : null,
          fix: unlocked
              ? (isId
                  ? 'Tambahkan kata kunci relevan yang Anda kuasai seperti ${missingKws.take(3).join(', ')}.'
                  : 'Incorporate relevant keywords you possess such as ${missingKws.take(3).join(', ')} into your bullets.')
              : null,
          rewrite: unlocked
              ? RewriteExample(
                  before: isId
                      ? 'Keahlian: ${matchedKws.take(3).join(', ')}'
                      : 'Skills: ${matchedKws.take(3).join(', ')}',
                  after: isId
                      ? 'Keahlian: ${[...matchedKws.take(4), ...missingKws.take(3)].join(', ')}'
                      : 'Skills: ${[...matchedKws.take(4), ...missingKws.take(3)].join(', ')}',
                )
              : null,
        ),
      );
    }

    var score = 100;
    for (final issue in issues) {
      if (issue.severity == 'critical') {
        score -= 11;
      } else if (issue.severity == 'warning') {
        score -= 7;
      } else if (issue.severity == 'suggestion') {
        score -= 3;
      }
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
        jobTitle: detectedRole,
        matched: matchedKws,
        missing: unlocked ? missingKws : const [],
        missingCount: missingKws.length,
      ),
      fileName: fileName,
      engine: 'rule-based',
      isUnlocked: unlocked,
    );

    return AnalyzeResponseData(
      scanToken: 'scn_local_${DateTime.now().millisecondsSinceEpoch}',
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
        title: 'Software Engineer | Node.js · Flutter · MySQL · REST API · Docker',
        contact: [
          'budi.santoso@example.com',
          'linkedin.com/in/budisantoso',
          'github.com/budisantoso',
          'Jakarta, Indonesia',
        ],
        summary:
            'Software Engineer berorientasi hasil dengan spesialisasi pengembangan layanan mikro backend Node.js dan aplikasi lintas platform Flutter. Terbukti mampu merancang arsitektur API yang bersih, mengoptimalkan performa database relasional, dan mempercepat siklus rilis fitur.',
        sections: [
          ImprovedCvSection(
            heading: 'Pendidikan',
            type: 'education',
            entries: [
              ImprovedCvEntry(
                title: 'Universitas Indonesia',
                date: '2019 – 2023',
                bullets: [
                  'S1 Teknik Informatika | IPK [X.XX] / 4.00',
                ],
              ),
            ],
            bullets: [
              'S1 Teknik Informatika | IPK [X.XX] / 4.00',
            ],
          ),
          ImprovedCvSection(
            heading: 'Pengalaman',
            type: 'experience',
            entries: [
              ImprovedCvEntry(
                title: 'Software Engineer — PT Solusi Teknologi Indonesia',
                date: 'Jan 2023 – Sekarang',
                subtitle: 'Backend & Mobile Engineering · Jakarta',
                bullets: [
                  'Merancang dan memelihara layanan backend RESTful menggunakan Node.js dan Express, meningkatkan kecepatan respons API sebesar [X]% pada [jumlah] endpoint utama.',
                  'Mengoptimalkan skema dan strategi indexing database MySQL, menurunkan latensi eksekusi query dari [ms awal] menjadi [ms akhir].',
                  'Mengembangkan alur autentikasi dan integrasi payment gateway yang aman, mendukung lebih dari [jumlah] transaksi bulanan dengan tingkat uptime [X]%.',
                  'Berkolaborasi dengan tim lintas fungsi dalam membangun modul aplikasi Flutter yang responsif, memangkas waktu pengiriman fitur sebesar [X]%.',
                ],
              ),
            ],
            bullets: [
              'Merancang dan memelihara layanan backend RESTful menggunakan Node.js dan Express, meningkatkan kecepatan respons API sebesar [X]% pada [jumlah] endpoint utama.',
              'Mengoptimalkan skema dan strategi indexing database MySQL, menurunkan latensi eksekusi query dari [ms awal] menjadi [ms akhir].',
              'Mengembangkan alur autentikasi dan integrasi payment gateway yang aman, mendukung lebih dari [jumlah] transaksi bulanan dengan tingkat uptime [X]%.',
              'Berkolaborasi dengan tim lintas fungsi dalam membangun modul aplikasi Flutter yang responsif, memangkas waktu pengiriman fitur sebesar [X]%.',
            ],
          ),
          ImprovedCvSection(
            heading: 'Keahlian',
            type: 'skills',
            skillGroups: [
              ImprovedCvSkillGroup(
                category: 'Bahasa & Framework',
                items: 'Dart, Flutter, JavaScript (ES6+), Node.js, Express.js, SQL',
              ),
              ImprovedCvSkillGroup(
                category: 'Database & Perangkat',
                items: 'MySQL, RESTful API, Git, Docker, Postman, Agile/Scrum',
              ),
            ],
            bullets: [
              'Bahasa & Framework: Dart, Flutter, JavaScript (ES6+), Node.js, Express.js, SQL',
              'Database & Perangkat: MySQL, RESTful API, Git, Docker, Postman, Agile/Scrum',
            ],
          ),
        ],
        changes: [
          'Menyusun ulang struktur CV mengikuti format referensi ATS modern siap unduh sebagai Word (.docx).',
          'Mengonversi kalimat tugas pasif menjadi poin pencapaian aktif berpola STAR dalam Bahasa Indonesia.',
          'Menambahkan penanda [placeholder] pada metrik angka yang perlu Anda lengkapi dengan data riil proyek Anda (Kebijakan Anti-Fabrikasi).',
        ],
      );
    }

    return ImprovedCV(
      language: 'en',
      name: 'Budi Santoso',
      title: 'Software Engineer | Node.js · Flutter · MySQL · REST API · Docker',
      contact: [
        'budi.santoso@example.com',
        'linkedin.com/in/budisantoso',
        'github.com/budisantoso',
        'Jakarta, Indonesia',
      ],
      summary:
          'Results-oriented Software Engineer specializing in Node.js backend microservices and cross-platform Flutter applications. Proven ability to architect clean APIs, optimize relational databases, and deliver scalable mobile experiences.',
      sections: [
        ImprovedCvSection(
          heading: 'Education',
          type: 'education',
          entries: [
            ImprovedCvEntry(
              title: 'Universitas Indonesia',
              date: '2019 – 2023',
              bullets: [
                'B.S. in Computer Science | GPA [X.XX] / 4.00',
              ],
            ),
          ],
          bullets: [
            'B.S. in Computer Science | GPA [X.XX] / 4.00',
          ],
        ),
        ImprovedCvSection(
          heading: 'Experience',
          type: 'experience',
          entries: [
            ImprovedCvEntry(
              title: 'Software Engineer — PT Solusi Teknologi Indonesia',
              date: 'Jan 2023 – Present',
              subtitle: 'Backend & Mobile Engineering · Jakarta',
              bullets: [
                'Architected and maintained RESTful backend services using Node.js and Express, improving API response times by [X]% across [number] endpoints.',
                'Optimized MySQL database schemas and indexing strategies, reducing query execution latency from [initial ms] to [target ms].',
                'Engineered secure payment gateway and authentication workflows, supporting over [number] monthly transactions with [X]% uptime.',
                'Collaborated with cross-functional mobile teams to build responsive Flutter UI modules, cutting feature delivery time by [X]%.',
              ],
            ),
          ],
          bullets: [
            'Architected and maintained RESTful backend services using Node.js and Express, improving API response times by [X]% across [number] endpoints.',
            'Optimized MySQL database schemas and indexing strategies, reducing query execution latency from [initial ms] to [target ms].',
            'Engineered secure payment gateway and authentication workflows, supporting over [number] monthly transactions with [X]% uptime.',
            'Collaborated with cross-functional mobile teams to build responsive Flutter UI modules, cutting feature delivery time by [X]%.',
          ],
        ),
        ImprovedCvSection(
          heading: 'Skills',
          type: 'skills',
          skillGroups: [
            ImprovedCvSkillGroup(
              category: 'Languages & Frameworks',
              items: 'Dart, Flutter, JavaScript (ES6+), Node.js, Express.js, SQL',
            ),
            ImprovedCvSkillGroup(
              category: 'Databases & DevOps',
              items: 'MySQL, RESTful APIs, Git, Docker, Postman, Agile/Scrum',
            ),
          ],
          bullets: [
            'Languages & Frameworks: Dart, Flutter, JavaScript (ES6+), Node.js, Express.js, SQL',
            'Databases & DevOps: MySQL, RESTful APIs, Git, Docker, Postman, Agile/Scrum',
          ],
        ),
      ],
      changes: [
        'Structured resume into the modern ATS reference layout ready for direct Word (.docx) export.',
        'Transformed passive duty statements into high-impact English STAR achievement bullets.',
        'Inserted bracketed [placeholder] markers for metrics you must fill with your real project numbers (Zero-Hallucination Policy).',
      ],
    );
  }
}

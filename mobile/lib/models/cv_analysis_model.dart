class RewriteExample {
  final String before;
  final String after;

  RewriteExample({required this.before, required this.after});

  factory RewriteExample.fromJson(Map<String, dynamic> json) {
    return RewriteExample(
      before: json['before']?.toString() ?? '',
      after: json['after']?.toString() ?? '',
    );
  }
}

class Issue {
  final String id;
  final String category;
  final String severity;
  final String title;
  final String? detail;
  final String? fix;
  final RewriteExample? rewrite;

  Issue({
    required this.id,
    required this.category,
    required this.severity,
    required this.title,
    this.detail,
    this.fix,
    this.rewrite,
  });

  bool get isLocked => detail == null || detail!.isEmpty;

  String get categoryLabel {
    switch (category) {
      case 'personal_info':
        return 'Personal Info Bias';
      case 'ats_readability':
        return 'ATS Readability';
      case 'keyword_match':
        return 'Keyword Match';
      case 'achievements':
        return 'Quantified Impact';
      case 'language_quality':
        return 'Language Quality';
      default:
        return category;
    }
  }

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? 'personal_info',
      severity: json['severity']?.toString() ?? 'warning',
      title: json['title']?.toString() ?? '',
      detail: json['detail']?.toString(),
      fix: json['fix']?.toString(),
      rewrite: json['rewrite'] != null && json['rewrite'] is Map<String, dynamic>
          ? RewriteExample.fromJson(json['rewrite'] as Map<String, dynamic>)
          : null,
    );
  }
}

class KeywordMatch {
  final String? jobTitle;
  final List<String> matched;
  final List<String> missing;
  final int missingCount;

  KeywordMatch({
    this.jobTitle,
    required this.matched,
    required this.missing,
    required this.missingCount,
  });

  factory KeywordMatch.fromJson(Map<String, dynamic> json) {
    final missingList = List<String>.from(json['missing'] ?? []);
    final count = json['missingCount'] is int
        ? json['missingCount'] as int
        : missingList.length;

    return KeywordMatch(
      jobTitle: json['jobTitle']?.toString(),
      matched: List<String>.from(json['matched'] ?? []),
      missing: missingList,
      missingCount: count,
    );
  }
}

class AnalysisResult {
  final String mode;
  final String language;
  final int overallScore;
  final String summary;
  final List<Issue> issues;
  final KeywordMatch? keywordMatch;
  final String fileName;
  final String engine;
  final bool isUnlocked;

  AnalysisResult({
    required this.mode,
    this.language = 'en',
    required this.overallScore,
    required this.summary,
    required this.issues,
    this.keywordMatch,
    required this.fileName,
    required this.engine,
    this.isUnlocked = false,
  });

  bool get isIndonesian => language == 'id';

  factory AnalysisResult.fromJson(Map<String, dynamic> json, {bool unlocked = false}) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final parsedIssues = (json['issues'] as List<dynamic>? ?? [])
        .map((item) => Issue.fromJson(item as Map<String, dynamic>))
        .toList();

    final hasUnlockedDetails = unlocked || parsedIssues.any((i) => !i.isLocked);
    final lang = json['language']?.toString() ?? meta['language']?.toString() ?? 'en';

    return AnalysisResult(
      mode: json['mode']?.toString() ?? 'global',
      language: lang,
      overallScore: (json['overallScore'] is num) ? (json['overallScore'] as num).toInt() : 0,
      summary: json['summary']?.toString() ?? '',
      issues: parsedIssues,
      keywordMatch: json['keywordMatch'] != null && json['keywordMatch'] is Map<String, dynamic>
          ? KeywordMatch.fromJson(json['keywordMatch'] as Map<String, dynamic>)
          : null,
      fileName: meta['fileName']?.toString() ?? 'CV.pdf',
      engine: meta['engine']?.toString() ?? 'rule-based',
      isUnlocked: hasUnlockedDetails,
    );
  }
}

class ImprovedCvEntry {
  final String title;
  final String date;
  final String subtitle;
  final List<String> bullets;

  ImprovedCvEntry({
    required this.title,
    this.date = '',
    this.subtitle = '',
    this.bullets = const [],
  });

  factory ImprovedCvEntry.fromJson(Map<String, dynamic> json) {
    return ImprovedCvEntry(
      title: json['title']?.toString().trim() ?? '',
      date: json['date']?.toString().trim() ?? '',
      subtitle: json['subtitle']?.toString().trim() ?? '',
      bullets: List<String>.from(json['bullets'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'date': date,
        'subtitle': subtitle,
        'bullets': bullets,
      };
}

class ImprovedCvSkillGroup {
  final String category;
  final String items;

  ImprovedCvSkillGroup({
    required this.category,
    required this.items,
  });

  factory ImprovedCvSkillGroup.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final itemsStr = rawItems is List
        ? rawItems.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).join(', ')
        : (rawItems?.toString().trim() ?? '');
    return ImprovedCvSkillGroup(
      category: json['category']?.toString().trim() ?? '',
      items: itemsStr,
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'items': items,
      };
}

class ImprovedCvSection {
  final String heading;
  final String type;
  final List<ImprovedCvEntry> entries;
  final List<ImprovedCvSkillGroup> skillGroups;
  final List<String> bullets;

  ImprovedCvSection({
    required this.heading,
    this.type = 'generic',
    this.entries = const [],
    this.skillGroups = const [],
    required this.bullets,
  });

  static String inferType(String? rawType, String heading) {
    final explicit = (rawType ?? '').trim().toLowerCase();
    const valid = {
      'education',
      'projects',
      'experience',
      'skills',
      'certifications',
      'generic',
    };
    if (valid.contains(explicit)) return explicit;

    final h = heading.trim().toLowerCase();
    if (RegExp(r'pendidikan|education|academic|akademik').hasMatch(h)) {
      return 'education';
    }
    if (RegExp(r'proyek|project|portfolio|portofolio').hasMatch(h)) {
      return 'projects';
    }
    if (RegExp(r'pengalaman|experience|work|kerja|magang|internship|organisasi|employment').hasMatch(h)) {
      return 'experience';
    }
    if (RegExp(r'keahlian|kemampuan|keterampilan|skill|kompetensi|competenc|tools|tech').hasMatch(h)) {
      return 'skills';
    }
    if (RegExp(r'sertifikasi|certif|lisensi|license|kursus|course|penghargaan|award|pelatihan|training').hasMatch(h)) {
      return 'certifications';
    }
    return 'generic';
  }

  factory ImprovedCvSection.fromJson(Map<String, dynamic> json) {
    final heading = json['heading']?.toString() ?? '';
    final type = inferType(json['type']?.toString(), heading);
    final entries = (json['entries'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ImprovedCvEntry.fromJson)
        .toList();
    final skillGroups = (json['skillGroups'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ImprovedCvSkillGroup.fromJson)
        .toList();
    final bullets = List<String>.from(json['bullets'] ?? []);

    return ImprovedCvSection(
      heading: heading,
      type: type,
      entries: entries,
      skillGroups: skillGroups,
      bullets: bullets,
    );
  }

  Map<String, dynamic> toJson() => {
        'heading': heading,
        'type': type,
        if (entries.isNotEmpty)
          'entries': entries.map((e) => e.toJson()).toList(),
        if (skillGroups.isNotEmpty)
          'skillGroups': skillGroups.map((g) => g.toJson()).toList(),
        'bullets': bullets,
      };
}

class ImprovedCV {
  final String language;
  final String name;
  final String title;
  final List<String> contact;
  final String summary;
  final List<ImprovedCvSection> sections;
  final List<String> changes;

  ImprovedCV({
    this.language = 'en',
    required this.name,
    required this.title,
    required this.contact,
    required this.summary,
    required this.sections,
    required this.changes,
  });

  bool get isIndonesian => language == 'id';

  factory ImprovedCV.fromJson(Map<String, dynamic> json) {
    return ImprovedCV(
      language: json['language']?.toString() ?? 'en',
      name: json['name']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      contact: List<String>.from(json['contact'] ?? []),
      summary: json['summary']?.toString() ?? '',
      sections: (json['sections'] as List<dynamic>? ?? [])
          .map((s) => ImprovedCvSection.fromJson(s as Map<String, dynamic>))
          .toList(),
      changes: List<String>.from(json['changes'] ?? []),
    );
  }

  String toMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('# $name');
    buffer.writeln('**$title**');
    buffer.writeln(contact.join(' | '));
    buffer.writeln(isIndonesian ? '\n## RINGKASAN' : '\n## SUMMARY');
    buffer.writeln(summary);
    for (final section in sections) {
      buffer.writeln('\n## ${section.heading.toUpperCase()}');
      if (section.entries.isNotEmpty) {
        for (final entry in section.entries) {
          final header = entry.date.isNotEmpty
              ? '**${entry.title}** (${entry.date})'
              : '**${entry.title}**';
          buffer.writeln(header);
          if (entry.subtitle.isNotEmpty) {
            buffer.writeln('_${entry.subtitle}_');
          }
          for (final b in entry.bullets) {
            buffer.writeln('- $b');
          }
        }
      } else if (section.skillGroups.isNotEmpty) {
        for (final group in section.skillGroups) {
          buffer.writeln('**${group.category}:** ${group.items}');
        }
      } else {
        for (final b in section.bullets) {
          buffer.writeln('- $b');
        }
      }
    }
    return buffer.toString();
  }
}

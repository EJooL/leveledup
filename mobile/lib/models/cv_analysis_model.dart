enum IssueSeverity { critical, warning, suggestion }

enum IssueCategory {
  personalInfo,
  atsReadability,
  keywordMatch,
  achievements,
  languageQuality,
}

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

  Map<String, dynamic> toJson() => {'before': before, 'after': after};
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
        return 'English Quality';
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'severity': severity,
        'title': title,
        'detail': detail,
        'fix': fix,
        'rewrite': rewrite?.toJson(),
      };
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

  Map<String, dynamic> toJson() => {
        'jobTitle': jobTitle,
        'matched': matched,
        'missing': missing,
        'missingCount': missingCount,
      };
}

class AnalysisResult {
  final String mode;
  final int overallScore;
  final String summary;
  final List<Issue> issues;
  final KeywordMatch? keywordMatch;
  final String fileName;
  final String engine;
  final bool isUnlocked;

  AnalysisResult({
    required this.mode,
    required this.overallScore,
    required this.summary,
    required this.issues,
    this.keywordMatch,
    required this.fileName,
    required this.engine,
    this.isUnlocked = false,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json, {bool unlocked = false}) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final parsedIssues = (json['issues'] as List<dynamic>? ?? [])
        .map((item) => Issue.fromJson(item as Map<String, dynamic>))
        .toList();

    final hasUnlockedDetails = unlocked || parsedIssues.any((i) => !i.isLocked);

    return AnalysisResult(
      mode: json['mode']?.toString() ?? 'global',
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

  int countByCategory(String catId) {
    return issues.where((i) => i.category == catId).length;
  }
}

class ImprovedCvSection {
  final String heading;
  final List<String> bullets;

  ImprovedCvSection({required this.heading, required this.bullets});

  factory ImprovedCvSection.fromJson(Map<String, dynamic> json) {
    return ImprovedCvSection(
      heading: json['heading']?.toString() ?? '',
      bullets: List<String>.from(json['bullets'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {'heading': heading, 'bullets': bullets};
}

class ImprovedCV {
  final String name;
  final String title;
  final List<String> contact;
  final String summary;
  final List<ImprovedCvSection> sections;
  final List<String> changes;

  ImprovedCV({
    required this.name,
    required this.title,
    required this.contact,
    required this.summary,
    required this.sections,
    required this.changes,
  });

  factory ImprovedCV.fromJson(Map<String, dynamic> json) {
    return ImprovedCV(
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
    buffer.writeln(contact.join(' • '));
    buffer.writeln('\n## Executive Summary');
    buffer.writeln(summary);
    for (final section in sections) {
      buffer.writeln('\n## ${section.heading}');
      for (final b in section.bullets) {
        buffer.writeln('- $b');
      }
    }
    return buffer.toString();
  }
}


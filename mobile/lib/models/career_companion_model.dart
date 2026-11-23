import 'cv_analysis_model.dart';

String _formatIsoDate(String rawDate, String fallback) {
  if (rawDate.isEmpty) return fallback;
  final parsed = DateTime.tryParse(rawDate);
  if (parsed == null) return fallback;
  final m = parsed.month.toString().padLeft(2, '0');
  final d = parsed.day.toString().padLeft(2, '0');
  return '${parsed.year}-$m-$d';
}

enum CareerStage {
  jobHunting,
  onboarding,
}

extension CareerStageExtension on CareerStage {
  String get apiMode => this == CareerStage.jobHunting ? 'job_hunt' : 'hired';

  static CareerStage fromApiMode(String? mode) =>
      mode == 'hired' ? CareerStage.onboarding : CareerStage.jobHunting;

  String get label => this == CareerStage.jobHunting
      ? 'Job Hunt Mode'
      : 'Hired · First 90 Days';
}

enum QuestVerificationType {
  scanVerified,
  winVerified,
  selfReported,
}

extension QuestVerificationTypeExtension on QuestVerificationType {
  bool get isManual => this == QuestVerificationType.selfReported;

  String get label {
    switch (this) {
      case QuestVerificationType.scanVerified:
        return 'Verified by Scan';
      case QuestVerificationType.winVerified:
        return 'Verified by Win';
      case QuestVerificationType.selfReported:
        return 'Self-reported';
    }
  }

  static QuestVerificationType fromApi(String? raw) {
    switch (raw) {
      case 'scan_verified':
        return QuestVerificationType.scanVerified;
      case 'win_verified':
        return QuestVerificationType.winVerified;
      default:
        return QuestVerificationType.selfReported;
    }
  }
}

enum QuestDifficulty {
  easy,
  medium,
  hard,
}

extension QuestDifficultyExtension on QuestDifficulty {
  int get defaultXp {
    switch (this) {
      case QuestDifficulty.easy:
        return 35;
      case QuestDifficulty.medium:
        return 75;
      case QuestDifficulty.hard:
        return 120;
    }
  }
}

class CareerQuest {
  final String id;
  final String title;
  final String description;
  final CareerStage stage;
  final QuestDifficulty difficulty;
  final int xpReward;
  final bool isCompleted;
  final String impactMetricTag;
  final QuestVerificationType verificationType;
  final String? linkedIssueKey;

  const CareerQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.stage,
    this.difficulty = QuestDifficulty.medium,
    this.xpReward = 50,
    this.isCompleted = false,
    this.impactMetricTag = 'Career Action',
    this.verificationType = QuestVerificationType.selfReported,
    this.linkedIssueKey,
  });

  bool get isManual => verificationType.isManual;

  factory CareerQuest.fromJson(Map<String, dynamic> json) {
    final verType = QuestVerificationTypeExtension.fromApi(
      json['verificationType']?.toString(),
    );
    final stage = CareerStageExtension.fromApiMode(
      json['careerMode']?.toString(),
    );
    return CareerQuest(
      id: json['questKey']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      stage: stage,
      difficulty: verType == QuestVerificationType.selfReported
          ? QuestDifficulty.easy
          : QuestDifficulty.medium,
      xpReward: verType == QuestVerificationType.selfReported ? 40 : 75,
      isCompleted: json['isCompleted'] == true,
      impactMetricTag: verType.label,
      verificationType: verType,
      linkedIssueKey: json['linkedIssueKey']?.toString(),
    );
  }

  CareerQuest copyWith({
    bool? isCompleted,
    String? title,
    String? description,
    QuestVerificationType? verificationType,
  }) {
    return CareerQuest(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      stage: stage,
      difficulty: difficulty,
      xpReward: xpReward,
      isCompleted: isCompleted ?? this.isCompleted,
      impactMetricTag: impactMetricTag,
      verificationType: verificationType ?? this.verificationType,
      linkedIssueKey: linkedIssueKey,
    );
  }
}

enum SkillBranch {
  technical,
  architecture,
  leadership,
  globalOps,
}

extension SkillBranchExtension on SkillBranch {
  String get apiCategory {
    switch (this) {
      case SkillBranch.technical:
        return 'project_delivery';
      case SkillBranch.architecture:
        return 'process_quality';
      case SkillBranch.leadership:
        return 'leadership_teamwork';
      case SkillBranch.globalOps:
        return 'metrics_growth';
    }
  }

  static SkillBranch fromApiCategory(String? cat) {
    switch (cat) {
      case 'process_quality':
        return SkillBranch.architecture;
      case 'leadership_teamwork':
        return SkillBranch.leadership;
      case 'metrics_growth':
        return SkillBranch.globalOps;
      default:
        return SkillBranch.technical;
    }
  }
}

class CareerBadge {
  final String id;
  final String title;
  final String description;
  final String iconCode;
  final bool isEarned;

  const CareerBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.iconCode,
    this.isEarned = false,
  });

  CareerBadge copyWith({bool? isEarned}) {
    return CareerBadge(
      id: id,
      title: title,
      description: description,
      iconCode: iconCode,
      isEarned: isEarned ?? this.isEarned,
    );
  }
}

class WorkWin {
  final String id;
  final String title;
  final String impactMetric;
  final SkillBranch branch;
  final String category;
  final String language;
  final String starBullet;
  final String? mergedIntoScanToken;
  final String dateLabel;
  final CareerStage stage;

  WorkWin({
    required this.id,
    required this.title,
    required this.impactMetric,
    required this.branch,
    String? category,
    this.language = 'en',
    String? starBullet,
    this.mergedIntoScanToken,
    required this.dateLabel,
    required this.stage,
  })  : category = category ?? branch.apiCategory,
        starBullet = (starBullet != null && starBullet.trim().isNotEmpty)
            ? starBullet.trim()
            : _buildDefaultStarBullet(title, impactMetric, language);

  bool get isMerged =>
      mergedIntoScanToken != null && mergedIntoScanToken!.isNotEmpty;

  String toStarBullet() => starBullet;

  static String _buildDefaultStarBullet(
    String title,
    String impactMetric,
    String language,
  ) {
    final cleanTitle = title.trim().replaceAll(RegExp(r'\.$'), '');
    final cleanImpact = impactMetric.trim().replaceAll(RegExp(r'\.$'), '');
    final isId = language == 'id';
    final hasNumber = RegExp(r'\d').hasMatch('$cleanTitle $cleanImpact');

    if (cleanImpact.isNotEmpty) {
      if (hasNumber || cleanImpact.contains('[')) {
        return isId
            ? '$cleanTitle, menghasilkan dampak terukur berupa $cleanImpact.'
            : '$cleanTitle, delivering measurable impact of $cleanImpact.';
      }
      return isId
          ? '$cleanTitle, meningkatkan $cleanImpact sebesar [X]%.'
          : '$cleanTitle, improving $cleanImpact by [X]%.';
    }
    if (hasNumber || cleanTitle.contains('[')) {
      return '$cleanTitle.';
    }
    return isId
        ? '$cleanTitle, meningkatkan efektivitas dan capaian target sebesar [X]% pada [metrik/jumlah].'
        : '$cleanTitle, improving overall outcome efficiency by [X]% across [target metric].';
  }

  factory WorkWin.fromJson(Map<String, dynamic> json) {
    final cat = json['category']?.toString() ?? 'project_delivery';
    return WorkWin(
      id: json['id']?.toString() ?? '${DateTime.now().millisecondsSinceEpoch}',
      title: json['title']?.toString() ?? '',
      impactMetric: json['impactMetric']?.toString() ?? '',
      branch: SkillBranchExtension.fromApiCategory(cat),
      category: cat,
      language: json['language']?.toString() ?? 'en',
      starBullet: json['starBullet']?.toString(),
      mergedIntoScanToken: json['mergedIntoScanToken']?.toString(),
      dateLabel: _formatIsoDate(json['createdAt']?.toString() ?? '', 'Saved Win'),
      stage: CareerStage.onboarding,
    );
  }

  WorkWin copyWith({
    String? starBullet,
    String? mergedIntoScanToken,
  }) {
    return WorkWin(
      id: id,
      title: title,
      impactMetric: impactMetric,
      branch: branch,
      category: category,
      language: language,
      starBullet: starBullet ?? this.starBullet,
      mergedIntoScanToken: mergedIntoScanToken ?? this.mergedIntoScanToken,
      dateLabel: dateLabel,
      stage: stage,
    );
  }
}

class FixedIssueItem {
  final String key;
  final String title;
  final String category;

  const FixedIssueItem({
    required this.key,
    required this.title,
    this.category = 'general',
  });

  factory FixedIssueItem.fromJson(Map<String, dynamic> json) {
    return FixedIssueItem(
      key: json['key']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? 'general',
    );
  }
}

class ScanScorePoint {
  final String scanToken;
  final String fileName;
  final int overallScore;
  final int scoreDelta;
  final String language;
  final String jobTitle;
  final int issueCount;
  final List<String> issueKeys;
  final List<FixedIssueItem> fixedIssues;
  final String createdAtLabel;

  const ScanScorePoint({
    required this.scanToken,
    required this.fileName,
    required this.overallScore,
    this.scoreDelta = 0,
    this.language = 'en',
    this.jobTitle = 'Professional',
    this.issueCount = 0,
    this.issueKeys = const [],
    this.fixedIssues = const [],
    this.createdAtLabel = 'Recent Scan',
  });

  factory ScanScorePoint.fromJson(Map<String, dynamic> json) {
    return ScanScorePoint(
      scanToken: json['scanToken']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? 'CV.pdf',
      overallScore: (json['overallScore'] is num)
          ? (json['overallScore'] as num).toInt()
          : 0,
      scoreDelta: (json['scoreDelta'] is num)
          ? (json['scoreDelta'] as num).toInt()
          : 0,
      language: json['language']?.toString() ?? 'en',
      jobTitle: json['jobTitle']?.toString() ?? 'Professional',
      issueCount: (json['issueCount'] is num)
          ? (json['issueCount'] as num).toInt()
          : 0,
      issueKeys: List<String>.from(json['issueKeys'] ?? const []),
      fixedIssues: (json['fixedIssues'] as List<dynamic>? ?? const [])
          .map((e) => FixedIssueItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAtLabel: _formatIsoDate(json['createdAt']?.toString() ?? '', 'Scan'),
    );
  }
}

class SkillGapItem {
  final String keyword;
  final String role;
  final String actionType;
  final String actionTitle;
  final String concreteAction;
  final String sampleBullet;

  const SkillGapItem({
    required this.keyword,
    required this.role,
    required this.actionType,
    required this.actionTitle,
    required this.concreteAction,
    required this.sampleBullet,
  });

  String get actionTypeLabel {
    switch (actionType) {
      case 'portfolio_project':
        return 'Mini Project / Case Study';
      case 'skills_section':
        return 'Skills & Tools Section';
      default:
        return 'Experience Bullet';
    }
  }

  factory SkillGapItem.fromJson(Map<String, dynamic> json) {
    return SkillGapItem(
      keyword: json['keyword']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Professional',
      actionType: json['actionType']?.toString() ?? 'experience_bullet',
      actionTitle: json['actionTitle']?.toString() ?? '',
      concreteAction: json['concreteAction']?.toString() ?? '',
      sampleBullet: json['sampleBullet']?.toString() ?? '',
    );
  }
}

class SkillGapReport {
  final String jobTitle;
  final String language;
  final List<String> matchedKeywords;
  final List<String> missingKeywords;
  final List<SkillGapItem> gaps;

  const SkillGapReport({
    required this.jobTitle,
    this.language = 'en',
    this.matchedKeywords = const [],
    this.missingKeywords = const [],
    this.gaps = const [],
  });

  bool get isIndonesian => language == 'id';

  factory SkillGapReport.fromJson(Map<String, dynamic> json) {
    return SkillGapReport(
      jobTitle: json['jobTitle']?.toString() ?? 'Fresh Graduate Professional',
      language: json['language']?.toString() ?? 'en',
      matchedKeywords: List<String>.from(json['matchedKeywords'] ?? const []),
      missingKeywords: List<String>.from(json['missingKeywords'] ?? const []),
      gaps: (json['gaps'] as List<dynamic>? ?? const [])
          .map((g) => SkillGapItem.fromJson(g as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LevelUpEvent {
  final int newLevel;
  final String careerMode; // 'job_hunt' | 'hired'
  final int eventId;

  const LevelUpEvent({
    required this.newLevel,
    required this.careerMode,
    required this.eventId,
  });

  bool get isPostHire => careerMode == 'hired';

  String get phaseBadgeLabel =>
      isPostHire ? 'POST-HIRE PHASE' : 'PRE-JOB PHASE';
}

class UserCareerProfile {
  static const int preJobXpStep = 250;
  static const int postHireXpStep = 300;

  final String characterName;
  final String targetRole;
  final int preJobLevel;
  final int preJobXp;
  final int postHireLevel;
  final int postHireXp;
  final int totalXpEarned;
  final int? latestAtsScore;
  final CareerStage currentStage;
  final List<CareerQuest> quests;
  final List<CareerBadge> badges;
  final List<WorkWin> workWins;
  final List<ScanScorePoint> scoreHistory;
  final SkillGapReport skillGap;
  final ImprovedCV? latestMergedCv;
  final CareerBadge? pendingToastBadge;
  final LevelUpEvent? pendingLevelUpEvent;

  const UserCareerProfile({
    required this.characterName,
    required this.targetRole,
    this.preJobLevel = 1,
    this.preJobXp = 180,
    this.postHireLevel = 1,
    this.postHireXp = 150,
    required this.totalXpEarned,
    this.latestAtsScore,
    required this.currentStage,
    required this.quests,
    required this.badges,
    this.workWins = const [],
    this.scoreHistory = const [],
    required this.skillGap,
    this.latestMergedCv,
    this.pendingToastBadge,
    this.pendingLevelUpEvent,
  });

  bool get isHiredMode => currentStage != CareerStage.jobHunting;
  CareerStage get normalizedMode =>
      isHiredMode ? CareerStage.onboarding : CareerStage.jobHunting;

  int get currentLevel => isHiredMode ? postHireLevel : preJobLevel;
  int get currentPhaseXp => isHiredMode ? postHireXp : preJobXp;
  int get targetPhaseXp => isHiredMode
      ? (postHireLevel * postHireXpStep)
      : (preJobLevel * preJobXpStep);
  double get xpProgress => targetPhaseXp > 0
      ? (currentPhaseXp / targetPhaseXp).clamp(0.0, 1.0)
      : 0.0;
  String get phaseShortTag => isHiredMode ? 'POST-HIRE' : 'PRE-JOB';

  List<CareerQuest> get activeModeQuests =>
      quests.where((q) => q.stage == normalizedMode).toList();

  int get activeModeCompletedCount =>
      activeModeQuests.where((q) => q.isCompleted).length;

  int get activeModeTotalCount => activeModeQuests.length;

  double get activeModeProgressFraction => activeModeTotalCount > 0
      ? (activeModeCompletedCount / activeModeTotalCount).clamp(0.0, 1.0)
      : 0.0;

  String get activeModeProgressLabel =>
      '$activeModeCompletedCount of $activeModeTotalCount done';

  String get timelineLabel {
    if (scoreHistory.isEmpty) {
      return latestAtsScore != null ? '$latestAtsScore' : 'No scans yet';
    }
    return scoreHistory.map((s) => s.overallScore).join(' -> ');
  }

  String get nextBestActionTitle {
    if (!isHiredMode && latestAtsScore == null) {
      return 'Run your first ATS CV Scan';
    }
    final nextIncomplete =
        activeModeQuests.where((q) => !q.isCompleted).toList();
    if (nextIncomplete.isNotEmpty) {
      return nextIncomplete.first.title;
    }
    if (workWins.isEmpty) {
      return 'Log a recent achievement in Wins';
    }
    return 'Merge your latest wins into your living CV';
  }

  UserCareerProfile copyWith({
    String? characterName,
    String? targetRole,
    int? preJobLevel,
    int? preJobXp,
    int? postHireLevel,
    int? postHireXp,
    int? totalXpEarned,
    int? latestAtsScore,
    CareerStage? currentStage,
    List<CareerQuest>? quests,
    List<CareerBadge>? badges,
    List<WorkWin>? workWins,
    List<ScanScorePoint>? scoreHistory,
    SkillGapReport? skillGap,
    ImprovedCV? latestMergedCv,
    CareerBadge? pendingToastBadge,
    bool clearToastBadge = false,
    LevelUpEvent? pendingLevelUpEvent,
    bool clearLevelUpEvent = false,
  }) {
    return UserCareerProfile(
      characterName: characterName ?? this.characterName,
      targetRole: targetRole ?? this.targetRole,
      preJobLevel: preJobLevel ?? this.preJobLevel,
      preJobXp: preJobXp ?? this.preJobXp,
      postHireLevel: postHireLevel ?? this.postHireLevel,
      postHireXp: postHireXp ?? this.postHireXp,
      totalXpEarned: totalXpEarned ?? this.totalXpEarned,
      latestAtsScore: latestAtsScore ?? this.latestAtsScore,
      currentStage: currentStage ?? this.currentStage,
      quests: quests ?? this.quests,
      badges: badges ?? this.badges,
      workWins: workWins ?? this.workWins,
      scoreHistory: scoreHistory ?? this.scoreHistory,
      skillGap: skillGap ?? this.skillGap,
      latestMergedCv: latestMergedCv ?? this.latestMergedCv,
      pendingToastBadge: clearToastBadge
          ? null
          : (pendingToastBadge ?? this.pendingToastBadge),
      pendingLevelUpEvent: clearLevelUpEvent
          ? null
          : (pendingLevelUpEvent ?? this.pendingLevelUpEvent),
    );
  }
}

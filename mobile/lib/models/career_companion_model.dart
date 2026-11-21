import 'cv_analysis_model.dart';

enum CareerStage {
  jobHunting,
  onboarding,
  midLevel,
  seniorTrack,
}

extension CareerStageExtension on CareerStage {
  /// Only two active modes in UI: Job Hunt and Hired (First 90 Days)
  static List<CareerStage> get activeModes => const [
        CareerStage.jobHunting,
        CareerStage.onboarding,
      ];

  String get apiMode =>
      this == CareerStage.jobHunting ? 'job_hunt' : 'hired';

  static CareerStage fromApiMode(String? mode) {
    if (mode == 'hired') return CareerStage.onboarding;
    return CareerStage.jobHunting;
  }

  String get label {
    switch (this) {
      case CareerStage.jobHunting:
        return 'Job Hunt Mode';
      case CareerStage.onboarding:
        return 'Hired · First 90 Days';
      case CareerStage.midLevel:
        return 'Hired · First 90 Days';
      case CareerStage.seniorTrack:
        return 'Hired · First 90 Days';
    }
  }

  String get shortLabel {
    switch (this) {
      case CareerStage.jobHunting:
        return 'Job Hunt';
      case CareerStage.onboarding:
        return 'First 90 Days';
      case CareerStage.midLevel:
        return 'First 90 Days';
      case CareerStage.seniorTrack:
        return 'First 90 Days';
    }
  }

  String get subtitle {
    switch (this) {
      case CareerStage.jobHunting:
        return 'Fix ATS flaws, close skill gaps for your target role, and keep your CV ready.';
      case CareerStage.onboarding:
      case CareerStage.midLevel:
      case CareerStage.seniorTrack:
        return 'Align 30/60/90-day goals, document deliverables, and merge wins into your living CV.';
    }
  }
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
  boss,
}

extension QuestDifficultyExtension on QuestDifficulty {
  String get label {
    switch (this) {
      case QuestDifficulty.easy:
        return 'STEP';
      case QuestDifficulty.medium:
        return 'CORE';
      case QuestDifficulty.hard:
        return 'HIGH IMPACT';
      case QuestDifficulty.boss:
        return 'MILESTONE';
    }
  }

  int get defaultXp {
    switch (this) {
      case QuestDifficulty.easy:
        return 35;
      case QuestDifficulty.medium:
        return 75;
      case QuestDifficulty.hard:
        return 120;
      case QuestDifficulty.boss:
        return 200;
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
  final QuestVerificationType? _verificationType;
  final String? linkedIssueKey;

  CareerQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.stage,
    this.difficulty = QuestDifficulty.medium,
    this.xpReward = 50,
    this.isCompleted = false,
    this.impactMetricTag = 'Career Action',
    QuestVerificationType verificationType = QuestVerificationType.selfReported,
    this.linkedIssueKey,
  }) : _verificationType = verificationType;

  // Hot-reload safe getter in case existing instances lack the newly added field
  QuestVerificationType get verificationType =>
      _verificationType ?? QuestVerificationType.selfReported;

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
  String get title {
    switch (this) {
      case SkillBranch.technical:
        return 'Project & Delivery';
      case SkillBranch.architecture:
        return 'Process & Quality';
      case SkillBranch.leadership:
        return 'Leadership & Teamwork';
      case SkillBranch.globalOps:
        return 'Metrics & Growth';
    }
  }

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

class SkillNode {
  final String id;
  final String title;
  final String description;
  final SkillBranch branch;
  final int currentTier;
  final int maxTier;
  final int xpCost;
  final int requiredLevel;

  SkillNode({
    required this.id,
    required this.title,
    required this.description,
    required this.branch,
    this.currentTier = 0,
    this.maxTier = 3,
    required this.xpCost,
    this.requiredLevel = 1,
  });

  bool get isMaxed => currentTier >= maxTier;
  bool get isUnlocked => currentTier > 0;

  SkillNode copyWith({int? currentTier}) {
    return SkillNode(
      id: id,
      title: title,
      description: description,
      branch: branch,
      currentTier: currentTier ?? this.currentTier,
      maxTier: maxTier,
      xpCost: xpCost,
      requiredLevel: requiredLevel,
    );
  }
}

class CareerBadge {
  final String id;
  final String title;
  final String description;
  final String iconCode;
  final bool isEarned;

  CareerBadge({
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
  final String? _category;
  final String? _language;
  final String? _starBullet;
  final String? mergedIntoScanToken;
  final String dateLabel;
  final CareerStage stage;

  WorkWin({
    required this.id,
    required this.title,
    required this.impactMetric,
    required this.branch,
    String? category,
    String language = 'en',
    String? starBullet,
    this.mergedIntoScanToken,
    required this.dateLabel,
    required this.stage,
  })  : _category = category ?? branch.apiCategory,
        _language = language,
        _starBullet = (starBullet != null && starBullet.trim().isNotEmpty)
            ? starBullet.trim()
            : _buildDefaultStarBullet(title, impactMetric, language);

  // Hot-reload safe getters
  String get category => _category ?? branch.apiCategory;
  String get language => _language ?? 'en';
  String get starBullet =>
      (_starBullet != null && _starBullet.trim().isNotEmpty)
          ? _starBullet
          : _buildDefaultStarBullet(title, impactMetric, language);

  bool get isMerged =>
      mergedIntoScanToken != null && mergedIntoScanToken!.isNotEmpty;

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

  String toStarBullet() => starBullet;

  factory WorkWin.fromJson(Map<String, dynamic> json) {
    final cat = json['category']?.toString() ?? 'project_delivery';
    final branch = SkillBranchExtension.fromApiCategory(cat);
    final rawDate = json['createdAt']?.toString() ?? '';
    String dateLabel = 'Saved Win';
    if (rawDate.isNotEmpty) {
      final parsed = DateTime.tryParse(rawDate);
      if (parsed != null) {
        final m = parsed.month.toString().padLeft(2, '0');
        final d = parsed.day.toString().padLeft(2, '0');
        dateLabel = '${parsed.year}-$m-$d';
      }
    }

    return WorkWin(
      id: json['id']?.toString() ?? '${DateTime.now().millisecondsSinceEpoch}',
      title: json['title']?.toString() ?? '',
      impactMetric: json['impactMetric']?.toString() ?? '',
      branch: branch,
      category: cat,
      language: json['language']?.toString() ?? 'en',
      starBullet: json['starBullet']?.toString(),
      mergedIntoScanToken: json['mergedIntoScanToken']?.toString(),
      dateLabel: dateLabel,
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
    final rawDate = json['createdAt']?.toString() ?? '';
    String label = 'Scan';
    if (rawDate.isNotEmpty) {
      final parsed = DateTime.tryParse(rawDate);
      if (parsed != null) {
        final m = parsed.month.toString().padLeft(2, '0');
        final d = parsed.day.toString().padLeft(2, '0');
        label = '${parsed.year}-$m-$d';
      }
    }

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
      createdAtLabel: label,
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

class DailyCheckIn {
  final String id;
  final String focusArea;
  final int confidenceRating;
  final String note;
  final String dateKey;
  final String dateLabel;

  DailyCheckIn({
    required this.id,
    required this.focusArea,
    required this.confidenceRating,
    required this.note,
    required this.dateKey,
    required this.dateLabel,
  });
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
  final int? _level;
  final int? _currentXp;
  final int? _preJobLevel;
  final int? _preJobXp;
  final int? _postHireLevel;
  final int? _postHireXp;
  final int? _totalXpEarned;
  final int? _streakDays;
  final int? latestAtsScore;
  final int? _applicationsSent;
  final int? _interviewsSecured;
  final CareerStage currentStage;
  final List<CareerQuest> quests;
  final List<SkillNode> skills;
  final List<CareerBadge> badges;
  final List<WorkWin>? _workWins;
  final List<DailyCheckIn>? _checkIns;
  final List<ScanScorePoint>? _scoreHistory;
  final SkillGapReport? _skillGap;
  final bool? _needsQuarterlyReminder;
  final String? _reminderMessage;
  final ImprovedCV? latestMergedCv;
  final CareerBadge? pendingToastBadge;
  final LevelUpEvent? pendingLevelUpEvent;

  UserCareerProfile({
    required this.characterName,
    required this.targetRole,
    required int level,
    required int currentXp,
    int? preJobLevel,
    int? preJobXp,
    int? postHireLevel,
    int? postHireXp,
    required int totalXpEarned,
    required int streakDays,
    this.latestAtsScore,
    int applicationsSent = 3,
    int interviewsSecured = 1,
    required this.currentStage,
    required this.quests,
    required this.skills,
    required this.badges,
    List<WorkWin> workWins = const [],
    List<DailyCheckIn> checkIns = const [],
    List<ScanScorePoint> scoreHistory = const [],
    SkillGapReport? skillGap,
    bool needsQuarterlyReminder = true,
    String? reminderMessage,
    this.latestMergedCv,
    this.pendingToastBadge,
    this.pendingLevelUpEvent,
  })  : _level = level,
        _currentXp = currentXp,
        _preJobLevel = preJobLevel ?? level,
        _preJobXp = preJobXp ?? currentXp,
        _postHireLevel = postHireLevel ?? 1,
        _postHireXp = postHireXp ?? 150,
        _totalXpEarned = totalXpEarned,
        _streakDays = streakDays,
        _applicationsSent = applicationsSent,
        _interviewsSecured = interviewsSecured,
        _workWins = workWins,
        _checkIns = checkIns,
        _scoreHistory = scoreHistory,
        _skillGap = skillGap,
        _needsQuarterlyReminder = needsQuarterlyReminder,
        _reminderMessage = reminderMessage;

  // Hot-reload safe phase-aware EXP getters
  String get careerMode => isHiredMode ? 'hired' : 'job_hunt';
  int get preJobLevel => _preJobLevel ?? (_level ?? 1);
  int get preJobXp => _preJobXp ?? (_currentXp ?? 180);
  int get postHireLevel => _postHireLevel ?? 1;
  int get postHireXp => _postHireXp ?? 150;

  int get currentLevel => isHiredMode ? postHireLevel : preJobLevel;
  int get currentPhaseXp => isHiredMode ? postHireXp : preJobXp;
  int get targetPhaseXp => isHiredMode
      ? (postHireLevel * postHireXpStep)
      : (preJobLevel * preJobXpStep);
  double get xpProgress => targetPhaseXp > 0
      ? (currentPhaseXp / targetPhaseXp).clamp(0.0, 1.0)
      : 0.0;
  String get phaseShortTag => isHiredMode ? 'POST-HIRE' : 'PRE-JOB';

  // Legacy getters mapped cleanly to active phase EXP
  int get level => currentLevel;
  int get currentXp => currentPhaseXp;
  int get totalXpEarned => _totalXpEarned ?? 430;
  int get streakDays => _streakDays ?? 5;
  int get applicationsSent => _applicationsSent ?? 3;
  int get interviewsSecured => _interviewsSecured ?? 1;
  List<WorkWin> get workWins => _workWins ?? const [];
  List<DailyCheckIn> get checkIns => _checkIns ?? const [];
  List<ScanScorePoint> get scoreHistory => _scoreHistory ?? const [];
  bool get needsQuarterlyReminder => _needsQuarterlyReminder ?? false;
  String get reminderMessage =>
      _reminderMessage ??
      "It's been 3 months — any new wins? Log your latest achievements so your living CV stays ready.";

  SkillGapReport get skillGap =>
      _skillGap ??
      SkillGapReport(
        jobTitle: targetRole,
        language: 'en',
        matchedKeywords: const ['Problem Solving', 'Project Execution'],
        missingKeywords: const [],
        gaps: const [],
      );

  bool get isHiredMode => currentStage != CareerStage.jobHunting;

  CareerStage get normalizedMode =>
      isHiredMode ? CareerStage.onboarding : CareerStage.jobHunting;

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

  static String todayDateKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  bool get hasCheckedInToday {
    final today = todayDateKey();
    return checkIns.any((c) => c.dateKey == today);
  }

  int get xpToNextLevel => targetPhaseXp;

  double get levelProgress => xpProgress;

  String get rankTitle {
    if (isHiredMode) return 'Hired · First 90 Days';
    return 'Job Hunt Mode';
  }

  int get completedQuestsCount => quests.where((q) => q.isCompleted).length;

  int get earnedBadgesCount => badges.where((b) => b.isEarned).length;

  UserCareerProfile copyWith({
    String? characterName,
    String? targetRole,
    int? level,
    int? currentXp,
    int? preJobLevel,
    int? preJobXp,
    int? postHireLevel,
    int? postHireXp,
    int? totalXpEarned,
    int? streakDays,
    int? latestAtsScore,
    int? applicationsSent,
    int? interviewsSecured,
    CareerStage? currentStage,
    List<CareerQuest>? quests,
    List<SkillNode>? skills,
    List<CareerBadge>? badges,
    List<WorkWin>? workWins,
    List<DailyCheckIn>? checkIns,
    List<ScanScorePoint>? scoreHistory,
    SkillGapReport? skillGap,
    bool? needsQuarterlyReminder,
    String? reminderMessage,
    ImprovedCV? latestMergedCv,
    CareerBadge? pendingToastBadge,
    bool clearToastBadge = false,
    LevelUpEvent? pendingLevelUpEvent,
    bool clearLevelUpEvent = false,
  }) {
    final nextStage = currentStage ?? this.currentStage;
    final nextIsHired = nextStage != CareerStage.jobHunting;
    final resolvedPreLevel = preJobLevel ?? this.preJobLevel;
    final resolvedPreXp = preJobXp ?? this.preJobXp;
    final resolvedPostLevel = postHireLevel ?? this.postHireLevel;
    final resolvedPostXp = postHireXp ?? this.postHireXp;

    return UserCareerProfile(
      characterName: characterName ?? this.characterName,
      targetRole: targetRole ?? this.targetRole,
      level: level ?? (nextIsHired ? resolvedPostLevel : resolvedPreLevel),
      currentXp: currentXp ?? (nextIsHired ? resolvedPostXp : resolvedPreXp),
      preJobLevel: resolvedPreLevel,
      preJobXp: resolvedPreXp,
      postHireLevel: resolvedPostLevel,
      postHireXp: resolvedPostXp,
      totalXpEarned: totalXpEarned ?? this.totalXpEarned,
      streakDays: streakDays ?? this.streakDays,
      latestAtsScore: latestAtsScore ?? this.latestAtsScore,
      applicationsSent: applicationsSent ?? this.applicationsSent,
      interviewsSecured: interviewsSecured ?? this.interviewsSecured,
      currentStage: nextStage,
      quests: quests ?? this.quests,
      skills: skills ?? this.skills,
      badges: badges ?? this.badges,
      workWins: workWins ?? this.workWins,
      checkIns: checkIns ?? this.checkIns,
      scoreHistory: scoreHistory ?? this.scoreHistory,
      skillGap: skillGap ?? this.skillGap,
      needsQuarterlyReminder:
          needsQuarterlyReminder ?? this.needsQuarterlyReminder,
      reminderMessage: reminderMessage ?? this.reminderMessage,
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

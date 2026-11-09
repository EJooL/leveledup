enum CareerStage {
  jobHunting,
  onboarding,
  midLevel,
  seniorTrack,
}

extension CareerStageExtension on CareerStage {
  String get label {
    switch (this) {
      case CareerStage.jobHunting:
        return 'Phase 1: Global Job Hunt';
      case CareerStage.onboarding:
        return 'Phase 2: First 90 Days (Hired!)';
      case CareerStage.midLevel:
        return 'Phase 3: High-Impact Contributor';
      case CareerStage.seniorTrack:
        return 'Phase 4: Senior & Tech Lead Track';
    }
  }

  String get shortLabel {
    switch (this) {
      case CareerStage.jobHunting:
        return 'Job Hunt';
      case CareerStage.onboarding:
        return 'First 90 Days';
      case CareerStage.midLevel:
        return 'Mid-Level';
      case CareerStage.seniorTrack:
        return 'Senior Track';
    }
  }

  String get subtitle {
    switch (this) {
      case CareerStage.jobHunting:
        return 'Optimize your ATS resume, eliminate bias, and secure global interviews.';
      case CareerStage.onboarding:
        return 'Ship your first production PR, map the architecture, and build team trust.';
      case CareerStage.midLevel:
        return 'Own end-to-end features, drive measurable KPIs, and mentor junior peers.';
      case CareerStage.seniorTrack:
        return 'Lead cross-team system design, shape engineering culture, and scale impact.';
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
        return 'EASY';
      case QuestDifficulty.medium:
        return 'MEDIUM';
      case QuestDifficulty.hard:
        return 'HARD';
      case QuestDifficulty.boss:
        return 'BOSS MILESTONE';
    }
  }

  int get defaultXp {
    switch (this) {
      case QuestDifficulty.easy:
        return 35;
      case QuestDifficulty.medium:
        return 75;
      case QuestDifficulty.hard:
        return 150;
      case QuestDifficulty.boss:
        return 300;
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

  CareerQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.stage,
    required this.difficulty,
    required this.xpReward,
    this.isCompleted = false,
    required this.impactMetricTag,
  });

  CareerQuest copyWith({bool? isCompleted}) {
    return CareerQuest(
      id: id,
      title: title,
      description: description,
      stage: stage,
      difficulty: difficulty,
      xpReward: xpReward,
      isCompleted: isCompleted ?? this.isCompleted,
      impactMetricTag: impactMetricTag,
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
        return 'Technical Craft';
      case SkillBranch.architecture:
        return 'System Architecture';
      case SkillBranch.leadership:
        return 'Leadership & Impact';
      case SkillBranch.globalOps:
        return 'Global Career Ops';
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

class UserCareerProfile {
  final String characterName;
  final String targetRole;
  final int level;
  final int currentXp;
  final int totalXpEarned;
  final int streakDays;
  final int? latestAtsScore;
  final CareerStage currentStage;
  final List<CareerQuest> quests;
  final List<SkillNode> skills;
  final List<CareerBadge> badges;

  UserCareerProfile({
    required this.characterName,
    required this.targetRole,
    required this.level,
    required this.currentXp,
    required this.totalXpEarned,
    required this.streakDays,
    this.latestAtsScore,
    required this.currentStage,
    required this.quests,
    required this.skills,
    required this.badges,
  });

  int get xpToNextLevel => level * 250;

  double get levelProgress => (currentXp / xpToNextLevel).clamp(0.0, 1.0);

  String get rankTitle {
    if (level >= 10) return 'Global Principal Architect';
    if (level >= 7) return 'Senior Staff Vanguard';
    if (level >= 5) return 'High-Impact Engineer';
    if (level >= 3) return 'ATS Slayer & Rising Builder';
    if (level >= 2) return 'Verified Global Contender';
    return 'Aspiring Global Talent';
  }

  int get completedQuestsCount => quests.where((q) => q.isCompleted).length;

  int get earnedBadgesCount => badges.where((b) => b.isEarned).length;

  UserCareerProfile copyWith({
    String? characterName,
    String? targetRole,
    int? level,
    int? currentXp,
    int? totalXpEarned,
    int? streakDays,
    int? latestAtsScore,
    CareerStage? currentStage,
    List<CareerQuest>? quests,
    List<SkillNode>? skills,
    List<CareerBadge>? badges,
  }) {
    return UserCareerProfile(
      characterName: characterName ?? this.characterName,
      targetRole: targetRole ?? this.targetRole,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      totalXpEarned: totalXpEarned ?? this.totalXpEarned,
      streakDays: streakDays ?? this.streakDays,
      latestAtsScore: latestAtsScore ?? this.latestAtsScore,
      currentStage: currentStage ?? this.currentStage,
      quests: quests ?? this.quests,
      skills: skills ?? this.skills,
      badges: badges ?? this.badges,
    );
  }
}


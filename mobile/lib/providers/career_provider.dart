import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/career_companion_model.dart';

class CareerNotifier extends StateNotifier<UserCareerProfile> {
  CareerNotifier() : super(_initialProfile());

  static UserCareerProfile _initialProfile() {
    return UserCareerProfile(
      characterName: 'Ijul',
      targetRole: 'Global Software & Mobile Engineer',
      level: 2,
      currentXp: 180,
      totalXpEarned: 430,
      streakDays: 5,
      latestAtsScore: null,
      currentStage: CareerStage.jobHunting,
      quests: [
        // Phase 1: Job Hunting Quests
        CareerQuest(
          id: 'q_scan_cv',
          title: 'Run Your First Global ATS Scan',
          description: 'Upload your PDF resume to diagnose international ATS readability and bias risks.',
          stage: CareerStage.jobHunting,
          difficulty: QuestDifficulty.easy,
          xpReward: 50,
          isCompleted: false,
          impactMetricTag: 'ATS Diagnostics',
        ),
        CareerQuest(
          id: 'q_remove_bias',
          title: 'Purge Personal Bias Data (EEOC Standard)',
          description: 'Remove photo, Date of Birth (TTL), Religion, Marital Status, and NIK from your CV.',
          stage: CareerStage.jobHunting,
          difficulty: QuestDifficulty.medium,
          xpReward: 75,
          isCompleted: true,
          impactMetricTag: 'Anti-Bias Shield',
        ),
        CareerQuest(
          id: 'q_star_rewrite',
          title: 'Transform Duties into STAR Achievements',
          description: 'Use the AI Zero-Hallucination Rewrite engine to convert passive tasks into quantified bullets.',
          stage: CareerStage.jobHunting,
          difficulty: QuestDifficulty.hard,
          xpReward: 150,
          isCompleted: false,
          impactMetricTag: '+40% Interview Rate',
        ),

        // Phase 2: First 90 Days (Hired / Onboarding)
        CareerQuest(
          id: 'q_first_pr',
          title: 'Ship Your First Production Pull Request',
          description: 'Clone the company repo, resolve a starter ticket, and merge your first PR within week 1.',
          stage: CareerStage.onboarding,
          difficulty: QuestDifficulty.medium,
          xpReward: 100,
          isCompleted: false,
          impactMetricTag: 'Week 1 Velocity',
        ),
        CareerQuest(
          id: 'q_manager_1on1',
          title: '30-60-90 Day KPI Alignment with Manager',
          description: 'Establish clear, measurable success criteria with your Tech Lead or Engineering Manager.',
          stage: CareerStage.onboarding,
          difficulty: QuestDifficulty.hard,
          xpReward: 125,
          isCompleted: false,
          impactMetricTag: 'Expectation Clarity',
        ),
        CareerQuest(
          id: 'q_onboarding_doc',
          title: 'Improve Internal Onboarding Documentation',
          description: 'Fix at least 1 gap in the team README or setup guide that you encountered while joining.',
          stage: CareerStage.onboarding,
          difficulty: QuestDifficulty.easy,
          xpReward: 60,
          isCompleted: false,
          impactMetricTag: 'Team Multiplier',
        ),

        // Phase 3: Mid-Level Contributor
        CareerQuest(
          id: 'q_perf_opt',
          title: 'Optimize a Critical Bottleneck by 20%+',
          description: 'Benchmark an API endpoint or mobile screen and log the before/after metric for your future CV.',
          stage: CareerStage.midLevel,
          difficulty: QuestDifficulty.boss,
          xpReward: 250,
          isCompleted: false,
          impactMetricTag: 'Quantified Achievement',
        ),
        CareerQuest(
          id: 'q_code_reviews',
          title: 'Deliver 10 High-Signal Peer Code Reviews',
          description: 'Review teammates\' PRs focusing on architecture, edge cases, and security.',
          stage: CareerStage.midLevel,
          difficulty: QuestDifficulty.medium,
          xpReward: 90,
          isCompleted: false,
          impactMetricTag: 'Code Quality',
        ),

        // Phase 4: Senior & Tech Lead Track
        CareerQuest(
          id: 'q_system_rfc',
          title: 'Author & Defend a System Design RFC',
          description: 'Write an architectural proposal with trade-offs and lead the engineering review session.',
          stage: CareerStage.seniorTrack,
          difficulty: QuestDifficulty.boss,
          xpReward: 300,
          isCompleted: false,
          impactMetricTag: 'Staff-Level Scope',
        ),
        CareerQuest(
          id: 'q_mentor_junior',
          title: 'Mentor a Junior Engineer Through a Feature Release',
          description: 'Pair-program and guide a junior colleague from ticket breakdown to production launch.',
          stage: CareerStage.seniorTrack,
          difficulty: QuestDifficulty.hard,
          xpReward: 180,
          isCompleted: false,
          impactMetricTag: 'Leadership Impact',
        ),
      ],
      skills: [
        SkillNode(
          id: 'sk_clean_code',
          title: 'Clean Architecture & Modularity',
          description: 'Structure mobile & backend codebases with clear separation of concerns and testability.',
          branch: SkillBranch.technical,
          currentTier: 2,
          maxTier: 3,
          xpCost: 100,
          requiredLevel: 1,
        ),
        SkillNode(
          id: 'sk_api_perf',
          title: 'High-Throughput API & DB Indexing',
          description: 'Design resilient REST/gRPC APIs with optimized SQL queries and caching layers.',
          branch: SkillBranch.technical,
          currentTier: 1,
          maxTier: 3,
          xpCost: 120,
          requiredLevel: 2,
        ),
        SkillNode(
          id: 'sk_sys_design',
          title: 'Distributed System Design',
          description: 'Master load balancing, message queues, horizontal scaling, and fault tolerance.',
          branch: SkillBranch.architecture,
          currentTier: 1,
          maxTier: 3,
          xpCost: 150,
          requiredLevel: 2,
        ),
        SkillNode(
          id: 'sk_star_story',
          title: 'STAR Impact Storytelling',
          description: 'Articulate engineering work in terms of revenue, latency saved, and business outcomes.',
          branch: SkillBranch.globalOps,
          currentTier: 2,
          maxTier: 3,
          xpCost: 90,
          requiredLevel: 1,
        ),
        SkillNode(
          id: 'sk_async_comm',
          title: 'Async Global Communication',
          description: 'Write crisp RFCs, PR descriptions, and status updates across international timezones.',
          branch: SkillBranch.leadership,
          currentTier: 1,
          maxTier: 3,
          xpCost: 110,
          requiredLevel: 2,
        ),
        SkillNode(
          id: 'sk_tech_mentorship',
          title: 'Engineering Mentorship & Ownership',
          description: 'Elevate team velocity through code reviews, pair programming, and incident leadership.',
          branch: SkillBranch.leadership,
          currentTier: 0,
          maxTier: 3,
          xpCost: 160,
          requiredLevel: 3,
        ),
      ],
      badges: [
        CareerBadge(
          id: 'b_early_adopter',
          title: 'Vanguard Initiate',
          description: 'Started your global career journey on LeveledUp.',
          iconCode: 'rocket',
          isEarned: true,
        ),
        CareerBadge(
          id: 'b_ats_scanned',
          title: 'ATS Challenger',
          description: 'Completed a full international ATS diagnostic scan.',
          iconCode: 'radar',
          isEarned: false,
        ),
        CareerBadge(
          id: 'b_vip_unlocked',
          title: 'Zero-Bias Architect',
          description: 'Unlocked deep ATS fixes and eliminated resume bias.',
          iconCode: 'shield',
          isEarned: false,
        ),
        CareerBadge(
          id: 'b_cv_rewritten',
          title: 'STAR Storyteller',
          description: 'Generated an AI Zero-Hallucination ATS resume.',
          iconCode: 'auto_awesome',
          isEarned: false,
        ),
        CareerBadge(
          id: 'b_first_job',
          title: 'Offer Secured',
          description: 'Transitioned into active On-The-Job Career Companion mode.',
          iconCode: 'workspace_premium',
          isEarned: false,
        ),
        CareerBadge(
          id: 'b_level_5',
          title: 'High-Impact Vanguard',
          description: 'Reached Career Level 5 through consistent quest execution.',
          iconCode: 'military_tech',
          isEarned: false,
        ),
      ],
    );
  }

  /// Switch between Pre-Job Hunt and Post-Job Career Progression phases
  void setCareerStage(CareerStage stage) {
    var updatedBadges = state.badges;
    if (stage != CareerStage.jobHunting) {
      updatedBadges = _unlockBadgeList(updatedBadges, 'b_first_job');
    }
    state = state.copyWith(currentStage: stage, badges: updatedBadges);
  }

  /// Toggle or complete a quest and award XP
  void toggleQuestCompletion(String questId) {
    final idx = state.quests.indexWhere((q) => q.id == questId);
    if (idx == -1) return;

    final quest = state.quests[idx];
    final nowCompleted = !quest.isCompleted;

    final updatedQuests = List<CareerQuest>.from(state.quests);
    updatedQuests[idx] = quest.copyWith(isCompleted: nowCompleted);

    if (nowCompleted) {
      _addXpInternal(quest.xpReward, updatedQuests: updatedQuests);
    } else {
      state = state.copyWith(quests: updatedQuests);
    }
  }

  /// Add a custom real-world work quest or KPI milestone
  void addCustomQuest({
    required String title,
    required String description,
    required CareerStage stage,
    required QuestDifficulty difficulty,
    required String impactTag,
  }) {
    final newQuest = CareerQuest(
      id: 'q_custom_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      stage: stage,
      difficulty: difficulty,
      xpReward: difficulty.defaultXp,
      isCompleted: false,
      impactMetricTag: impactTag.isEmpty ? 'Career KPI' : impactTag,
    );

    state = state.copyWith(quests: [newQuest, ...state.quests]);
  }

  /// Upgrade a node on the RPG Skill Tree
  String? upgradeSkillNode(String skillId) {
    final idx = state.skills.indexWhere((s) => s.id == skillId);
    if (idx == -1) return 'Skill not found';

    final skill = state.skills[idx];
    if (skill.isMaxed) return 'Skill is already at maximum mastery tier!';
    if (state.level < skill.requiredLevel) {
      return 'Requires Career Level ${skill.requiredLevel} to unlock.';
    }

    final updatedSkills = List<SkillNode>.from(state.skills);
    updatedSkills[idx] = skill.copyWith(currentTier: skill.currentTier + 1);

    state = state.copyWith(skills: updatedSkills);
    // Upgrading a skill also grants +40 mastery XP
    _addXpInternal(40);
    return null;
  }

  /// Called when CV is scanned, unlocked, or rewritten to link ATS actions with RPG progression
  void recordAtsMilestone({
    int? atsScore,
    String? questIdToComplete,
    String? badgeIdToUnlock,
    int bonusXp = 50,
  }) {
    var updatedQuests = List<CareerQuest>.from(state.quests);
    if (questIdToComplete != null) {
      final qIdx = updatedQuests.indexWhere((q) => q.id == questIdToComplete);
      if (qIdx != -1 && !updatedQuests[qIdx].isCompleted) {
        updatedQuests[qIdx] = updatedQuests[qIdx].copyWith(isCompleted: true);
      }
    }

    var updatedBadges = List<CareerBadge>.from(state.badges);
    if (badgeIdToUnlock != null) {
      updatedBadges = _unlockBadgeList(updatedBadges, badgeIdToUnlock);
    }

    _addXpInternal(
      bonusXp,
      updatedQuests: updatedQuests,
      updatedBadges: updatedBadges,
      latestAtsScore: atsScore ?? state.latestAtsScore,
    );
  }

  List<CareerBadge> _unlockBadgeList(List<CareerBadge> list, String badgeId) {
    return list.map((b) => b.id == badgeId ? b.copyWith(isEarned: true) : b).toList();
  }

  void _addXpInternal(
    int xpToAdd, {
    List<CareerQuest>? updatedQuests,
    List<CareerBadge>? updatedBadges,
    int? latestAtsScore,
  }) {
    var level = state.level;
    var currentXp = state.currentXp + xpToAdd;
    final totalXp = state.totalXpEarned + xpToAdd;

    while (currentXp >= (level * 250)) {
      currentXp -= (level * 250);
      level++;
    }

    var badges = updatedBadges ?? state.badges;
    if (level >= 5) {
      badges = _unlockBadgeList(badges, 'b_level_5');
    }

    state = state.copyWith(
      level: level,
      currentXp: currentXp,
      totalXpEarned: totalXp,
      quests: updatedQuests ?? state.quests,
      badges: badges,
      latestAtsScore: latestAtsScore,
    );
  }
}

final careerProvider = StateNotifierProvider<CareerNotifier, UserCareerProfile>((ref) {
  return CareerNotifier();
});


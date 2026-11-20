import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../models/career_companion_model.dart';
import '../models/cv_analysis_model.dart';

class CareerNotifier extends StateNotifier<UserCareerProfile> {
  final ApiClient? _injectedClient;
  ApiClient get _apiClient => _injectedClient ?? ApiClient();

  CareerNotifier([ApiClient? apiClient])
      : _injectedClient = apiClient,
        super(_initialProfile()) {
    syncFromBackend();
  }

  static UserCareerProfile _initialProfile() {
    final defaultGap = ApiClient.buildSkillGapReport(
      jobTitle: 'Data Analyst',
      matchedKeywords: const ['SQL', 'Excel', 'Data Visualization'],
      missingKeywords: const [
        'Python',
        'Tableau',
        'Power BI',
        'Statistical Analysis',
        'ETL',
      ],
      language: 'en',
    );

    return UserCareerProfile(
      characterName: 'Ijul',
      targetRole: 'Fresh Graduate Professional',
      level: 2,
      currentXp: 180,
      totalXpEarned: 430,
      streakDays: 5,
      latestAtsScore: null,
      applicationsSent: 3,
      interviewsSecured: 1,
      currentStage: CareerStage.jobHunting,
      quests: [
        // Job Hunt Mode: Scan-Verified Quests
        CareerQuest(
          id: 'q_first_scan',
          title: 'Run Your First ATS Scan',
          description:
              'Upload your CV PDF in the Scanner tab to benchmark your ATS score and detect hidden issues.',
          stage: CareerStage.jobHunting,
          difficulty: QuestDifficulty.easy,
          xpReward: 50,
          isCompleted: false,
          impactMetricTag: 'Verified by Scan',
          verificationType: QuestVerificationType.scanVerified,
        ),
        CareerQuest(
          id: 'q_purge_bias',
          title: 'Purge Personal Bias Data',
          description:
              'Remove headshot photo, Date of Birth (TTL), Religion, Marital Status, and NIK — verified automatically by scan.',
          stage: CareerStage.jobHunting,
          difficulty: QuestDifficulty.medium,
          xpReward: 75,
          isCompleted: false,
          impactMetricTag: 'Verified by Scan',
          verificationType: QuestVerificationType.scanVerified,
          linkedIssueKey: 'personal_info',
        ),
        CareerQuest(
          id: 'q_fix_no_metrics',
          title: 'Add measurable results to 3 bullets',
          description:
              'Include concrete numbers, percentages, or scale metrics in your CV bullets and re-scan to verify.',
          stage: CareerStage.jobHunting,
          difficulty: QuestDifficulty.hard,
          xpReward: 100,
          isCompleted: false,
          impactMetricTag: 'Verified by Scan',
          verificationType: QuestVerificationType.scanVerified,
          linkedIssueKey: 'no_metrics',
        ),
        // Job Hunt Mode: Secondary Self-Reported Quests
        CareerQuest(
          id: 'q_self_linkedin',
          title: 'Update LinkedIn headline with target role keywords',
          description:
              'Align your LinkedIn headline and summary with the matched keywords from your CV scan.',
          stage: CareerStage.jobHunting,
          difficulty: QuestDifficulty.easy,
          xpReward: 40,
          isCompleted: false,
          impactMetricTag: 'Self-reported',
          verificationType: QuestVerificationType.selfReported,
        ),
        CareerQuest(
          id: 'q_self_portfolio',
          title: 'Showcase 3 documented projects or portfolio samples',
          description:
              'Highlight 3 real projects (case studies, GitHub repos, campaigns, or financial models) with clear outcomes.',
          stage: CareerStage.jobHunting,
          difficulty: QuestDifficulty.medium,
          xpReward: 60,
          isCompleted: false,
          impactMetricTag: 'Self-reported',
          verificationType: QuestVerificationType.selfReported,
        ),
        CareerQuest(
          id: 'q_self_applications',
          title: 'Send 5 tailored job applications',
          description:
              'Apply to 5 target roles using your newly exported ATS-ready PDF CV.',
          stage: CareerStage.jobHunting,
          difficulty: QuestDifficulty.medium,
          xpReward: 75,
          isCompleted: false,
          impactMetricTag: 'Self-reported',
          verificationType: QuestVerificationType.selfReported,
        ),

        // Hired Mode: First 90 Days Checklist
        CareerQuest(
          id: 'hired_log_first_win',
          title: 'Log your first work win in the Brag Doc',
          description:
              'Record a real deliverable in the Wins tab to generate a Zero-Hallucination STAR bullet.',
          stage: CareerStage.onboarding,
          difficulty: QuestDifficulty.medium,
          xpReward: 75,
          isCompleted: false,
          impactMetricTag: 'Verified by Win',
          verificationType: QuestVerificationType.winVerified,
        ),
        CareerQuest(
          id: 'hired_merge_win_cv',
          title: 'Merge a logged work win into your living CV',
          description:
              'Use "Add to my CV" in the Wins tab so your CV stays updated while employed.',
          stage: CareerStage.onboarding,
          difficulty: QuestDifficulty.hard,
          xpReward: 100,
          isCompleted: false,
          impactMetricTag: 'Verified by Win',
          verificationType: QuestVerificationType.winVerified,
        ),
        CareerQuest(
          id: 'hired_align_goals',
          title: 'Meet manager & define 30/60/90-day goals',
          description:
              'Align on clear expectations, KPIs, and first-quarter priorities with your manager.',
          stage: CareerStage.onboarding,
          difficulty: QuestDifficulty.medium,
          xpReward: 60,
          isCompleted: false,
          impactMetricTag: 'Self-reported',
          verificationType: QuestVerificationType.selfReported,
        ),
        CareerQuest(
          id: 'hired_first_deliverable',
          title: 'Document your first completed project or workflow',
          description:
              'Capture the problem solved, tools used, and measurable outcome of your first task.',
          stage: CareerStage.onboarding,
          difficulty: QuestDifficulty.easy,
          xpReward: 50,
          isCompleted: false,
          impactMetricTag: 'Self-reported',
          verificationType: QuestVerificationType.selfReported,
        ),
        CareerQuest(
          id: 'hired_30day_feedback',
          title: 'Request 30-day feedback from your manager or peer',
          description:
              'Ask for early feedback on execution, communication, and collaboration.',
          stage: CareerStage.onboarding,
          difficulty: QuestDifficulty.easy,
          xpReward: 50,
          isCompleted: false,
          impactMetricTag: 'Self-reported',
          verificationType: QuestVerificationType.selfReported,
        ),
      ],
      skills: const [],
      badges: [
        CareerBadge(
          id: 'b_ats_scanned',
          title: 'ATS Baseline Set',
          description: 'Completed your first evidence-based ATS CV audit.',
          iconCode: 'radar',
          isEarned: false,
        ),
        CareerBadge(
          id: 'b_score_improved',
          title: 'Verified Improver',
          description: 'Fixed ATS flaws and raised your CV score on a re-scan.',
          iconCode: 'trending_up',
          isEarned: false,
        ),
        CareerBadge(
          id: 'b_vip_unlocked',
          title: 'Zero-Bias Architect',
          description: 'Unlocked deep ATS fixes and Before/After examples.',
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
          id: 'b_first_win',
          title: 'Impact Documented',
          description: 'Converted a real work win into an ATS-ready STAR bullet.',
          iconCode: 'emoji_events',
          isEarned: false,
        ),
        CareerBadge(
          id: 'b_first_job',
          title: 'Offer Secured!',
          description: 'Activated your First 90 Days onboarding checklist.',
          iconCode: 'workspace_premium',
          isEarned: false,
        ),
      ],
      workWins: const [],
      checkIns: [
        DailyCheckIn(
          id: 'ci_seed_1',
          focusArea: 'Deep Work & Shipping',
          confidenceRating: 4,
          note: 'Wrapped up API validation and reviewed mobile state flow.',
          dateKey: '2026-11-19',
          dateLabel: 'Yesterday',
        ),
      ],
      scoreHistory: const [],
      skillGap: defaultGap,
      needsQuarterlyReminder: true,
    );
  }

  /// Synchronize score history, scan-verified quests, wins, and skill gap from MySQL
  Future<void> syncFromBackend({bool simulateReminder = false}) async {
    try {
      final progressData = await _apiClient.fetchProgress();
      final winsData = await _apiClient.fetchWins(
        simulateReminder: simulateReminder,
      );

      if (progressData != null) {
        final rawHistory =
            progressData['scoreHistory'] as List<dynamic>? ?? const [];
        final parsedHistory = rawHistory
            .map((e) => ScanScorePoint.fromJson(e as Map<String, dynamic>))
            .toList();

        final rawQuests = progressData['quests'] as List<dynamic>? ?? const [];
        final parsedQuests = rawQuests
            .map((e) => CareerQuest.fromJson(e as Map<String, dynamic>))
            .toList();

        final rawSkillGap = progressData['skillGap'];
        final parsedSkillGap = rawSkillGap is Map<String, dynamic>
            ? SkillGapReport.fromJson(rawSkillGap)
            : state.skillGap;

        final profileJson =
            progressData['profile'] as Map<String, dynamic>? ?? const {};
        final modeStr = profileJson['careerMode']?.toString();
        final backendStage = CareerStageExtension.fromApiMode(modeStr);

        final latestScore = parsedHistory.isNotEmpty
            ? parsedHistory.last.overallScore
            : state.latestAtsScore;

        state = state.copyWith(
          targetRole:
              profileJson['targetRole']?.toString() ?? state.targetRole,
          currentStage: backendStage,
          latestAtsScore: latestScore,
          scoreHistory:
              parsedHistory.isNotEmpty ? parsedHistory : state.scoreHistory,
          quests: parsedQuests.isNotEmpty ? parsedQuests : state.quests,
          skillGap: parsedSkillGap,
        );
      }

      if (winsData != null) {
        final rawWins = winsData['wins'] as List<dynamic>? ?? const [];
        final parsedWins = rawWins
            .map((e) => WorkWin.fromJson(e as Map<String, dynamic>))
            .toList();
        final needsReminder = winsData['needsQuarterlyReminder'] == true;
        final msg = winsData['reminderMessageEn']?.toString();

        state = state.copyWith(
          workWins: parsedWins,
          needsQuarterlyReminder: needsReminder,
          reminderMessage: msg,
        );
      }
    } catch (_) {
      // Offline mode continues using local state
    }
  }

  /// Clear pending congratulation toast badge after displaying it
  void clearPendingToastBadge() {
    if (state.pendingToastBadge != null) {
      state = state.copyWith(clearToastBadge: true);
    }
  }

  void dismissQuarterlyReminder() {
    state = state.copyWith(needsQuarterlyReminder: false);
  }

  /// Switch between Job Hunt mode and Hired (First 90 Days) mode
  Future<void> setCareerStage(CareerStage stage) async {
    final normalized =
        stage == CareerStage.jobHunting ? CareerStage.jobHunting : CareerStage.onboarding;
    CareerBadge? toastBadge;
    var updatedBadges = state.badges;

    if (normalized == CareerStage.onboarding) {
      final wasEarned =
          updatedBadges.any((b) => b.id == 'b_first_job' && b.isEarned);
      updatedBadges = _unlockBadgeList(updatedBadges, 'b_first_job');
      if (!wasEarned) {
        toastBadge =
            updatedBadges.firstWhere((b) => b.id == 'b_first_job');
      }
    }

    state = state.copyWith(
      currentStage: normalized,
      badges: updatedBadges,
      pendingToastBadge: toastBadge,
    );

    await _apiClient.switchCareerMode(
      mode: normalized.apiMode,
      displayName: state.characterName,
      targetRole: state.targetRole,
    );
    await syncFromBackend();
  }

  /// 1-Tap "I got the job" action -> switches to First 90 Days checklist
  Future<void> markGotTheJob() async {
    await setCareerStage(CareerStage.onboarding);
  }

  /// Update player name, target role, and initial stage upon Login / Registration
  void updateProfileIdentity({
    String? name,
    String? targetRole,
    CareerStage? stage,
  }) {
    final normalized = stage != null
        ? (stage == CareerStage.jobHunting
            ? CareerStage.jobHunting
            : CareerStage.onboarding)
        : state.currentStage;
    var updatedBadges = state.badges;
    if (normalized != CareerStage.jobHunting) {
      updatedBadges = _unlockBadgeList(updatedBadges, 'b_first_job');
    }
    state = state.copyWith(
      characterName: name ?? state.characterName,
      targetRole: targetRole ?? state.targetRole,
      currentStage: normalized,
      badges: updatedBadges,
    );
  }

  /// Called when a CV scan finishes to update Score History, auto-generated quests, and Skill Gap
  Future<void> recordScanResult(
    AnalysisResult result, {
    String? scanToken,
    bool isUnlockAction = false,
  }) async {
    final token =
        scanToken ?? 'scn_${DateTime.now().millisecondsSinceEpoch}';
    final currentIssueKeys = result.issues.map((i) => i.id).toList();
    final currentKeySet = currentIssueKeys.toSet();

    var history = List<ScanScorePoint>.from(state.scoreHistory);
    CareerBadge? toastBadge;
    var updatedBadges = List<CareerBadge>.from(state.badges);

    if (!isUnlockAction) {
      var delta = 0;
      final fixed = <FixedIssueItem>[];
      if (history.isNotEmpty) {
        final prev = history.last;
        delta = result.overallScore - prev.overallScore;
        for (final prevKey in prev.issueKeys) {
          if (!currentKeySet.contains(prevKey)) {
            fixed.add(
              FixedIssueItem(
                key: prevKey,
                title: _humanizeIssueKey(prevKey),
              ),
            );
          }
        }
      }

      final newPoint = ScanScorePoint(
        scanToken: token,
        fileName: result.fileName,
        overallScore: result.overallScore,
        scoreDelta: delta,
        language: result.language,
        jobTitle: result.keywordMatch?.jobTitle ?? state.targetRole,
        issueCount: result.issues.length,
        issueKeys: currentIssueKeys,
        fixedIssues: fixed,
        createdAtLabel: 'Just now',
      );
      history.add(newPoint);

      if (history.length == 1) {
        final alreadyEarned =
            updatedBadges.any((b) => b.id == 'b_ats_scanned' && b.isEarned);
        updatedBadges = _unlockBadgeList(updatedBadges, 'b_ats_scanned');
        if (!alreadyEarned) {
          toastBadge =
              updatedBadges.firstWhere((b) => b.id == 'b_ats_scanned');
        }
      } else if (delta > 0 || fixed.isNotEmpty) {
        updatedBadges = _unlockBadgeList(updatedBadges, 'b_score_improved');
        toastBadge = CareerBadge(
          id: 'b_score_improved',
          title: delta > 0 ? 'Score Up +$delta pts!' : 'ATS Flaws Resolved!',
          description: fixed.isNotEmpty
              ? 'Verified fix: ${fixed.map((f) => f.title).take(2).join(', ')}'
              : 'Your ATS readiness score improved to ${result.overallScore}/100.',
          iconCode: 'trending_up',
          isEarned: true,
        );
      }
    } else {
      final alreadyEarned =
          updatedBadges.any((b) => b.id == 'b_vip_unlocked' && b.isEarned);
      updatedBadges = _unlockBadgeList(updatedBadges, 'b_vip_unlocked');
      if (!alreadyEarned) {
        toastBadge =
            updatedBadges.firstWhere((b) => b.id == 'b_vip_unlocked');
      }
    }

    // Auto-verify scan quests & generate dynamic quests from detected issues
    final hasBiasIssue = result.issues.any(
      (i) =>
          i.category == 'personal_info' ||
          const {
            'photo',
            'dob_age',
            'dob_marital',
            'marital_status',
            'religion',
            'national_id',
          }.contains(i.id),
    );

    var updatedQuests = List<CareerQuest>.from(state.quests);

    void upsertScanQuest({
      required String id,
      required String title,
      required String description,
      required bool completed,
      String? linkedIssueKey,
    }) {
      final idx = updatedQuests.indexWhere((q) => q.id == id);
      if (idx != -1) {
        updatedQuests[idx] = updatedQuests[idx].copyWith(
          title: title,
          description: description,
          isCompleted: completed,
          verificationType: QuestVerificationType.scanVerified,
        );
      } else {
        updatedQuests.insert(
          2,
          CareerQuest(
            id: id,
            title: title,
            description: description,
            stage: CareerStage.jobHunting,
            difficulty: QuestDifficulty.medium,
            xpReward: 75,
            isCompleted: completed,
            impactMetricTag: 'Verified by Scan',
            verificationType: QuestVerificationType.scanVerified,
            linkedIssueKey: linkedIssueKey,
          ),
        );
      }
    }

    upsertScanQuest(
      id: 'q_first_scan',
      title: 'Run Your First ATS Scan',
      description:
          'Upload your CV PDF in the Scanner to benchmark your ATS score and detect hidden issues.',
      completed: true,
    );

    upsertScanQuest(
      id: 'q_purge_bias',
      title: 'Purge Personal Bias Data',
      description:
          'Remove headshot photo, Date of Birth (TTL), Religion, Marital Status, and NIK — verified automatically by scan.',
      completed: !hasBiasIssue,
      linkedIssueKey: 'personal_info',
    );

    // Dynamic issue-based quests
    final issueQuestTemplates = <String, Map<String, String>>{
      'no_metrics': {
        'id': 'q_fix_no_metrics',
        'title': 'Add measurable results to 3 bullets',
        'description':
            'Include concrete numbers, percentages, or scale metrics in your CV bullets and re-scan to verify.',
      },
      'duties': {
        'id': 'q_fix_duties',
        'title': 'Rewrite passive duties into action-driven STAR bullets',
        'description':
            'Replace passive "Responsible for..." lines with strong action verbs and outcomes, then re-scan.',
      },
      'missing_core_keywords': {
        'id': 'q_fix_missing_keywords',
        'title': 'Add missing target role keywords to your CV',
        'description':
            'Incorporate key competencies from your Skill Gap list into your CV and verify with a re-scan.',
      },
      'missing_keywords': {
        'id': 'q_fix_missing_keywords',
        'title': 'Add missing target role keywords to your CV',
        'description':
            'Incorporate key competencies from your Skill Gap list into your CV and verify with a re-scan.',
      },
      'cliche_words': {
        'id': 'q_fix_cliche_words',
        'title': 'Replace generic clichés with concrete evidence',
        'description':
            'Remove subjective phrases ("hard-working", "under pressure") and verify with a re-scan.',
      },
      'cliches': {
        'id': 'q_fix_cliche_words',
        'title': 'Replace generic clichés with concrete evidence',
        'description':
            'Remove subjective phrases ("hard-working", "under pressure") and verify with a re-scan.',
      },
    };

    // For any issue currently present or previously generated as a quest, update its completion
    for (final entry in issueQuestTemplates.entries) {
      final issueKey = entry.key;
      final tpl = entry.value;
      final qId = tpl['id']!;
      final existsInQuests = updatedQuests.any((q) => q.id == qId);
      final presentInCurrentScan = currentKeySet.contains(issueKey);

      if (presentInCurrentScan || existsInQuests) {
        upsertScanQuest(
          id: qId,
          title: tpl['title']!,
          description: tpl['description']!,
          completed: !presentInCurrentScan && history.isNotEmpty,
          linkedIssueKey: issueKey,
        );
      }
    }

    // Update role-agnostic bilingual Skill Gap from scan keywordMatch
    final kw = result.keywordMatch;
    final updatedSkillGap = ApiClient.buildSkillGapReport(
      jobTitle: kw?.jobTitle ?? state.targetRole,
      missingKeywords: kw?.missing ?? const [],
      matchedKeywords: kw?.matched ?? const [],
      language: result.language,
    );

    _addXpInternal(
      isUnlockAction ? 60 : 50,
      updatedQuests: updatedQuests,
      updatedBadges: updatedBadges,
      latestAtsScore: result.overallScore,
      updatedScoreHistory: history,
      updatedSkillGap: updatedSkillGap,
      updatedTargetRole: kw?.jobTitle ?? state.targetRole,
      pendingToastBadge: toastBadge,
    );

    await syncFromBackend();
  }

  static String _humanizeIssueKey(String key) {
    switch (key) {
      case 'photo':
        return 'Removed Headshot Photo';
      case 'dob_age':
      case 'dob_marital':
        return 'Removed Date of Birth / Personal Bias';
      case 'marital_status':
        return 'Removed Marital Status';
      case 'religion':
        return 'Removed Religious Affiliation';
      case 'national_id':
        return 'Removed National ID (NIK)';
      case 'duties':
        return 'Converted Passive Duties to STAR Bullets';
      case 'no_metrics':
        return 'Added Quantifiable Impact Metrics';
      case 'cliche_words':
      case 'cliches':
        return 'Removed Subjective Clichés';
      case 'missing_core_keywords':
      case 'missing_keywords':
        return 'Added Core Role Keywords';
      case 'too_short':
        return 'Expanded CV Depth';
      default:
        return 'Resolved $key';
    }
  }

  /// Stores the latest AI-rewritten CV as the base living CV for merging wins
  void setLatestRewrittenCv(ImprovedCV cv) {
    var updatedBadges = List<CareerBadge>.from(state.badges);
    final alreadyEarned =
        updatedBadges.any((b) => b.id == 'b_cv_rewritten' && b.isEarned);
    updatedBadges = _unlockBadgeList(updatedBadges, 'b_cv_rewritten');
    final toast = !alreadyEarned
        ? updatedBadges.firstWhere((b) => b.id == 'b_cv_rewritten')
        : null;

    _addXpInternal(
      75,
      updatedBadges: updatedBadges,
      latestMergedCv: cv,
      pendingToastBadge: toast,
    );
  }

  /// Log a real-world work win into the Brag Doc, generating a Zero-Hallucination STAR bullet
  Future<WorkWin?> addWorkWin({
    required String title,
    required String impactMetric,
    required SkillBranch branch,
    String? language,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return null;

    final lang = language ??
        ApiClient.detectLanguage('$cleanTitle $impactMetric');
    final apiRes = await _apiClient.createWorkWin(
      title: cleanTitle,
      impactMetric: impactMetric.trim(),
      category: branch.apiCategory,
      language: lang,
    );

    late final WorkWin createdWin;
    CareerBadge? toastBadge;

    if (apiRes != null && apiRes['win'] is Map<String, dynamic>) {
      createdWin = WorkWin.fromJson(apiRes['win'] as Map<String, dynamic>);
      if (apiRes['badgeUnlocked'] is Map<String, dynamic>) {
        final bJson = apiRes['badgeUnlocked'] as Map<String, dynamic>;
        toastBadge = CareerBadge(
          id: bJson['id']?.toString() ?? 'b_first_win',
          title: bJson['title']?.toString() ?? 'Impact Documented',
          description: bJson['description']?.toString() ??
              'Converted your first achievement into an ATS STAR bullet.',
          iconCode: 'emoji_events',
          isEarned: true,
        );
      }
    } else {
      final isFirst = state.workWins.isEmpty;
      createdWin = WorkWin(
        id: 'w_${DateTime.now().millisecondsSinceEpoch}',
        title: cleanTitle,
        impactMetric: impactMetric.trim(),
        branch: branch,
        category: branch.apiCategory,
        language: lang,
        dateLabel: 'Today',
        stage: state.currentStage,
      );
      if (isFirst) {
        toastBadge = CareerBadge(
          id: 'b_first_win',
          title: 'Impact Documented',
          description:
              'Converted your first achievement into an ATS STAR bullet.',
          iconCode: 'emoji_events',
          isEarned: true,
        );
      }
    }

    // Mark win-verified quest 'hired_log_first_win' complete
    final updatedQuests = state.quests.map((q) {
      if (q.id == 'hired_log_first_win') {
        return q.copyWith(isCompleted: true);
      }
      return q;
    }).toList();

    final updatedBadges = _unlockBadgeList(state.badges, 'b_first_win');

    _addXpInternal(
      50,
      updatedWorkWins: [createdWin, ...state.workWins],
      updatedQuests: updatedQuests,
      updatedBadges: updatedBadges,
      needsQuarterlyReminder: false,
      pendingToastBadge: toastBadge,
    );

    return createdWin;
  }

  /// Merge selected Brag Doc wins into the user's living CV ("Add to my CV")
  Future<ImprovedCV> mergeWinsIntoLivingCv({
    required List<String> winIds,
    ImprovedCV? currentScannerCv,
    String? scanToken,
  }) async {
    final selectedWins = state.workWins
        .where((w) => winIds.contains(w.id))
        .toList();
    final winsToUse =
        selectedWins.isNotEmpty ? selectedWins : state.workWins.take(3).toList();

    final baseCv = currentScannerCv ?? state.latestMergedCv;
    final mergedCv = await _apiClient.mergeWinsIntoCv(
      winsToMerge: winsToUse,
      scanToken: scanToken,
      baseCv: baseCv,
    );

    final effectiveToken = scanToken ?? 'living_cv';
    final selectedIdSet = winsToUse.map((w) => w.id).toSet();
    final updatedWins = state.workWins.map((w) {
      if (selectedIdSet.contains(w.id)) {
        return w.copyWith(mergedIntoScanToken: effectiveToken);
      }
      return w;
    }).toList();

    final updatedQuests = state.quests.map((q) {
      if (q.id == 'hired_merge_win_cv') {
        return q.copyWith(isCompleted: true);
      }
      return q;
    }).toList();

    _addXpInternal(
      60,
      updatedWorkWins: updatedWins,
      updatedQuests: updatedQuests,
      latestMergedCv: mergedCv,
      pendingToastBadge: CareerBadge(
        id: 'b_living_cv',
        title: 'Living CV Updated!',
        description:
            'Merged ${winsToUse.length} STAR bullet(s) into your CV — ready for PDF download.',
        iconCode: 'auto_awesome',
        isEarned: true,
      ),
    );

    return mergedCv;
  }

  /// Submit or update today's Daily Career Check-In (kept behind enableDailyCheckIn feature flag)
  bool submitDailyCheckIn({
    required String focusArea,
    required int confidenceRating,
    required String note,
  }) {
    final todayKey = UserCareerProfile.todayDateKey();
    final alreadyDoneToday = state.hasCheckedInToday;

    final entry = DailyCheckIn(
      id: 'ci_${DateTime.now().millisecondsSinceEpoch}',
      focusArea: focusArea,
      confidenceRating: confidenceRating.clamp(1, 5),
      note: note.trim(),
      dateKey: todayKey,
      dateLabel: 'Today',
    );

    final remaining =
        state.checkIns.where((c) => c.dateKey != todayKey).toList();
    final updatedCheckIns = [entry, ...remaining];

    if (alreadyDoneToday) {
      state = state.copyWith(checkIns: updatedCheckIns);
      return false;
    }

    _addXpInternal(
      35,
      updatedStreak: state.streakDays + 1,
      updatedCheckIns: updatedCheckIns,
    );
    return true;
  }

  /// Toggles a quest if and only if it is self-reported.
  /// Returns an explanation message if the quest is scan_verified or win_verified.
  Future<String?> toggleQuestCompletion(String questId) async {
    final idx = state.quests.indexWhere((q) => q.id == questId);
    if (idx == -1) return null;

    final quest = state.quests[idx];
    if (quest.verificationType == QuestVerificationType.scanVerified) {
      return 'This item is verified automatically when you scan your updated CV in the Scanner tab.';
    }
    if (quest.verificationType == QuestVerificationType.winVerified) {
      return 'This item is verified automatically when you log and merge a win in the Wins tab.';
    }

    final nowCompleted = !quest.isCompleted;
    final updatedQuests = List<CareerQuest>.from(state.quests);
    updatedQuests[idx] = quest.copyWith(isCompleted: nowCompleted);

    if (nowCompleted) {
      _addXpInternal(quest.xpReward, updatedQuests: updatedQuests);
    } else {
      state = state.copyWith(quests: updatedQuests);
    }

    await _apiClient.toggleSelfReportedQuest(questId);
    return null;
  }

  /// Add a custom self-reported checklist item
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
      stage: stage == CareerStage.jobHunting
          ? CareerStage.jobHunting
          : CareerStage.onboarding,
      difficulty: difficulty,
      xpReward: difficulty.defaultXp,
      isCompleted: false,
      impactMetricTag: 'Self-reported',
      verificationType: QuestVerificationType.selfReported,
    );

    state = state.copyWith(quests: [...state.quests, newQuest]);
  }

  /// Legacy compatibility helper for cv_provider / tests
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
    CareerBadge? toast;
    if (badgeIdToUnlock != null) {
      final already =
          updatedBadges.any((b) => b.id == badgeIdToUnlock && b.isEarned);
      updatedBadges = _unlockBadgeList(updatedBadges, badgeIdToUnlock);
      if (!already) {
        final matched = updatedBadges.where((b) => b.id == badgeIdToUnlock);
        if (matched.isNotEmpty) toast = matched.first;
      }
    }

    _addXpInternal(
      bonusXp,
      updatedQuests: updatedQuests,
      updatedBadges: updatedBadges,
      latestAtsScore: atsScore ?? state.latestAtsScore,
      pendingToastBadge: toast,
    );
  }

  List<CareerBadge> _unlockBadgeList(List<CareerBadge> list, String badgeId) {
    return list
        .map((b) => b.id == badgeId ? b.copyWith(isEarned: true) : b)
        .toList();
  }

  void _addXpInternal(
    int xpToAdd, {
    List<CareerQuest>? updatedQuests,
    List<CareerBadge>? updatedBadges,
    int? latestAtsScore,
    int? updatedStreak,
    List<WorkWin>? updatedWorkWins,
    List<DailyCheckIn>? updatedCheckIns,
    List<ScanScorePoint>? updatedScoreHistory,
    SkillGapReport? updatedSkillGap,
    String? updatedTargetRole,
    bool? needsQuarterlyReminder,
    ImprovedCV? latestMergedCv,
    CareerBadge? pendingToastBadge,
  }) {
    var level = state.level;
    var currentXp = state.currentXp + xpToAdd;
    final totalXp = state.totalXpEarned + xpToAdd;

    while (currentXp >= (level * 250)) {
      currentXp -= (level * 250);
      level++;
    }

    state = state.copyWith(
      targetRole: updatedTargetRole ?? state.targetRole,
      level: level,
      currentXp: currentXp,
      totalXpEarned: totalXp,
      streakDays: updatedStreak ?? state.streakDays,
      quests: updatedQuests ?? state.quests,
      badges: updatedBadges ?? state.badges,
      latestAtsScore: latestAtsScore ?? state.latestAtsScore,
      workWins: updatedWorkWins ?? state.workWins,
      checkIns: updatedCheckIns ?? state.checkIns,
      scoreHistory: updatedScoreHistory ?? state.scoreHistory,
      skillGap: updatedSkillGap ?? state.skillGap,
      needsQuarterlyReminder:
          needsQuarterlyReminder ?? state.needsQuarterlyReminder,
      latestMergedCv: latestMergedCv ?? state.latestMergedCv,
      pendingToastBadge: pendingToastBadge,
    );
  }
}

final careerProvider =
    StateNotifierProvider<CareerNotifier, UserCareerProfile>((ref) {
  return CareerNotifier();
});

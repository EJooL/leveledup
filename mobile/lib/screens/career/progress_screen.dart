import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/career_icons.dart';
import '../../models/career_companion_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/career_provider.dart';
import '../../widgets/career_icon_badge.dart';
import '../../widgets/placeholder_rich_text.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const ProgressScreen({
    super.key,
    this.onNavigateTab,
  });

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  String _activeSection = 'all'; // 'all', 'checklist', 'skill_gap'
  String? _roleOverride;
  String? _langOverride;
  final Set<String> _expandedQuestIds = {};

  static String _shortVerificationTag(QuestVerificationType type) {
    switch (type) {
      case QuestVerificationType.scanVerified:
        return 'Auto · Scan';
      case QuestVerificationType.winVerified:
        return 'Auto · Win';
      case QuestVerificationType.selfReported:
        return 'Manual';
    }
  }

  void _showAddSelfReportedGoalDialog(CareerStage activeMode) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          title: const Row(
            children: [
              Icon(Icons.add_task_rounded, color: AppColors.terracottaBright),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Add Self-Reported Goal',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add a custom job-hunt or onboarding task to your personal checklist.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: AppColors.white),
                  decoration: const InputDecoration(
                    labelText: 'Checklist Goal',
                    hintText: 'e.g. Tailor CV for 3 Data Analyst openings',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.white),
                  decoration: const InputDecoration(
                    labelText: 'Concrete Deliverable',
                    hintText: 'Include SQL & Tableau project metrics',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                ref.read(careerProvider.notifier).addCustomQuest(
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim().isEmpty
                          ? 'Self-reported career milestone.'
                          : descCtrl.text.trim(),
                      stage: activeMode,
                      difficulty: QuestDifficulty.easy,
                      impactTag: 'Self-reported',
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Add Goal'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleQuestTap(CareerQuest quest) async {
    final msg = await ref
        .read(careerProvider.notifier)
        .toggleQuestCompletion(quest.id);
    if (!mounted) return;
    if (msg != null) {
      final isWinQuest =
          quest.verificationType == QuestVerificationType.winVerified;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            content: Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: AppColors.terracottaBright,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    msg,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                if (widget.onNavigateTab != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      widget.onNavigateTab!(isWinQuest ? 2 : 1);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.terracottaBright,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      isWinQuest ? 'Open Wins' : 'Open Scanner',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(careerProvider);
    final isHired = profile.isHiredMode;
    final modeQuests = profile.activeModeQuests;

    // Resolve Skill Gap report (from scan data or role selector preview)
    final baseSkillGap = profile.skillGap;
    final effectiveLang = _langOverride ?? baseSkillGap.language;
    final effectiveSkillGap = (_roleOverride != null || _langOverride != null)
        ? ApiClient.buildSkillGapReport(
            jobTitle: _roleOverride ?? baseSkillGap.jobTitle,
            missingKeywords: _roleOverride != null &&
                    _roleOverride != baseSkillGap.jobTitle
                ? const []
                : baseSkillGap.missingKeywords,
            matchedKeywords: _roleOverride != null &&
                    _roleOverride != baseSkillGap.jobTitle
                ? const []
                : baseSkillGap.matchedKeywords,
            language: effectiveLang,
          )
        : baseSkillGap;

    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Crisp Header + Sign Out
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Verified Progress',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Sign out',
                    onPressed: () => ref.read(authProvider.notifier).signOut(),
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2. Slim Single-Row Mode Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isHired
                        ? AppColors.emerald.withValues(alpha: 0.45)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isHired
                          ? Icons.verified_outlined
                          : Icons.work_outline_rounded,
                      color: isHired
                          ? AppColors.emerald
                          : AppColors.terracottaBright,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isHired ? 'First 90 Days' : 'Job Hunt Mode',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isHired)
                      OutlinedButton(
                        onPressed: () => ref
                            .read(careerProvider.notifier)
                            .setCareerStage(CareerStage.jobHunting),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Job Hunt',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(careerProvider.notifier).markGotTheJob(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracotta,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'I got the job',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Compact 3-Chip Filter Bar (Fits cleanly on 360px without clipping)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChipPill(
                    label: 'All',
                    selected: _activeSection == 'all',
                    onTap: () => setState(() => _activeSection = 'all'),
                  ),
                  _FilterChipPill(
                    label:
                        'Checklist (${profile.activeModeCompletedCount}/${profile.activeModeTotalCount})',
                    selected: _activeSection == 'checklist',
                    onTap: () => setState(() => _activeSection = 'checklist'),
                  ),
                  _FilterChipPill(
                    label: 'Skill Gap (${effectiveSkillGap.gaps.length})',
                    selected: _activeSection == 'skill_gap',
                    onTap: () => setState(() => _activeSection = 'skill_gap'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ---------------------------------------------------------------
              // SECTION A: SCORE HISTORY TIMELINE ("54 -> 71 -> 82")
              // ---------------------------------------------------------------
              if (_activeSection == 'all') ...[
                _buildScoreHistorySection(profile),
                const SizedBox(height: 24),
              ],

              // ---------------------------------------------------------------
              // SECTION B: VERIFIED CHECKLIST ("3 of 6 done" + accurate bar)
              // ---------------------------------------------------------------
              if (_activeSection == 'all' || _activeSection == 'checklist') ...[
                _buildChecklistSection(profile, modeQuests),
                const SizedBox(height: 24),
              ],

              // ---------------------------------------------------------------
              // SECTION C: ROLE-AGNOSTIC BILINGUAL SKILL GAP (Replaces Skill Tree)
              // ---------------------------------------------------------------
              if (_activeSection == 'all' || _activeSection == 'skill_gap') ...[
                _buildSkillGapSection(effectiveSkillGap),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreHistorySection(UserCareerProfile profile) {
    final history = profile.scoreHistory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timeline_rounded,
                    color: AppColors.terracottaBright,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ATS Score History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              if (history.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    profile.timelineLabel,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.terracottaBright,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Scan your CV to track score changes.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                if (widget.onNavigateTab != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => widget.onNavigateTab!(1),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.terracottaBright,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Scan CV',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          ...history.reversed.map((point) {
            final isPositive = point.scoreDelta > 0;
            final scoreColor = AppColors.getScoreColor(point.overallScore);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPositive
                      ? AppColors.emerald.withValues(alpha: 0.45)
                      : AppColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${point.overallScore}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: scoreColor,
                              ),
                            ),
                            Text(
                              '/100',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                              ),
                            ),
                            if (point.scoreDelta != 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                isPositive
                                    ? '+${point.scoreDelta} pts'
                                    : '${point.scoreDelta} pts',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: isPositive
                                      ? AppColors.emerald
                                      : AppColors.crimson,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          point.createdAtLabel,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${point.fileName} · ${point.jobTitle}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  if (point.fixedIssues.isNotEmpty) ...[
                    const Divider(
                      color: AppColors.border,
                      height: 24,
                    ),
                    ...point.fixedIssues.map((fi) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 16,
                              color: AppColors.emerald,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Fixed: ${fi.title}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.emerald,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildChecklistSection(
    UserCareerProfile profile,
    List<CareerQuest> modeQuests,
  ) {
    final pct = (profile.activeModeProgressFraction * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                profile.isHiredMode
                    ? 'First 90 Days Checklist'
                    : 'Job-Hunt & ATS Checklist',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$pct%',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.emerald,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Accurate Progress Bar bound strictly to completedCount / totalCount
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: profile.activeModeProgressFraction,
            minHeight: 8,
            backgroundColor: AppColors.surfaceElevated,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.emerald,
            ),
          ),
        ),
        const SizedBox(height: 16),

        ...modeQuests.map((quest) {
          final isVerifiedType = !quest.isManual;
          final isExpanded = _expandedQuestIds.contains(quest.id);
          final isWinQuest =
              quest.verificationType == QuestVerificationType.winVerified;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: quest.isCompleted
                      ? AppColors.emerald.withValues(alpha: 0.45)
                      : AppColors.border,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedQuestIds.remove(quest.id);
                    } else {
                      _expandedQuestIds.add(quest.id);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CareerIconBadge(
                            icon: CareerIcons.forQuest(quest),
                            accentColor: CareerIcons.forQuestAccent(quest),
                            size: 32,
                            radius: 8,
                            iconSize: 16,
                            showCompletedBadge: quest.isCompleted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  quest.title,
                                  maxLines: isExpanded ? 3 : 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: quest.isCompleted
                                        ? AppColors.textSecondary
                                        : AppColors.white,
                                    decoration: quest.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _shortVerificationTag(quest.verificationType),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isVerifiedType
                                        ? AppColors.terracottaBright
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isExpanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: AppColors.textMuted,
                            size: 16,
                          ),
                          IconButton(
                            tooltip: quest.isManual
                                ? 'Toggle completion'
                                : 'Verification info',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                            onPressed: () => _handleQuestTap(quest),
                            icon: Icon(
                              quest.isCompleted
                                  ? Icons.check_circle_rounded
                                  : (quest.isManual
                                      ? Icons.radio_button_unchecked_rounded
                                      : Icons.lock_clock_rounded),
                              color: quest.isCompleted
                                  ? AppColors.emerald
                                  : AppColors.textMuted,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(
                                color: AppColors.border,
                                height: 1,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                quest.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                              if (isVerifiedType &&
                                  !quest.isCompleted &&
                                  widget.onNavigateTab != null) ...[
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => widget.onNavigateTab!(
                                    isWinQuest ? 2 : 1,
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.terracottaBright,
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    isWinQuest ? 'Open Wins' : 'Open Scanner',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        crossFadeState: isExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 200),
                        sizeCurve: Curves.easeOutCubic,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () =>
                _showAddSelfReportedGoalDialog(profile.normalizedMode),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text(
              'Add Self-Reported Goal',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillGapSection(SkillGapReport report) {
    final isId = report.isIndonesian;
    final availableRoles = ApiClient.roleKeywordsCatalog.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isId
                        ? 'ANALISIS KESENJANGAN KEAHLIAN'
                        : 'SKILL GAP & ACTION PLAN',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.terracottaBright,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.jobTitle,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Bilingual EN / ID toggle for Skill Gap
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MiniTogglePill(
                  label: 'EN',
                  selected: !isId,
                  onTap: () => setState(() => _langOverride = 'en'),
                ),
                const SizedBox(width: 4),
                _MiniTogglePill(
                  label: 'ID',
                  selected: isId,
                  onTap: () => setState(() => _langOverride = 'id'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Role Switcher chips across diverse fresh-grad fields
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: availableRoles.map((role) {
              final isSelected = role == report.jobTitle;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(role),
                  selected: isSelected,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _roleOverride = role),
                  selectedColor: AppColors.terracotta.withValues(alpha: 0.22),
                  backgroundColor: AppColors.surfaceElevated,
                  side: BorderSide(
                    color:
                        isSelected ? AppColors.terracotta : AppColors.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppColors.terracottaBright
                        : AppColors.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        if (report.matchedKeywords.isNotEmpty) ...[
          Text(
            isId
                ? 'KATA KUNCI TERDETEKSI DI CV ANDA (${report.matchedKeywords.length})'
                : 'MATCHED IN YOUR CV (${report.matchedKeywords.length})',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: report.matchedKeywords.map((kw) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.emerald.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: AppColors.emerald,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        kw,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.emerald,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        Text(
          isId
              ? 'KATA KUNCI BELUM TERCANTUM & AKSI KONKRET (${report.gaps.length})'
              : 'MISSING KEYWORDS & CONCRETE ACTIONS (${report.gaps.length})',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),

        if (report.gaps.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.45),
              ),
            ),
            child: Text(
              isId
                  ? 'Luar biasa! Seluruh kata kunci utama untuk posisi ini telah tercantum di CV Anda.'
                  : 'All core keywords for this target role are present in your CV!',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.emerald,
              ),
            ),
          )
        else
          ...report.gaps.map((gap) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          gap.keyword,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.terracottaBright,
                          ),
                        ),
                        Text(
                          gap.actionTypeLabel,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    gap.actionTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gap.concreteAction,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const Divider(
                    color: AppColors.border,
                    height: 24,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isId ? 'CONTOH POIN CV' : 'SAMPLE CV BULLET',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            PlaceholderRichText(
                              text: '• ${gap.sampleBullet}',
                              baseStyle: const TextStyle(
                                fontSize: 12,
                                color: AppColors.white,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Copy sample bullet',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: gap.sampleBullet),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isId
                                    ? 'Contoh kalimat ${gap.keyword} disalin!'
                                    : 'Sample bullet for ${gap.keyword} copied!',
                              ),
                              backgroundColor: AppColors.emerald,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.copy_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.terracotta.withValues(alpha: 0.22)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.terracotta : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected
                ? AppColors.terracottaBright
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _MiniTogglePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MiniTogglePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.terracotta.withValues(alpha: 0.22)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.terracotta : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: selected
                ? AppColors.terracottaBright
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}


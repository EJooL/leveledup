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
  String _activeSection = 'all'; // 'all', 'checklist', 'skill_gap', 'history'
  String? _roleOverride;
  String? _langOverride;

  void _showAddSelfReportedGoalDialog(CareerStage activeMode) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border),
          ),
          title: const Row(
            children: [
              Icon(Icons.add_task_rounded, color: AppColors.terracottaBright),
              SizedBox(width: 10),
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
                const SizedBox(height: 14),
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
                  Icons.verified_outlined,
                  color: AppColors.terracottaBright,
                  size: 18,
                ),
                const SizedBox(width: 10),
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header + Single "I got the job" Transition Action + Sign Out
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHired
                              ? 'HIRED · FIRST 90 DAYS'
                              : 'JOB HUNT CHECKLIST & SKILL GAP',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.terracottaBright,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Verified Progress',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
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

              // Mode Transition Banner ("I got the job" -> First 90 Days checklist)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
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
                          ? Icons.celebration_rounded
                          : Icons.work_outline_rounded,
                      color: isHired
                          ? AppColors.emerald
                          : AppColors.terracottaBright,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHired
                                ? 'First 90 Days Onboarding Active'
                                : 'Currently in Job Hunt Mode',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isHired
                                ? 'Track your 30/60/90 goals and log work wins into your living CV.'
                                : 'Landed an offer? Switch to your First 90 Days onboarding checklist.',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (isHired) {
                          ref
                              .read(careerProvider.notifier)
                              .setCareerStage(CareerStage.jobHunting);
                        } else {
                          ref.read(careerProvider.notifier).markGotTheJob();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isHired
                            ? AppColors.surfaceElevated
                            : AppColors.terracotta,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      icon: Icon(
                        isHired
                            ? Icons.work_outline_rounded
                            : Icons.celebration_rounded,
                        size: 15,
                      ),
                      label: Text(
                        isHired ? 'Job Hunt' : 'I got the job',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChipPill(
                      label: 'All Progress',
                      selected: _activeSection == 'all',
                      onTap: () => setState(() => _activeSection = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipPill(
                      label: 'Checklist (${profile.activeModeProgressLabel})',
                      selected: _activeSection == 'checklist',
                      onTap: () => setState(() => _activeSection = 'checklist'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipPill(
                      label:
                          'Skill Gap (${effectiveSkillGap.gaps.length} gaps)',
                      selected: _activeSection == 'skill_gap',
                      onTap: () => setState(() => _activeSection = 'skill_gap'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipPill(
                      label: 'Score History',
                      selected: _activeSection == 'history',
                      onTap: () => setState(() => _activeSection = 'history'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ---------------------------------------------------------------
              // SECTION A: SCORE HISTORY TIMELINE ("54 -> 71 -> 82")
              // ---------------------------------------------------------------
              if (_activeSection == 'all' || _activeSection == 'history') ...[
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

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
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
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
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
          const SizedBox(height: 12),
          if (history.isEmpty)
            const Text(
              'No CV scans recorded yet. Run an ATS scan in the Scanner tab to track your score progression (e.g., 54 → 71 → 82) and verify which issues were fixed between versions.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            )
          else ...[
            ...history.reversed.map((point) {
              final isPositive = point.scoreDelta > 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isPositive
                        ? AppColors.emerald.withValues(alpha: 0.4)
                        : AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.getScoreColor(point.overallScore)
                                .withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${point.overallScore}/100',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color:
                                  AppColors.getScoreColor(point.overallScore),
                            ),
                          ),
                        ),
                        if (point.scoreDelta != 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isPositive
                                  ? AppColors.emerald.withValues(alpha: 0.16)
                                  : AppColors.crimson.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              isPositive
                                  ? '+${point.scoreDelta} pts'
                                  : '${point.scoreDelta} pts',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: isPositive
                                    ? AppColors.emerald
                                    : AppColors.crimson,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${point.fileName} · ${point.jobTitle}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        Text(
                          point.createdAtLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    if (point.fixedIssues.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: point.fixedIssues.map((fi) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.emerald.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 13,
                                  color: AppColors.emerald,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Fixed: ${fi.title}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.emerald,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildChecklistSection(
    UserCareerProfile profile,
    List<CareerQuest> modeQuests,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
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
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
              Text(
                profile.activeModeProgressLabel,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.emerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Accurate Progress Bar bound strictly to completedCount / totalCount
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: profile.activeModeProgressFraction,
              minHeight: 8,
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.emerald,
              ),
            ),
          ),
          const SizedBox(height: 14),

          ...modeQuests.map((quest) {
            final isVerifiedType = !quest.isManual;
            return InkWell(
              onTap: () => _handleQuestTap(quest),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: quest.isCompleted
                        ? AppColors.emerald.withValues(alpha: 0.45)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CareerIconBadge(
                      icon: CareerIcons.forQuest(quest),
                      accentColor: CareerIcons.forQuestAccent(quest),
                      size: 42,
                      radius: 12,
                      iconSize: 20,
                      showCompletedBadge: quest.isCompleted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  quest.title,
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
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isVerifiedType
                                      ? AppColors.terracotta
                                          .withValues(alpha: 0.16)
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: isVerifiedType
                                        ? AppColors.terracotta
                                            .withValues(alpha: 0.4)
                                        : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  quest.verificationType.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isVerifiedType
                                        ? AppColors.terracottaBright
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            quest.description,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      quest.isCompleted
                          ? Icons.check_circle_rounded
                          : (quest.isManual
                              ? Icons.radio_button_unchecked_rounded
                              : Icons.lock_clock_rounded),
                      color: quest.isCompleted
                          ? AppColors.emerald
                          : AppColors.textMuted,
                      size: 21,
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  _showAddSelfReportedGoalDialog(profile.normalizedMode),
              icon: const Icon(Icons.add_rounded, size: 17),
              label: const Text(
                'Add Self-Reported Goal',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillGapSection(SkillGapReport report) {
    final isId = report.isIndonesian;
    final availableRoles = ApiClient.roleKeywordsCatalog.keys.toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
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
                    const SizedBox(height: 2),
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
              // Bilingual EN / ID toggle for Skill Gap
              Row(
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
          const SizedBox(height: 10),
          // Role Switcher chips across diverse fresh-grad fields
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: availableRoles.map((role) {
                final isSelected = role == report.jobTitle;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(role),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _roleOverride = role),
                    selectedColor:
                        AppColors.terracotta.withValues(alpha: 0.24),
                    backgroundColor: AppColors.surfaceElevated,
                    labelStyle: TextStyle(
                      fontSize: 11,
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
          const SizedBox(height: 14),

          if (report.matchedKeywords.isNotEmpty) ...[
            Text(
              isId
                  ? 'KATA KUNCI TERDETEKSI DI CV ANDA (${report.matchedKeywords.length})'
                  : 'MATCHED IN YOUR CV (${report.matchedKeywords.length})',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: report.matchedKeywords.map((kw) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.emerald.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_rounded,
                        size: 13,
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
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          if (report.gaps.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
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
                        runSpacing: 6,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.terracotta.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              gap.keyword,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.terracottaBright,
                              ),
                            ),
                          ),
                          Text(
                            gap.actionTypeLabel,
                            style: const TextStyle(
                              fontSize: 11,
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
                        fontSize: 13.5,
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
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: PlaceholderRichText(
                              text: '• ${gap.sampleBullet}',
                              baseStyle: const TextStyle(
                                fontSize: 12,
                                color: AppColors.white,
                                height: 1.4,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Copy sample bullet',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.only(left: 8),
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
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.terracotta : AppColors.surfaceElevated,
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
            color: selected ? AppColors.white : AppColors.textSecondary,
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
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.terracotta : AppColors.surfaceElevated,
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
            color: selected ? AppColors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/career_icons.dart';
import '../../models/career_companion_model.dart';
import '../../providers/career_provider.dart';
import '../../widgets/career_companion_sheets.dart';
import '../../widgets/career_icon_badge.dart';

class HomeDashboardScreen extends ConsumerWidget {
  final ValueChanged<int> onNavigateTab;

  const HomeDashboardScreen({
    super.key,
    required this.onNavigateTab,
  });

  void _confirmGotTheJobDialog(BuildContext context, WidgetRef ref) {
    final profile = ref.read(careerProvider);
    if (profile.isHiredMode) {
      onNavigateTab(3);
      return;
    }

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
              Icon(Icons.work_outline_rounded, color: AppColors.terracottaBright),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Congratulations on the Job!',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Switching to Hired Mode activates your First 90 Days onboarding checklist (30/60/90 manager alignment, documenting your first deliverable, and logging work wins into your living CV).',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Not yet',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(careerProvider.notifier).markGotTheJob();
              },
              child: const Text('Activate First 90 Days'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(careerProvider);
    final stageQuests = profile.activeModeQuests;

    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Greeting Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Hello, ${profile.characterName}!',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Subtle secondary XP pill
                  GestureDetector(
                    onTap: () => onNavigateTab(3),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 168),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '${profile.activeModeProgressLabel} · ${profile.totalXpEarned} XP',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.terracottaBright,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Simplified Hero Card: Latest ATS Score + Next Best Action + Checklist Progress
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.terracotta,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -32,
                        top: 24,
                        bottom: 24,
                        child: Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.white.withValues(alpha: 0.14),
                              width: 24,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.background
                                          .withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      profile.currentStage.label.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  profile.activeModeProgressLabel,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (profile.latestAtsScore != null)
                              Text.rich(
                                TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'ATS Score: ',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.white,
                                        letterSpacing: -0.5,
                                        height: 1.1,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '${profile.latestAtsScore}/100',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.white,
                                        letterSpacing: -0.8,
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            else
                              const Text(
                                'No ATS Scan Yet',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.white,
                                  letterSpacing: -0.6,
                                  height: 1.1,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              'Next: ${profile.nextBestActionTitle}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white.withValues(alpha: 0.92),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'LV ${profile.currentLevel} · ${profile.phaseShortTag}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.white,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${profile.currentPhaseXp} / ${profile.targetPhaseXp} XP',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        AppColors.white.withValues(alpha: 0.92),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(end: profile.xpProgress),
                              duration: const Duration(milliseconds: 520),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: value.clamp(0.0, 1.0),
                                    minHeight: 8,
                                    backgroundColor: AppColors.background
                                        .withValues(alpha: 0.3),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      AppColors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 3. Quick Action Buttons Row (Real-world outcome actions)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _QuickActionSquircle(
                      icon: Icons.document_scanner_outlined,
                      label: 'Scan CV',
                      onTap: () => onNavigateTab(1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickActionSquircle(
                      icon: Icons.post_add_outlined,
                      label: 'Log Win',
                      onTap: () => onNavigateTab(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickActionSquircle(
                      icon: Icons.insights_outlined,
                      label: 'Skill Gap',
                      onTap: () => onNavigateTab(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ApiConstants.enableDailyCheckIn
                        ? _QuickActionSquircle(
                            icon: Icons.event_available_outlined,
                            label: 'Check-In',
                            dotColor: profile.hasCheckedInToday
                                ? AppColors.emerald
                                : AppColors.terracotta,
                            onTap: () => showDailyCheckInSheet(context, ref),
                          )
                        : _QuickActionSquircle(
                            icon: profile.isHiredMode
                                ? Icons.verified_outlined
                                : Icons.work_outline_rounded,
                            label: profile.isHiredMode
                                ? '90-Day Plan'
                                : 'Got the Job',
                            iconColor: profile.isHiredMode
                                ? AppColors.emerald
                                : AppColors.white,
                            onTap: () => _confirmGotTheJobDialog(context, ref),
                          ),
                  ),
                ],
              ),

              // 4. Score History Strip (if user has scanned at least once)
              if (profile.scoreHistory.isNotEmpty) ...[
                const SizedBox(height: 24),
                InkWell(
                  onTap: () => onNavigateTab(3),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.timeline_rounded,
                          color: AppColors.terracottaBright,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Score Timeline:',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            profile.timelineLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // 5. Verified Checklist Preview ("3 of 6 done")
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      profile.isHiredMode
                          ? 'First 90 Days Checklist (${profile.activeModeProgressLabel})'
                          : 'Job-Hunt Checklist (${profile.activeModeProgressLabel})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => onNavigateTab(3),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'See all',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.terracottaBright,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppColors.terracottaBright,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (stageQuests.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0;
                          i < stageQuests.take(5).length;
                          i++) ...[
                        if (i > 0)
                          const Divider(
                            color: AppColors.border,
                            height: 1,
                          ),
                        _ChecklistQuestRow(
                          quest: stageQuests[i],
                          onTap: () async {
                            final quest = stageQuests[i];
                            final msg = await ref
                                .read(careerProvider.notifier)
                                .toggleQuestCompletion(quest.id);
                            if (!context.mounted) return;
                            if (msg != null) {
                              final isWin = quest.verificationType ==
                                  QuestVerificationType.winVerified;
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
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () {
                                            ScaffoldMessenger.of(context)
                                                .hideCurrentSnackBar();
                                            onNavigateTab(isWin ? 2 : 1);
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                AppColors.terracottaBright,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            minimumSize: Size.zero,
                                            tapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: Text(
                                            isWin
                                                ? 'Open Wins'
                                                : 'Open Scanner',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionSquircle extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;
  final Color? dotColor;

  const _QuickActionSquircle({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppColors.white,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              if (dotColor != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.background,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistQuestRow extends StatelessWidget {
  final CareerQuest quest;
  final VoidCallback onTap;

  const _ChecklistQuestRow({
    required this.quest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isVerified = !quest.isManual;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CareerIconBadge(
              icon: CareerIcons.forQuest(quest),
              accentColor: CareerIcons.forQuestAccent(quest),
              size: 40,
              radius: 12,
              iconSize: 20,
              showCompletedBadge: quest.isCompleted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    maxLines: 1,
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
                    quest.verificationType.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isVerified
                          ? AppColors.terracottaBright
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              quest.isCompleted
                  ? Icons.check_circle_rounded
                  : (quest.isManual
                      ? Icons.radio_button_unchecked_rounded
                      : Icons.verified_outlined),
              color: quest.isCompleted
                  ? AppColors.emerald
                  : AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

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
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: AppColors.border),
          ),
          title: const Row(
            children: [
              Icon(Icons.celebration_rounded, color: AppColors.accentGoldBright),
              SizedBox(width: 10),
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Greeting Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.isHiredMode
                              ? 'Hired · First 90 Days Companion'
                              : 'Job Hunt & Living CV Companion',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Hello, ${profile.characterName}!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Subtle secondary XP pill
                  GestureDetector(
                    onTap: () => onNavigateTab(3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        '${profile.activeModeProgressLabel} · ${profile.totalXpEarned} XP',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.terracottaBright,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Simplified Hero Card: Latest ATS Score + Next Best Action + Checklist Progress ("3 of 6 done")
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFB5462F),
                      Color(0xFFD95B3F),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.terracotta.withValues(alpha: 0.28),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -38,
                        top: 22,
                        bottom: 22,
                        child: Container(
                          width: 132,
                          height: 132,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.white.withValues(alpha: 0.9),
                              width: 24,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.background
                                        .withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    profile.currentStage.label.toUpperCase(),
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
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
                            const SizedBox(height: 14),
                            Text(
                              profile.latestAtsScore != null
                                  ? 'ATS Score: ${profile.latestAtsScore}/100'
                                  : 'No ATS Scan Yet',
                              style: const TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w900,
                                color: AppColors.white,
                                letterSpacing: -0.8,
                                height: 1.08,
                              ),
                            ),
                            const SizedBox(height: 6),
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
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: profile.activeModeProgressFraction,
                                minHeight: 7,
                                backgroundColor:
                                    AppColors.background.withValues(alpha: 0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // 3. Quick Action Buttons Row (Real-world outcome actions)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _QuickActionSquircle(
                    icon: Icons.document_scanner_rounded,
                    label: 'Scan CV',
                    onTap: () => onNavigateTab(1),
                  ),
                  _QuickActionSquircle(
                    icon: Icons.emoji_events_rounded,
                    label: 'Log Win',
                    iconColor: AppColors.accentGoldBright,
                    onTap: () => onNavigateTab(2),
                  ),
                  _QuickActionSquircle(
                    icon: Icons.psychology_alt_rounded,
                    label: 'Skill Gap',
                    onTap: () => onNavigateTab(3),
                  ),
                  if (ApiConstants.enableDailyCheckIn)
                    _QuickActionSquircle(
                      icon: Icons.event_available_rounded,
                      label: 'Check-In',
                      dotColor: profile.hasCheckedInToday
                          ? AppColors.emerald
                          : AppColors.terracotta,
                      onTap: () => showDailyCheckInSheet(context, ref),
                    )
                  else
                    _QuickActionSquircle(
                      icon: profile.isHiredMode
                          ? Icons.verified_rounded
                          : Icons.celebration_rounded,
                      label:
                          profile.isHiredMode ? '90-Day Plan' : 'Got the Job',
                      iconColor: profile.isHiredMode
                          ? AppColors.emerald
                          : AppColors.terracottaBright,
                      onTap: () => _confirmGotTheJobDialog(context, ref),
                    ),
                ],
              ),

              // 4. Score History Strip (if user has scanned at least once)
              if (profile.scoreHistory.isNotEmpty) ...[
                const SizedBox(height: 22),
                InkWell(
                  onTap: () => onNavigateTab(3),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
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
                          size: 19,
                        ),
                        const SizedBox(width: 10),
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
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 26),

              // 5. Verified Checklist Preview ("3 of 6 done")
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      profile.isHiredMode
                          ? 'First 90 Days Checklist (${profile.activeModeProgressLabel})'
                          : 'Job-Hunt Checklist (${profile.activeModeProgressLabel})',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onNavigateTab(3),
                    child: const Text(
                      'See all →',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.terracottaBright,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ...stageQuests.take(5).map((quest) {
                return _ChecklistQuestRow(
                  quest: quest,
                  onTap: () async {
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
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context)
                                        .hideCurrentSnackBar();
                                    onNavigateTab(isWin ? 2 : 1);
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.terracottaBright,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    isWin ? 'Open Wins' : 'Open Scanner',
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
                );
              }),
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
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 23,
                ),
              ),
              if (dotColor != null)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 11,
                    height: 11,
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: quest.isCompleted
                ? AppColors.emerald.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            CareerIconBadge(
              icon: CareerIcons.forQuest(quest),
              accentColor: CareerIcons.forQuestAccent(quest),
              size: 44,
              radius: 13,
              iconSize: 21,
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
                  const SizedBox(height: 3),
                  Text(
                    quest.verificationType.label,
                    style: TextStyle(
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
            const SizedBox(width: 10),
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

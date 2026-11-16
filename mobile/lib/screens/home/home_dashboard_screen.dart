import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/career_companion_model.dart';
import '../../providers/career_provider.dart';

class HomeDashboardScreen extends ConsumerWidget {
  final ValueChanged<int> onNavigateTab;

  const HomeDashboardScreen({
    super.key,
    required this.onNavigateTab,
  });

  void _showStageSelectorModal(
    BuildContext context,
    WidgetRef ref,
    CareerStage current,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.explore_rounded, color: AppColors.terracottaBright),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Select Your Career Stage',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Switch between Pre-Job Hunting and Post-Hire Career Progression.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ...CareerStage.values.map((stage) {
                  final isSelected = stage == current;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        ref.read(careerProvider.notifier).setCareerStage(stage);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.terracotta.withValues(alpha: 0.16)
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.terracotta
                                : AppColors.border,
                            width: isSelected ? 1.4 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: isSelected
                                  ? AppColors.terracottaBright
                                  : AppColors.textMuted,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stage.label,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    stage.subtitle,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(careerProvider);
    final stageQuests = profile.quests
        .where((q) => q.stage == profile.currentStage)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Greeting Header (Matched to Screen 2 of Reference: "Welcome back / Anarda" + Avatar)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.currentStage == CareerStage.jobHunting
                              ? 'Global Job Hunter Mode'
                              : 'On-The-Job Companion',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.characterName,
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
                  // Avatar with Terracotta Notification Dot
                  GestureDetector(
                    onTap: () => onNavigateTab(3),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'LVL ${profile.level}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.terracottaBright,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.terracotta,
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
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Visa-Style Hero Card + Vertical '+' Pill Bar (Matched 1:1 to Screen 2 of Reference)
              SizedBox(
                height: 176,
                child: Row(
                  children: [
                    // Left Main Terracotta Gradient Card with Cropped White 'C' Ring Emblem
                    Expanded(
                      child: Container(
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
                              // Large cropped white 'C' / ring emblem on the right edge (exact reference match)
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
                                      color: AppColors.white.withValues(alpha: 0.92),
                                      width: 24,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.background.withValues(alpha: 0.25),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            'LEVELED UP · LVL ${profile.level}',
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          profile.latestAtsScore != null
                                              ? 'ATS ${profile.latestAtsScore}/100'
                                              : '${profile.totalXpEarned} XP',
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.white,
                                            letterSpacing: -0.8,
                                            height: 1.05,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${profile.currentXp} / ${profile.xpToNextLevel} XP · ${profile.rankTitle}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.white.withValues(alpha: 0.85),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      profile.currentStage.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Right Vertical Dark Pill '+' Bar (Matched 1:1 to Screen 2 of Reference)
                    InkWell(
                      onTap: () => _showStageSelectorModal(
                        context,
                        ref,
                        profile.currentStage,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 48,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.add_rounded,
                            color: AppColors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. 4 Rounded-Square Quick Action Buttons Row (Matched 1:1 to Send / Request / Pay / More)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _QuickActionSquircle(
                    icon: Icons.send_rounded,
                    label: 'Scan CV',
                    onTap: () => onNavigateTab(1),
                  ),
                  _QuickActionSquircle(
                    icon: Icons.description_outlined,
                    label: 'AI Rewrite',
                    onTap: () => onNavigateTab(1),
                  ),
                  _QuickActionSquircle(
                    icon: Icons.work_outline_rounded,
                    label: 'Log App (${profile.applicationsSent})',
                    onTap: () {
                      ref.read(careerProvider.notifier).logJobApplicationSent();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Global job application logged! +25 Career XP!',
                          ),
                          backgroundColor: AppColors.terracotta,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  _QuickActionSquircle(
                    icon: Icons.more_horiz_rounded,
                    label: 'Stage',
                    onTap: () => _showStageSelectorModal(
                      context,
                      ref,
                      profile.currentStage,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 4. "Recent Quests & Milestones" Transaction-Style List (Matched 1:1 to Reference)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Active Career Quests',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onNavigateTab(2),
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
              const SizedBox(height: 14),

              ...stageQuests.map((quest) {
                return _TransactionStyleQuestRow(
                  quest: quest,
                  onTap: () => ref
                      .read(careerProvider.notifier)
                      .toggleQuestCompletion(quest.id),
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

  const _QuickActionSquircle({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
              color: AppColors.white,
              size: 23,
            ),
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

class _TransactionStyleQuestRow extends StatelessWidget {
  final CareerQuest quest;
  final VoidCallback onTap;

  const _TransactionStyleQuestRow({
    required this.quest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            // Left Squircle Icon (Matching PayPal/Spotify/Adobe icon boxes in Reference)
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: quest.isCompleted
                    ? AppColors.emerald.withValues(alpha: 0.14)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: quest.isCompleted
                      ? AppColors.emerald.withValues(alpha: 0.4)
                      : AppColors.border,
                ),
              ),
              child: Icon(
                quest.isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.bolt_rounded,
                color: quest.isCompleted
                    ? AppColors.emerald
                    : AppColors.terracottaBright,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Center Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
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
                    '${quest.impactMetricTag} · ${quest.difficulty.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Right Value (+XP in Emerald/Terracotta matching +$212 / -$212 in Reference)
            Text(
              '+${quest.xpReward} XP',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: quest.isCompleted
                    ? AppColors.emerald
                    : AppColors.terracottaBright,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/career_companion_model.dart';
import '../../providers/career_provider.dart';
import '../../widgets/quest_card.dart';
import '../../widgets/xp_level_banner.dart';

class HomeDashboardScreen extends ConsumerWidget {
  final ValueChanged<int> onNavigateTab;

  const HomeDashboardScreen({
    super.key,
    required this.onNavigateTab,
  });

  void _showStageSelectorModal(BuildContext context, WidgetRef ref, CareerStage current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.explore_rounded, color: AppColors.accentCyan),
                  const SizedBox(width: 10),
                  const Text(
                    'Select Your Career Stage',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'LeveledUp adapts its quests and coaching from your job hunt through your promotions.',
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
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      ref.read(careerProvider.notifier).setCareerStage(stage);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentCyan.withValues(alpha: 0.12)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accentCyan
                              : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: isSelected
                                ? AppColors.accentCyan
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
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.trending_up_rounded,
                color: AppColors.background,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LEVELED UP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  'ATS Scanner & RPG Career Companion',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. RPG Level & XP Banner
            XpLevelBanner(
              profile: profile,
              onStageTap: () =>
                  _showStageSelectorModal(context, ref, profile.currentStage),
            ),
            const SizedBox(height: 18),

            // 2. Quick Telemetry Grid
            Row(
              children: [
                Expanded(
                  child: _StatMiniCard(
                    label: 'LATEST ATS',
                    value: profile.latestAtsScore != null
                        ? '${profile.latestAtsScore}/100'
                        : 'Not Scanned',
                    icon: Icons.document_scanner_rounded,
                    accent: profile.latestAtsScore != null
                        ? AppColors.getScoreColor(profile.latestAtsScore!)
                        : AppColors.accentCyan,
                    onTap: () => onNavigateTab(1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatMiniCard(
                    label: 'QUESTS DONE',
                    value: '${profile.completedQuestsCount}/${profile.quests.length}',
                    icon: Icons.task_alt_rounded,
                    accent: AppColors.emerald,
                    onTap: () => onNavigateTab(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatMiniCard(
                    label: 'BADGES',
                    value: '${profile.earnedBadgesCount}/${profile.badges.length}',
                    icon: Icons.military_tech_rounded,
                    accent: AppColors.accentGoldBright,
                    onTap: () => onNavigateTab(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // 3. Dual Core Action Cards (CV Scanner + Post-Job Career Mode)
            const Text(
              'CORE MODULES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderBright),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accentCyan.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.radar_rounded,
                          color: AppColors.accentCyan,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Global ATS CV Scanner & AI Rewrite',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Audit 5 international pillars, strip bias data & rewrite with STAR metrics (+75 XP)',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => onNavigateTab(1),
                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                      label: const Text('Launch ATS CV Scanner'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Current Stage Quests Preview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ACTIVE QUESTS — ${profile.currentStage.shortLabel.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.currentStage.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => onNavigateTab(2),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: AppColors.accentCyan,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...stageQuests.map(
              (quest) => QuestCard(
                quest: quest,
                onToggle: () => ref
                    .read(careerProvider.notifier)
                    .toggleQuestCompletion(quest.id),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _StatMiniCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


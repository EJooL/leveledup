import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/career_companion_model.dart';
import '../../providers/career_provider.dart';

class SkillTreeScreen extends ConsumerWidget {
  const SkillTreeScreen({super.key});

  IconData _badgeIcon(String code) {
    switch (code) {
      case 'rocket':
        return Icons.rocket_launch_rounded;
      case 'radar':
        return Icons.radar_rounded;
      case 'shield':
        return Icons.verified_user_rounded;
      case 'auto_awesome':
        return Icons.auto_awesome_rounded;
      case 'workspace_premium':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.military_tech_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(careerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SKILL TREE & TROPHIES',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Total XP: ${profile.totalXpEarned}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentCyan,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Achievement Badges Grid
            const Text(
              'CAREER ACHIEVEMENT BADGES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.9,
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.55,
              ),
              itemCount: profile.badges.length,
              itemBuilder: (context, index) {
                final badge = profile.badges[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: badge.isEarned
                        ? AppColors.surfaceLight
                        : AppColors.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: badge.isEarned
                          ? AppColors.accentGold.withValues(alpha: 0.5)
                          : AppColors.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _badgeIcon(badge.iconCode),
                            size: 20,
                            color: badge.isEarned
                                ? AppColors.accentGoldBright
                                : AppColors.textMuted,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badge.isEarned
                                  ? AppColors.emerald.withValues(alpha: 0.16)
                                  : AppColors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge.isEarned ? 'EARNED' : 'LOCKED',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: badge.isEarned
                                    ? AppColors.emerald
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        badge.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: badge.isEarned
                              ? AppColors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        badge.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 26),

            // 2. RPG Skill Tree Nodes
            const Text(
              'RPG CAREER SKILL TREE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.9,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Level up your core engineering & leadership competencies as you grow in your role.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),

            ...profile.skills.map((skill) {
              final canUpgrade =
                  !skill.isMaxed && profile.level >= skill.requiredLevel;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: skill.isMaxed
                        ? AppColors.accentGold.withValues(alpha: 0.5)
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
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentCyan.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            skill.branch.title.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accentCyan,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Tier Pips
                        Row(
                          children: List.generate(skill.maxTier, (i) {
                            final filled = i < skill.currentTier;
                            return Container(
                              width: 18,
                              height: 7,
                              margin: const EdgeInsets.only(left: 4),
                              decoration: BoxDecoration(
                                color: filled
                                    ? AppColors.accentGoldBright
                                    : AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      skill.title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      skill.description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          skill.isMaxed
                              ? 'MASTERY COMPLETE (TIER ${skill.currentTier}/${skill.maxTier})'
                              : 'Tier ${skill.currentTier}/${skill.maxTier} • Req. Level ${skill.requiredLevel}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: skill.isMaxed
                                ? AppColors.emerald
                                : AppColors.textMuted,
                          ),
                        ),
                        if (!skill.isMaxed)
                          OutlinedButton.icon(
                            onPressed: canUpgrade
                                ? () {
                                    final err = ref
                                        .read(careerProvider.notifier)
                                        .upgradeSkillNode(skill.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          err ??
                                              'Upgraded ${skill.title}! +40 Mastery XP earned!',
                                        ),
                                        backgroundColor: err == null
                                            ? AppColors.emerald
                                            : AppColors.crimson,
                                      ),
                                    );
                                  }
                                : null,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                            ),
                            icon: const Icon(Icons.upgrade_rounded, size: 16),
                            label: Text(
                              canUpgrade
                                  ? 'Train (+40 XP)'
                                  : 'Locked (Lvl ${skill.requiredLevel})',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}


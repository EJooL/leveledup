import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/career_icons.dart';
import '../../models/career_companion_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/career_provider.dart';
import '../../widgets/career_icon_badge.dart';

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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Stack(
            children: [
              // 1. Curved Sheet Body starting at top: 68px (Matched 1:1 to Screen 3 Top-Right in Reference)
              Container(
                margin: const EdgeInsets.only(top: 64),
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 36),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border(
                    top: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Centered Name & Handle below overlapping avatar
                    Center(
                      child: Column(
                        children: [
                          Text(
                            profile.characterName,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            profile.rankTitle,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.terracottaBright,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 1: "Career Skill Tree" (Matched to "General" list cards in Screen 3 of Reference)
                    const Text(
                      'Career Skill Tree',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...profile.skills.map((skill) {
                      final canUpgrade = !skill.isMaxed &&
                          profile.level >= skill.requiredLevel;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: canUpgrade
                              ? () {
                                  final err = ref
                                      .read(careerProvider.notifier)
                                      .upgradeSkillNode(skill.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        err ??
                                            'Upgraded ${skill.title}! +40 Mastery XP!',
                                      ),
                                      backgroundColor: err == null
                                          ? AppColors.emerald
                                          : AppColors.crimson,
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                }
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 15,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: skill.isMaxed
                                    ? AppColors.emerald.withValues(alpha: 0.45)
                                    : AppColors.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                CareerIconBadge(
                                  icon: CareerIcons.forSkill(skill),
                                  accentColor: CareerIcons.forSkillAccent(skill),
                                  size: 44,
                                  radius: 13,
                                  iconSize: 22,
                                  showCompletedBadge: skill.isMaxed,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        skill.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${skill.branch.title} · Tier ${skill.currentTier}/${skill.maxTier}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: skill.isMaxed
                                        ? AppColors.emerald.withValues(alpha: 0.16)
                                        : AppColors.terracotta.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    skill.isMaxed
                                        ? 'MAX'
                                        : canUpgrade
                                            ? '+Train'
                                            : 'Lvl ${skill.requiredLevel}',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: skill.isMaxed
                                          ? AppColors.emerald
                                          : AppColors.terracottaBright,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    // Section 2: "Achievement Badges" (Matched to "Help center" cards in Screen 3 of Reference)
                    const Text(
                      'Achievement Trophies',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...profile.badges.map((badge) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: badge.isEarned
                                ? AppColors.terracotta.withValues(alpha: 0.45)
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: badge.isEarned
                                    ? AppColors.terracotta.withValues(alpha: 0.16)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                _badgeIcon(badge.iconCode),
                                color: badge.isEarned
                                    ? AppColors.terracottaBright
                                    : AppColors.textMuted,
                                size: 21,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    badge.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: badge.isEarned
                                          ? AppColors.white
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    badge.description,
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
                            const SizedBox(width: 8),
                            Text(
                              badge.isEarned ? 'EARNED' : 'LOCKED',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: badge.isEarned
                                    ? AppColors.emerald
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 10),

                    // Bottom Full-Width Dark Pill Bar (Matched 1:1 to "Log out" dark pill bar in Screen 3 of Reference)
                    InkWell(
                      onTap: () => ref.read(authProvider.notifier).signOut(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderBright),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: AppColors.terracottaBright,
                              size: 18,
                            ),
                            SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                'Log out',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Overlapping Centered Squircle Avatar straddling the curved top edge (Matched 1:1 to Screen 3)
              Positioned(
                top: 22,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFB5462F),
                          Color(0xFFE06348),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.background,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.terracotta.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'LEVEL',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        Text(
                          '${profile.level}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.white,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

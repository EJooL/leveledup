import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/career_companion_model.dart';

class QuestCard extends StatelessWidget {
  final CareerQuest quest;
  final VoidCallback onToggle;

  const QuestCard({
    super.key,
    required this.quest,
    required this.onToggle,
  });

  Color _difficultyColor() {
    switch (quest.difficulty) {
      case QuestDifficulty.easy:
        return AppColors.emerald;
      case QuestDifficulty.medium:
        return AppColors.accentCyan;
      case QuestDifficulty.hard:
        return AppColors.accentGold;
      case QuestDifficulty.boss:
        return AppColors.accentPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final diffColor = _difficultyColor();

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: quest.isCompleted
              ? AppColors.surface.withValues(alpha: 0.6)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: quest.isCompleted
                ? AppColors.emerald.withValues(alpha: 0.4)
                : AppColors.border,
            width: 1.1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox Circle
            Container(
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: quest.isCompleted
                    ? AppColors.emerald
                    : AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(
                  color: quest.isCompleted
                      ? AppColors.emerald
                      : AppColors.borderBright,
                  width: 1.8,
                ),
              ),
              child: quest.isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppColors.background,
                    )
                  : null,
            ),
            const SizedBox(width: 14),

            // Quest Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top badges: Difficulty + Impact Tag + XP Reward
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: diffColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: diffColor.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Text(
                          quest.difficulty.label,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: diffColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          quest.impactMetricTag,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    quest.title,
                    style: TextStyle(
                      fontSize: 15,
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

                  // Description
                  Text(
                    quest.description,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // XP Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: quest.isCompleted
                    ? AppColors.emerald.withValues(alpha: 0.14)
                    : AppColors.accentGold.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: quest.isCompleted
                      ? AppColors.emerald.withValues(alpha: 0.4)
                      : AppColors.accentGold.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                '+${quest.xpReward} XP',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: quest.isCompleted
                      ? AppColors.emerald
                      : AppColors.accentGoldBright,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


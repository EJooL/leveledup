import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Shared squircle icon container for quests and skills, preserving each item's
/// distinctive icon while optionally showing a compact completion badge.
class CareerIconBadge extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final double size;
  final double radius;
  final double iconSize;
  final bool showCompletedBadge;

  const CareerIconBadge({
    super.key,
    required this.icon,
    required this.accentColor,
    this.size = 44,
    this.radius = 13,
    this.iconSize = 21,
    this.showCompletedBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: iconSize,
            ),
          ),
          if (showCompletedBadge)
            Positioned(
              right: -3,
              bottom: -3,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.emerald,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.background,
                    width: 1.8,
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 10,
                  color: AppColors.background,
                ),
              ),
            ),
        ],
      ),
    );
  }
}


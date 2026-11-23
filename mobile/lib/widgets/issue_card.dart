import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../models/cv_analysis_model.dart';

class IssueCard extends StatelessWidget {
  final Issue issue;
  final VoidCallback? onUnlockTap;

  const IssueCard({
    super.key,
    required this.issue,
    this.onUnlockTap,
  });

  Color _getSeverityColor() {
    switch (issue.severity) {
      case 'critical':
        return AppColors.crimson;
      case 'warning':
        return AppColors.amber;
      default:
        return AppColors.accentCyan;
    }
  }

  String _formatSeverityLabel() {
    if (issue.severity.isEmpty) return '';
    return '${issue.severity[0].toUpperCase()}${issue.severity.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final sevColor = _getSeverityColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: issue.severity == 'critical'
              ? AppColors.crimson.withValues(alpha: 0.35)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Severity + Category Badges
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: sevColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: sevColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  _formatSeverityLabel(),
                  style: AppTheme.label(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: sevColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    issue.categoryLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.label(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              const SizedBox(width: 8),
              Icon(
                issue.isLocked ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                size: 16,
                color: issue.isLocked ? AppColors.textMuted : AppColors.emerald,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Issue Title (Always visible)
          Text(
            issue.title,
            style: AppTheme.display(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
              height: 1.32,
            ),
          ),
          const SizedBox(height: 12),

          // Gated vs Unlocked Content
          if (issue.isLocked)
            InkWell(
              onTap: onUnlockTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.vpn_key_rounded,
                      size: 16,
                      color: AppColors.accentGold,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Deep root cause, fix & Before/After rewrite locked',
                        style: AppTheme.body(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Unlock +120 XP',
                      style: AppTheme.numeric(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentGoldBright,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Detailed Explanation
            if (issue.detail != null) ...[
              Text(
                issue.detail!,
                style: AppTheme.body(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Actionable Fix Box
            if (issue.fix != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_rounded,
                      size: 16,
                      color: AppColors.accentCyan,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Fix: ${issue.fix!}',
                        style: AppTheme.body(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Before vs After Comparison
            if (issue.rewrite != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Before (ATS Rejection Risk)',
                      style: AppTheme.label(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.crimson,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      issue.rewrite!.before,
                      style: AppTheme.body(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                        height: 1.45,
                      ).copyWith(decoration: TextDecoration.lineThrough),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    Text(
                      'After (Global ATS Standard)',
                      style: AppTheme.label(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.emerald,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      issue.rewrite!.after,
                      style: AppTheme.body(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}


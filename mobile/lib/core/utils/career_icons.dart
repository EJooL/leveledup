import 'package:flutter/material.dart';
import '../../models/career_companion_model.dart';
import '../theme/app_colors.dart';

/// Shared icon and accent mapping for Career Quests and Brag Doc categories.
class CareerIcons {
  CareerIcons._();

  static IconData forQuest(CareerQuest quest) {
    switch (quest.id) {
      case 'q_first_scan':
        return Icons.document_scanner_rounded;
      case 'q_purge_bias':
        return Icons.privacy_tip_rounded;
      case 'q_fix_duties':
        return Icons.auto_awesome_rounded;
      case 'q_fix_no_metrics':
        return Icons.analytics_rounded;
      case 'q_fix_missing_keywords':
        return Icons.key_rounded;
      case 'q_fix_cliche_words':
        return Icons.spellcheck_rounded;
      case 'q_fix_too_short':
        return Icons.subject_rounded;
      case 'q_self_portfolio':
        return Icons.folder_special_rounded;
      case 'q_self_linkedin':
        return Icons.badge_rounded;
      case 'q_self_applications':
        return Icons.rocket_launch_rounded;
      case 'hired_first_deliverable':
        return Icons.assignment_turned_in_rounded;
      case 'hired_align_goals':
        return Icons.track_changes_rounded;
      case 'hired_log_first_win':
        return Icons.emoji_events_rounded;
      case 'hired_merge_win_cv':
        return Icons.description_rounded;
      case 'hired_30day_feedback':
        return Icons.forum_rounded;
    }

    final text = '${quest.title} ${quest.impactMetricTag}'.toLowerCase();
    if (text.contains('api') ||
        text.contains('latency') ||
        text.contains('perf') ||
        text.contains('cache')) {
      return Icons.speed_rounded;
    }
    if (text.contains('doc') ||
        text.contains('readme') ||
        text.contains('write')) {
      return Icons.edit_note_rounded;
    }
    if (text.contains('interview') ||
        text.contains('1-on-1') ||
        text.contains('meeting')) {
      return Icons.record_voice_over_rounded;
    }
    if (text.contains('deploy') ||
        text.contains('ship') ||
        text.contains('release')) {
      return Icons.rocket_launch_rounded;
    }

    switch (quest.difficulty) {
      case QuestDifficulty.easy:
        return Icons.checklist_rounded;
      case QuestDifficulty.medium:
        return Icons.trending_up_rounded;
      case QuestDifficulty.hard:
        return Icons.local_fire_department_rounded;
    }
  }

  static Color forQuestAccent(CareerQuest quest) {
    if (quest.isCompleted) return AppColors.emerald;
    switch (quest.difficulty) {
      case QuestDifficulty.easy:
        return AppColors.white;
      case QuestDifficulty.medium:
        return AppColors.terracottaBright;
      case QuestDifficulty.hard:
        return AppColors.accentGoldBright;
    }
  }

  static IconData forBranch(SkillBranch branch) {
    switch (branch) {
      case SkillBranch.technical:
        return Icons.code_rounded;
      case SkillBranch.architecture:
        return Icons.hub_rounded;
      case SkillBranch.leadership:
        return Icons.diversity_3_rounded;
      case SkillBranch.globalOps:
        return Icons.public_rounded;
    }
  }

  static Color forBranchAccent(SkillBranch branch) {
    switch (branch) {
      case SkillBranch.technical:
        return AppColors.terracottaBright;
      case SkillBranch.architecture:
        return AppColors.accentGoldBright;
      case SkillBranch.leadership:
        return AppColors.white;
      case SkillBranch.globalOps:
        return AppColors.terracottaBright;
    }
  }
}

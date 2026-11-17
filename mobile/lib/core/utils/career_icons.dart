import 'package:flutter/material.dart';
import '../../models/career_companion_model.dart';
import '../theme/app_colors.dart';

/// Shared icon and accent mapping for Career Quests and RPG Skill Nodes.
/// Keeps Active Career Quests, Quest Log, and Skill Tree icons distinctive
/// and thematically aligned without duplicating mapping logic.
class CareerIcons {
  CareerIcons._();

  static IconData forQuest(CareerQuest quest) {
    switch (quest.id) {
      case 'q_scan_cv':
        return Icons.document_scanner_rounded;
      case 'q_remove_bias':
        return Icons.privacy_tip_rounded;
      case 'q_star_rewrite':
        return Icons.auto_awesome_rounded;
      case 'q_github_pins':
        return Icons.terminal_rounded;
      case 'q_linkedin_opt':
        return Icons.badge_rounded;
      case 'q_send_5_apps':
        return Icons.rocket_launch_rounded;
      case 'q_first_pr':
        return Icons.merge_type_rounded;
      case 'q_manager_1on1':
        return Icons.track_changes_rounded;
      case 'q_onboarding_doc':
        return Icons.menu_book_rounded;
      case 'q_perf_opt':
        return Icons.speed_rounded;
      case 'q_code_reviews':
        return Icons.rate_review_rounded;
      case 'q_system_rfc':
        return Icons.architecture_rounded;
      case 'q_mentor_junior':
        return Icons.school_rounded;
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
      case QuestDifficulty.boss:
        return Icons.emoji_events_rounded;
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
      case QuestDifficulty.boss:
        return AppColors.terracottaBright;
    }
  }

  static IconData forSkill(SkillNode skill) {
    switch (skill.id) {
      case 'sk_clean_code':
        return Icons.layers_rounded;
      case 'sk_api_perf':
        return Icons.dns_rounded;
      case 'sk_sys_design':
        return Icons.hub_rounded;
      case 'sk_star_story':
        return Icons.auto_stories_rounded;
      case 'sk_async_comm':
        return Icons.public_rounded;
      case 'sk_tech_mentorship':
        return Icons.diversity_3_rounded;
    }

    switch (skill.branch) {
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

  static Color forSkillAccent(SkillNode skill) {
    if (skill.isMaxed) return AppColors.emerald;
    switch (skill.branch) {
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


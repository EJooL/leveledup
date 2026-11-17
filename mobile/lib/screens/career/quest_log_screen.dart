import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/career_icons.dart';
import '../../models/career_companion_model.dart';
import '../../providers/career_provider.dart';
import '../../widgets/career_icon_badge.dart';

class QuestLogScreen extends ConsumerStatefulWidget {
  const QuestLogScreen({super.key});

  @override
  ConsumerState<QuestLogScreen> createState() => _QuestLogScreenState();
}

class _QuestLogScreenState extends ConsumerState<QuestLogScreen> {
  CareerStage? _selectedStageFilter;

  void _showAddQuestDialog(CareerStage defaultStage) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final tagCtrl = TextEditingController(text: 'Q4 Sprint KPI');
    var selectedDifficulty = QuestDifficulty.medium;
    var selectedStage = defaultStage;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border),
              ),
              title: const Row(
                children: [
                  Icon(Icons.add_task_rounded, color: AppColors.terracottaBright),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Create Career QuestPlan',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Turn your job hunt goals, 1-on-1 KPIs, or sprint deliverables into XP quests.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(color: AppColors.white),
                      decoration: const InputDecoration(
                        labelText: 'Quest Title',
                        hintText: 'e.g. Reduce checkout API latency by 25%',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      style: const TextStyle(color: AppColors.white),
                      decoration: const InputDecoration(
                        labelText: 'Action Plan / Deliverable',
                        hintText: 'Add Redis caching and benchmark p95 response time',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tagCtrl,
                      style: const TextStyle(color: AppColors.white),
                      decoration: const InputDecoration(
                        labelText: 'Impact Tag',
                        hintText: 'Performance KPI',
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'DIFFICULTY & XP REWARD',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: QuestDifficulty.values.map((diff) {
                        final isSel = diff == selectedDifficulty;
                        return ChoiceChip(
                          label: Text('${diff.label} (+${diff.defaultXp} XP)'),
                          selected: isSel,
                          onSelected: (_) =>
                              setModalState(() => selectedDifficulty = diff),
                          selectedColor: AppColors.terracotta.withValues(alpha: 0.25),
                          backgroundColor: AppColors.surfaceElevated,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSel ? AppColors.terracottaBright : AppColors.textSecondary,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    ref.read(careerProvider.notifier).addCustomQuest(
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim().isEmpty
                              ? 'Complete this milestone and document quantified metrics.'
                              : descCtrl.text.trim(),
                          stage: selectedStage,
                          difficulty: selectedDifficulty,
                          impactTag: tagCtrl.text.trim(),
                        );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add Quest'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(careerProvider);
    final activeStage = _selectedStageFilter ?? profile.currentStage;
    final filteredQuests = profile.quests
        .where((q) => q.stage == activeStage)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Centered Top Metric Header (Matched 1:1 to Screen 5 Bottom-Center in Reference)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                children: [
                  const Text(
                    'Total Career XP',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${profile.totalXpEarned} XP',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: AppColors.white,
                      letterSpacing: -0.9,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Stage Selector Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: CareerStage.values.map((stage) {
                        final isSelected = stage == activeStage;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              setState(() => _selectedStageFilter = stage);
                              ref
                                  .read(careerProvider.notifier)
                                  .setCareerStage(stage);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.terracotta
                                    : AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.terracotta
                                      : AppColors.border,
                                ),
                              ),
                              child: Text(
                                stage.shortLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Curved Sheet Container with "⊕ Create a career quest plan" Pill + Progress Bar Cards
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border(
                    top: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    // Top Pill Action Bar ("⊕ Create a career quest plan")
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: InkWell(
                        onTap: () => _showAddQuestDialog(activeStage),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.borderBright),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_rounded,
                                color: AppColors.white,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Create a new career quest plan',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Progress-Bar Plan Cards List (Matched 1:1 to Screen 5 of Reference)
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
                        itemCount: filteredQuests.length,
                        itemBuilder: (context, index) {
                          final quest = filteredQuests[index];
                          return _SavingPlanStyleQuestCard(
                            quest: quest,
                            onTap: () {
                              final wasCompleted = quest.isCompleted;
                              ref
                                  .read(careerProvider.notifier)
                                  .toggleQuestCompletion(quest.id);
                              if (!wasCompleted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Quest Complete! +${quest.xpReward} Career XP earned!',
                                    ),
                                    backgroundColor: AppColors.emerald,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingPlanStyleQuestCard extends StatelessWidget {
  final CareerQuest quest;
  final VoidCallback onTap;

  const _SavingPlanStyleQuestCard({
    required this.quest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = quest.isCompleted ? 1.0 : 0.45;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: quest.isCompleted
                ? AppColors.emerald.withValues(alpha: 0.45)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // Left Squircle Icon (Varied per quest with completion badge)
            CareerIconBadge(
              icon: CareerIcons.forQuest(quest),
              accentColor: CareerIcons.forQuestAccent(quest),
              size: 44,
              radius: 13,
              iconSize: 21,
              showCompletedBadge: quest.isCompleted,
            ),
            const SizedBox(width: 14),
            // Right Title + XP Fraction + Horizontal Progress Bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          quest.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                            decoration: quest.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        quest.isCompleted
                            ? '+${quest.xpReward}/${quest.xpReward} XP'
                            : '0/${quest.xpReward} XP',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: quest.isCompleted
                              ? AppColors.emerald
                              : AppColors.terracottaBright,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    quest.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 9),
                  // Dual-Tone Progress Bar matching Screen 5 of Reference
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.background,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        quest.isCompleted
                            ? AppColors.emerald
                            : AppColors.terracotta,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

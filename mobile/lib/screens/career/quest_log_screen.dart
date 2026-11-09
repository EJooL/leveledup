import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/career_companion_model.dart';
import '../../providers/career_provider.dart';
import '../../widgets/quest_card.dart';

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
                side: const BorderSide(color: AppColors.borderBright),
              ),
              title: const Row(
                children: [
                  Icon(Icons.add_task_rounded, color: AppColors.accentCyan),
                  SizedBox(width: 10),
                  Text(
                    'Create Career Quest',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
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
                      'Turn your real-world work deliverables, 1-on-1 goals, or promotions into XP quests.',
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
                        labelText: 'Impact Tag (for future CV bullet)',
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
                          selectedColor: AppColors.accentGold.withValues(alpha: 0.25),
                          backgroundColor: AppColors.surfaceLight,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSel ? AppColors.accentGoldBright : AppColors.textSecondary,
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
      appBar: AppBar(
        title: const Text(
          'CAREER QUEST LOG',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'LVL ${profile.level} • ${profile.currentXp}/${profile.xpToNextLevel} XP',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentGoldBright,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddQuestDialog(activeStage),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.background,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Work Quest',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Career Stage Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              children: CareerStage.values.map((stage) {
                final isSelected = stage == activeStage;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() => _selectedStageFilter = stage);
                      ref.read(careerProvider.notifier).setCareerStage(stage);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.white : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.white : AppColors.border,
                        ),
                      ),
                      child: Text(
                        stage.shortLabel,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? AppColors.background
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Stage Header Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.flag_circle_rounded,
                    color: AppColors.accentCyan,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeStage.label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activeStage.subtitle,
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

          // Quests List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 90),
              itemCount: filteredQuests.length,
              itemBuilder: (context, index) {
                final quest = filteredQuests[index];
                return QuestCard(
                  quest: quest,
                  onToggle: () {
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
                          duration: const Duration(seconds: 2),
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
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/career_icons.dart';
import '../models/career_companion_model.dart';
import '../providers/career_provider.dart';
import 'career_icon_badge.dart';

/// Opens the Brag Doc / Log Win bottom sheet so users can record real work
/// achievements and quantified metrics (+50 XP) for reviews, promotions, and CVs.
void showWorkWinSheet(BuildContext context, WidgetRef ref) {
  final titleCtrl = TextEditingController();
  final impactCtrl = TextEditingController();
  var selectedBranch = SkillBranch.technical;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.85,
                ),
                child: Consumer(
                  builder: (context, ref, _) {
                    final wins = ref.watch(
                      careerProvider.select((p) => p.workWins),
                    );

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.emoji_events_rounded,
                                color: AppColors.accentGoldBright,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Brag Doc · Log Work Win',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.terracotta.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${wins.length} Logged',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.terracottaBright,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Capture shipped work & real metrics while fresh (+50 XP) for performance reviews, promotions, and future CV updates.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: titleCtrl,
                            style: const TextStyle(color: AppColors.white, fontSize: 13.5),
                            decoration: const InputDecoration(
                              labelText: 'What did you achieve or ship?',
                              hintText: 'e.g. Cut checkout API latency via Redis cache',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: impactCtrl,
                            style: const TextStyle(color: AppColors.white, fontSize: 13.5),
                            decoration: const InputDecoration(
                              labelText: 'Measurable Impact / Metric (Optional)',
                              hintText: 'e.g. -28% p95 latency · 12k daily requests',
                            ),
                          ),
                          const SizedBox(height: 14),

                          const Text(
                            'COMPETENCY CATEGORY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: SkillBranch.values.map((branch) {
                              final isSel = branch == selectedBranch;
                              return ChoiceChip(
                                label: Text(branch.title),
                                selected: isSel,
                                onSelected: (_) =>
                                    setModalState(() => selectedBranch = branch),
                                selectedColor:
                                    AppColors.terracotta.withValues(alpha: 0.24),
                                backgroundColor: AppColors.surfaceElevated,
                                labelStyle: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isSel
                                      ? AppColors.terracottaBright
                                      : AppColors.textSecondary,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (titleCtrl.text.trim().isEmpty) return;
                                ref.read(careerProvider.notifier).addWorkWin(
                                      title: titleCtrl.text,
                                      impactMetric: impactCtrl.text,
                                      branch: selectedBranch,
                                    );
                                titleCtrl.clear();
                                impactCtrl.clear();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Work Win saved to Brag Doc! +50 Career XP!',
                                    ),
                                    backgroundColor: AppColors.emerald,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_task_rounded, size: 18),
                              label: const Text('Save Win to Brag Doc (+50 XP)'),
                            ),
                          ),

                          if (wins.isNotEmpty) ...[
                            const SizedBox(height: 22),
                            const Text(
                              'YOUR SAVED WORK WINS (TAP COPY FOR CV / REVIEW)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...wins.map((win) {
                              final accent = CareerIcons.forBranchAccent(win.branch);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    CareerIconBadge(
                                      icon: CareerIcons.forBranch(win.branch),
                                      accentColor: accent,
                                      size: 40,
                                      radius: 11,
                                      iconSize: 19,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            win.title,
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              if (win.impactMetric.isNotEmpty)
                                                Text(
                                                  win.impactMetric,
                                                  style: GoogleFonts.jetBrainsMono(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.emerald,
                                                  ),
                                                ),
                                              Text(
                                                '${win.branch.title} · ${win.dateLabel}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Copy STAR bullet',
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(text: win.toStarBullet()),
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Copied win bullet to clipboard!'),
                                            backgroundColor: AppColors.emerald,
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.copy_rounded,
                                        size: 17,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

/// Opens the Daily Career Check-In sheet so employed or job-hunting users can
/// log daily focus, energy/confidence, and blockers while extending their streak (+35 XP).
void showDailyCheckInSheet(BuildContext context, WidgetRef ref) {
  final profile = ref.read(careerProvider);
  final todayKey = UserCareerProfile.todayDateKey();
  final existingToday = profile.checkIns.where((c) => c.dateKey == todayKey).toList();

  const focusOptions = [
    'Deep Work & Shipping',
    'Team & 1-on-1s',
    'Upskilling & Study',
    'Job Hunt & Outreach',
  ];

  var selectedFocus = existingToday.isNotEmpty
      ? existingToday.first.focusArea
      : (profile.currentStage == CareerStage.jobHunting
          ? 'Job Hunt & Outreach'
          : 'Deep Work & Shipping');
  var confidence =
      existingToday.isNotEmpty ? existingToday.first.confidenceRating : 4;
  final noteCtrl = TextEditingController(
    text: existingToday.isNotEmpty ? existingToday.first.note : '',
  );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.85,
                ),
                child: Consumer(
                  builder: (context, ref, _) {
                    final liveProfile = ref.watch(careerProvider);
                    final checkedToday = liveProfile.hasCheckedInToday;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.event_available_rounded,
                                color: AppColors.terracottaBright,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Daily Career Check-In',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  '🔥 ${liveProfile.streakDays}d Streak',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accentGoldBright,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            checkedToday
                                ? 'Today\'s check-in is logged! You can still update your focus or reflection note below.'
                                : 'Log today\'s primary work focus and confidence pulse to extend your streak (+1d) and earn +35 XP.',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'TODAY\'S PRIMARY FOCUS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: focusOptions.map((opt) {
                              final isSel = opt == selectedFocus;
                              return ChoiceChip(
                                label: Text(opt),
                                selected: isSel,
                                onSelected: (_) =>
                                    setModalState(() => selectedFocus = opt),
                                selectedColor:
                                    AppColors.terracotta.withValues(alpha: 0.24),
                                backgroundColor: AppColors.surfaceElevated,
                                labelStyle: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isSel
                                      ? AppColors.terracottaBright
                                      : AppColors.textSecondary,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'CONFIDENCE & ENERGY PULSE (1–5)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: List.generate(5, (idx) {
                              final rating = idx + 1;
                              final isSel = rating == confidence;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: idx < 4 ? 8 : 0),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () =>
                                        setModalState(() => confidence = rating),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? AppColors.terracotta
                                            : AppColors.surfaceElevated,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSel
                                              ? AppColors.terracotta
                                              : AppColors.border,
                                        ),
                                      ),
                                      child: Text(
                                        '$rating',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: isSel
                                              ? AppColors.white
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: noteCtrl,
                            maxLines: 2,
                            style: const TextStyle(color: AppColors.white, fontSize: 13.5),
                            decoration: const InputDecoration(
                              labelText: 'Quick Reflection or Blocker (Optional)',
                              hintText: 'e.g. Unblocked PR review, prepping 1-on-1 notes',
                            ),
                          ),
                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final awarded = ref
                                    .read(careerProvider.notifier)
                                    .submitDailyCheckIn(
                                      focusArea: selectedFocus,
                                      confidenceRating: confidence,
                                      note: noteCtrl.text,
                                    );
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      awarded
                                          ? 'Daily Check-In complete! +35 XP & Streak boosted!'
                                          : 'Today\'s Check-In updated!',
                                    ),
                                    backgroundColor: AppColors.emerald,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.check_circle_rounded, size: 18),
                              label: Text(
                                checkedToday
                                    ? 'Update Today\'s Check-In'
                                    : 'Complete Check-In (+35 XP)',
                              ),
                            ),
                          ),

                          if (liveProfile.checkIns.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            const Text(
                              'RECENT CHECK-INS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...liveProfile.checkIns.take(3).map((ci) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.terracotta
                                            .withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${ci.confidenceRating}/5',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.terracottaBright,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${ci.focusArea} · ${ci.dateLabel}',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.white,
                                            ),
                                          ),
                                          if (ci.note.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              ci.note,
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      );
    },
  );
}


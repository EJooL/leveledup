import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/career_icons.dart';
import '../../core/utils/pdf_generator.dart';
import '../../models/career_companion_model.dart';
import '../../models/cv_analysis_model.dart';
import '../../providers/career_provider.dart';
import '../../providers/cv_provider.dart';
import '../../widgets/career_icon_badge.dart';
import '../../widgets/placeholder_rich_text.dart';

class WinsScreen extends ConsumerStatefulWidget {
  const WinsScreen({super.key});

  @override
  ConsumerState<WinsScreen> createState() => _WinsScreenState();
}

class _WinsScreenState extends ConsumerState<WinsScreen> {
  final _titleCtrl = TextEditingController();
  final _impactCtrl = TextEditingController();
  SkillBranch _selectedBranch = SkillBranch.technical;
  String _selectedLang = 'auto'; // 'auto', 'en', 'id'
  bool _isSavingWin = false;
  bool _isMergingCv = false;
  final Set<String> _selectedWinIds = {};

  @override
  void dispose() {
    _titleCtrl.dispose();
    _impactCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSaveWin() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter what you achieved or delivered.'),
          backgroundColor: AppColors.crimson,
        ),
      );
      return;
    }

    setState(() => _isSavingWin = true);
    try {
      final created = await ref.read(careerProvider.notifier).addWorkWin(
            title: title,
            impactMetric: _impactCtrl.text.trim(),
            branch: _selectedBranch,
            language: _selectedLang == 'auto' ? null : _selectedLang,
          );
      _titleCtrl.clear();
      _impactCtrl.clear();
      if (created != null) {
        setState(() {
          _selectedWinIds.add(created.id);
        });
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Converted to Zero-Hallucination STAR bullet & saved to Brag Doc!',
          ),
          backgroundColor: AppColors.emerald,
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingWin = false);
    }
  }

  Future<void> _handleMergeIntoCv() async {
    final profile = ref.read(careerProvider);
    final scanState = ref.read(cvScanProvider);
    final idsToMerge = _selectedWinIds.isNotEmpty
        ? _selectedWinIds.toList()
        : profile.workWins.take(3).map((w) => w.id).toList();

    if (idsToMerge.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Log or select at least 1 win to merge into your CV.'),
          backgroundColor: AppColors.crimson,
        ),
      );
      return;
    }

    setState(() => _isMergingCv = true);
    try {
      final mergedCv =
          await ref.read(careerProvider.notifier).mergeWinsIntoLivingCv(
                winIds: idsToMerge,
                currentScannerCv: scanState.rewrittenCv,
                scanToken: scanState.scanToken,
              );
      ref.read(cvScanProvider.notifier).updateRewrittenCvFromWins(mergedCv);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Merged ${idsToMerge.length} STAR bullet(s) into your Living CV! Ready to export as PDF.',
          ),
          backgroundColor: AppColors.emerald,
        ),
      );
    } finally {
      if (mounted) setState(() => _isMergingCv = false);
    }
  }

  Future<void> _handleExportPdf(ImprovedCV cv) async {
    try {
      await PdfCvGenerator.exportAndDownloadPdf(cv);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cv.isIndonesian
                ? 'PDF CV terbaru (${cv.name}) berhasil disimpan ke perangkat Anda!'
                : 'Updated Living CV PDF (${cv.name}) saved to your device!',
          ),
          backgroundColor: AppColors.emerald,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export PDF: $e'),
          backgroundColor: AppColors.crimson,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(careerProvider);
    final scanState = ref.watch(cvScanProvider);
    final wins = profile.workWins;
    final activeLivingCv = profile.latestMergedCv ?? scanState.rewrittenCv;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LIVING CV · BRAG DOC',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.terracottaBright,
                            letterSpacing: 0.7,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Log Wins → STAR CV',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '${wins.length} Logged',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentGoldBright,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Record achievements from any role (Data, Marketing, Finance, Design, HR, Engineering). Gemini turns each win into a Zero-Hallucination STAR bullet you can merge directly into your PDF CV.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),

              // 2. Periodic 3-Month Living-CV Reminder Banner
              if (profile.needsQuarterlyReminder) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.accentGold.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.notifications_active_rounded,
                        color: AppColors.accentGoldBright,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quarterly Living-CV Reminder',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              profile.reminderMessage,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Dismiss reminder',
                        onPressed: () => ref
                            .read(careerProvider.notifier)
                            .dismissQuarterlyReminder(),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 3. Log Win Form Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Log a New Achievement',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                          ),
                        ),
                        // Language pill selector
                        Row(
                          children: [
                            _LangPill(
                              label: 'Auto',
                              selected: _selectedLang == 'auto',
                              onTap: () =>
                                  setState(() => _selectedLang = 'auto'),
                            ),
                            const SizedBox(width: 4),
                            _LangPill(
                              label: 'EN',
                              selected: _selectedLang == 'en',
                              onTap: () => setState(() => _selectedLang = 'en'),
                            ),
                            const SizedBox(width: 4),
                            _LangPill(
                              label: 'ID',
                              selected: _selectedLang == 'id',
                              onTap: () => setState(() => _selectedLang = 'id'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _titleCtrl,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 13.5,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'What did you achieve, deliver, or solve?',
                        hintText:
                            'e.g. Automated monthly financial reconciliation / Launched SEO campaign',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _impactCtrl,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 13.5,
                      ),
                      decoration: const InputDecoration(
                        labelText:
                            'Measurable Impact / Metric (Leave blank for [placeholder])',
                        hintText:
                            'e.g. +32% organic leads · cut closing time by 2 days',
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'CATEGORY (ALL FIELDS)',
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
                        final isSel = branch == _selectedBranch;
                        return ChoiceChip(
                          label: Text(branch.title),
                          selected: isSel,
                          onSelected: (_) =>
                              setState(() => _selectedBranch = branch),
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
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isSavingWin ? null : _handleSaveWin,
                        icon: _isSavingWin
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : const Icon(Icons.auto_awesome_rounded, size: 18),
                        label: Text(
                          _isSavingWin
                              ? 'Generating STAR Bullet...'
                              : 'Convert to STAR Bullet & Save Win',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Saved Wins List + "Add to my CV" Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Saved STAR Wins',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  if (wins.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_selectedWinIds.length == wins.length) {
                            _selectedWinIds.clear();
                          } else {
                            _selectedWinIds
                              ..clear()
                              ..addAll(wins.map((w) => w.id));
                          }
                        });
                      },
                      child: Text(
                        _selectedWinIds.length == wins.length
                            ? 'Clear Selection'
                            : 'Select All (${wins.length})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.terracottaBright,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              if (wins.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        color: AppColors.textMuted,
                        size: 32,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No wins logged yet',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Log an internship project, campaign result, process improvement, or capstone deliverable above to generate your first STAR bullet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                ...wins.map((win) {
                  final isSelected = _selectedWinIds.contains(win.id);
                  final accent = CareerIcons.forBranchAccent(win.branch);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.terracotta
                            : win.isMerged
                                ? AppColors.emerald.withValues(alpha: 0.4)
                                : AppColors.border,
                        width: isSelected ? 1.4 : 1,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedWinIds.remove(win.id);
                          } else {
                            _selectedWinIds.add(win.id);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.check_box_rounded
                                      : Icons.check_box_outline_blank_rounded,
                                  color: isSelected
                                      ? AppColors.terracottaBright
                                      : AppColors.textMuted,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                CareerIconBadge(
                                  icon: CareerIcons.forBranch(win.branch),
                                  accentColor: accent,
                                  size: 36,
                                  radius: 10,
                                  iconSize: 17,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        win.title,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${win.branch.title} · ${win.dateLabel}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (win.isMerged)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.emerald
                                          .withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'In CV',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.emerald,
                                      ),
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
                                        content: Text(
                                          'STAR bullet copied to clipboard!',
                                        ),
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
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    win.language == 'id'
                                        ? 'POIN STAR (ANTI-HALUSINASI)'
                                        : 'STAR CV BULLET (ZERO-HALLUCINATION)',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.terracottaBright,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  PlaceholderRichText(
                                    text: '• ${win.toStarBullet()}',
                                    baseStyle: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.white,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),

                // "Add to my CV" Primary Action Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isMergingCv ? null : _handleMergeIntoCv,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.terracotta,
                      foregroundColor: AppColors.white,
                      shape: const StadiumBorder(),
                    ),
                    icon: _isMergingCv
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.post_add_rounded, size: 20),
                    label: Text(
                      _selectedWinIds.isNotEmpty
                          ? 'Add Selected to My CV (${_selectedWinIds.length})'
                          : 'Add Recent Wins to My CV',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],

              // 5. Living CV Preview & 1-Tap PDF Export Card
              if (activeLivingCv != null) ...[
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.emerald.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.emerald,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              activeLivingCv.isIndonesian
                                  ? 'Dokumen CV Hidup Anda (Siap Unduh PDF)'
                                  : 'Your Living CV (Updated & PDF-Ready)',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${activeLivingCv.name} · ${activeLivingCv.title}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (activeLivingCv.sections.isNotEmpty) ...[
                        Text(
                          activeLivingCv.sections.first.heading.toUpperCase(),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.terracottaBright,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...activeLivingCv.sections.first.bullets
                            .take(4)
                            .map((b) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: PlaceholderRichText(
                              text: '• $b',
                              baseStyle: const TextStyle(
                                fontSize: 12,
                                color: AppColors.white,
                                height: 1.4,
                              ),
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => _handleExportPdf(activeLivingCv),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.emerald,
                            foregroundColor: AppColors.white,
                            shape: const StadiumBorder(),
                          ),
                          icon: const Icon(
                            Icons.download_rounded,
                            size: 19,
                          ),
                          label: Text(
                            activeLivingCv.isIndonesian
                                ? 'Simpan PDF CV Terbaru (.pdf)'
                                : 'Download Updated PDF CV (.pdf)',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LangPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.terracotta : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.terracotta : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}


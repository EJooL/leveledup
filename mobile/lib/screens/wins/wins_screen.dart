import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/career_icons.dart';
import '../../core/utils/docx_generator.dart';
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

  static String _shortBranchLabel(SkillBranch branch) {
    switch (branch) {
      case SkillBranch.technical:
        return 'Delivery';
      case SkillBranch.architecture:
        return 'Quality';
      case SkillBranch.leadership:
        return 'Leadership';
      case SkillBranch.globalOps:
        return 'Metrics';
    }
  }

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
          content: Text('Please enter what you accomplished.'),
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
          content: Text('STAR bullet saved to your wins.'),
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
            'Merged ${idsToMerge.length} STAR bullet(s) into your Living CV! Ready to export as Word (.docx).',
          ),
          backgroundColor: AppColors.emerald,
        ),
      );
    } finally {
      if (mounted) setState(() => _isMergingCv = false);
    }
  }

  Future<void> _handleExportDocx(ImprovedCV cv) async {
    try {
      await DocxCvGenerator.exportAndDownloadDocx(cv);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cv.isIndonesian
                ? 'Word CV (.docx) terbaru (${cv.name}) berhasil disimpan ke perangkat Anda!'
                : 'Updated Living CV (.docx) (${cv.name}) saved to your device!',
          ),
          backgroundColor: AppColors.emerald,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export DOCX: $e'),
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

    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Crisp Header & Logged Wins Counter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Text(
                      'Work Wins',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
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
              const SizedBox(height: 4),
              const Text(
                'Turn work achievements into CV bullets.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // 2. Log Win Form Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'New Win',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                            ),
                          ),
                          // Language pill selector
                          Row(
                            mainAxisSize: MainAxisSize.min,
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
                                onTap: () =>
                                    setState(() => _selectedLang = 'en'),
                              ),
                              const SizedBox(width: 4),
                              _LangPill(
                                label: 'ID',
                                selected: _selectedLang == 'id',
                                onTap: () =>
                                    setState(() => _selectedLang = 'id'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleCtrl,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 13.5,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Achievement',
                        hintText: 'What did you accomplish?',
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
                        labelText: 'Impact (optional)',
                        hintText: 'Numbers or impact (optional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'CATEGORY',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10.5,
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
                          label: Text(_shortBranchLabel(branch)),
                          selected: isSel,
                          showCheckmark: false,
                          onSelected: (_) =>
                              setState(() => _selectedBranch = branch),
                          selectedColor:
                              AppColors.terracotta.withValues(alpha: 0.22),
                          backgroundColor: AppColors.surfaceElevated,
                          side: BorderSide(
                            color: isSel
                                ? AppColors.terracotta
                                : AppColors.border,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
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
                      child: ElevatedButton(
                        onPressed: _isSavingWin ? null : _handleSaveWin,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        child: _isSavingWin
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : const Text(
                                'Save STAR Win',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Saved Wins List + "Add to my CV" Secondary Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Saved Wins',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  if (wins.isNotEmpty) ...[
                    const SizedBox(width: 8),
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
                            ? 'Clear'
                            : 'Select All (${wins.length})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.terracottaBright,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              if (wins.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'No wins yet. Log your first achievement above.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else ...[
                ...wins.map((win) {
                  final isSelected = _selectedWinIds.contains(win.id);
                  final accent = CareerIcons.forBranchAccent(win.branch);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.terracotta
                              : win.isMerged
                                  ? AppColors.emerald.withValues(alpha: 0.45)
                                  : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
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
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Icon(
                                      isSelected
                                          ? Icons.check_box_rounded
                                          : Icons
                                              .check_box_outline_blank_rounded,
                                      color: isSelected
                                          ? AppColors.terracottaBright
                                          : AppColors.textMuted,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  CareerIconBadge(
                                    icon: CareerIcons.forBranch(win.branch),
                                    accentColor: accent,
                                    size: 40,
                                    radius: 12,
                                    iconSize: 20,
                                  ),
                                  const SizedBox(width: 12),
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
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_shortBranchLabel(win.branch)} · ${win.dateLabel}',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 10.5,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: 'Copy STAR bullet',
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(8),
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(text: win.toStarBullet()),
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
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
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(
                                color: AppColors.border,
                                height: 24,
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      win.language == 'id'
                                          ? 'POIN STAR'
                                          : 'STAR BULLET',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.terracottaBright,
                                      ),
                                    ),
                                    if (win.isMerged)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            size: 12,
                                            color: AppColors.emerald,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'IN CV',
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.emerald,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
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
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),

                // Secondary Merge Action Button (preserves single Terracotta CTA rule)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _isMergingCv ? null : _handleMergeIntoCv,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.surfaceElevated,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      side: const BorderSide(
                        color: AppColors.terracotta,
                        width: 1.5,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    icon: _isMergingCv
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.terracottaBright,
                            ),
                          )
                        : const Icon(
                            Icons.post_add_rounded,
                            size: 20,
                            color: AppColors.terracottaBright,
                          ),
                    label: Text(
                      _selectedWinIds.isNotEmpty
                          ? 'Add Selected to My CV (${_selectedWinIds.length})'
                          : 'Add Recent Wins to My CV',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],

              // 4. Living CV Preview & 1-Tap DOCX Export Card
              if (activeLivingCv != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
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
                                  ? 'Dokumen CV Hidup Anda (Siap Unduh DOCX)'
                                  : 'Your Living CV (Updated & DOCX-Ready)',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${activeLivingCv.name} · ${activeLivingCv.title}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (activeLivingCv.sections.isNotEmpty) ...[
                        const Divider(
                          color: AppColors.border,
                          height: 24,
                        ),
                        Builder(
                          builder: (context) {
                            final previewSection =
                                activeLivingCv.sections.firstWhere(
                              (s) => s.type == 'experience',
                              orElse: () => activeLivingCv.sections.first,
                            );
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  previewSection.heading.toUpperCase(),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.terracottaBright,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...previewSection.bullets.take(4).map((b) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: PlaceholderRichText(
                                      text: '• $b',
                                      baseStyle: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.white,
                                        height: 1.45,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _handleExportDocx(activeLivingCv),
                          style: OutlinedButton.styleFrom(
                            backgroundColor:
                                AppColors.emerald.withValues(alpha: 0.14),
                            foregroundColor: AppColors.emerald,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            side: const BorderSide(
                              color: AppColors.emerald,
                              width: 1.5,
                            ),
                            shape: const StadiumBorder(),
                          ),
                          icon: const Icon(
                            Icons.download_rounded,
                            size: 20,
                          ),
                          label: Text(
                            activeLivingCv.isIndonesian
                                ? 'Simpan Word CV Terbaru (.docx)'
                                : 'Download Updated Word CV (.docx)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.terracotta.withValues(alpha: 0.22)
              : AppColors.surfaceElevated,
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
            color: selected
                ? AppColors.terracottaBright
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}


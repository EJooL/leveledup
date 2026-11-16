import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/cv_provider.dart';
import '../../widgets/issue_card.dart';
import '../../widgets/placeholder_rich_text.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  Future<void> _pickPdfDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.size > 4 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File exceeds 4 MB limit. Please upload a smaller PDF.'),
            backgroundColor: AppColors.crimson,
          ),
        );
        return;
      }

      if (file.bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read PDF file bytes.'),
            backgroundColor: AppColors.crimson,
          ),
        );
        return;
      }

      await ref.read(cvScanProvider.notifier).scanPdfFile(
            bytes: file.bytes!,
            fileName: file.name,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick file: $e'),
          backgroundColor: AppColors.crimson,
        ),
      );
    }
  }

  void _showUnlockModal() {
    final controller = TextEditingController(text: ApiConstants.defaultVipCode);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border),
          ),
          title: const Row(
            children: [
              Icon(Icons.vpn_key_rounded, color: AppColors.terracottaBright),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Unlock Full ATS Solutions',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your VIP access code to reveal deep fixes, Before/After examples, missing keywords, and AI Resume Rewrite (+120 XP).',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  labelText: 'Access Code',
                  hintText: 'LEVELEDUPVIP2026',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final code = controller.text.trim();
                Navigator.pop(ctx);
                final ok = await ref
                    .read(cvScanProvider.notifier)
                    .unlockFullReport(code);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Unlocked! +120 Career XP awarded & Zero-Bias badge earned!'
                          : 'Invalid access code. Try LEVELEDUPVIP2026',
                    ),
                    backgroundColor: ok ? AppColors.emerald : AppColors.crimson,
                  ),
                );
              },
              child: const Text('Unlock Report'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(cvScanProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (scanState.isBusy) {
              return _buildScanningProgress(scanState.step);
            }

            if (scanState.analysisResult != null) {
              return _buildCurvedResultsSheet(scanState);
            }

            return _buildTiltedCardsSplashHero(scanState.errorMessage);
          },
        ),
      ),
    );
  }

  /// Matched 1:1 to Screen 1 (Top-Left) of the Reference Image:
  /// Centered Brand Logo + Tilted 3D Dual Card Stack + Centered Headline + Bottom Pill Button
  Widget _buildTiltedCardsSplashHero(String? errorMessage) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        children: [
          // 1. Centered Top Brand Mark (Matched to AtomBank top logo in Screen 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.terracotta,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: AppColors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  children: [
                    TextSpan(
                      text: 'Leveled',
                      style: TextStyle(color: AppColors.white),
                    ),
                    TextSpan(
                      text: 'Up',
                      style: TextStyle(color: AppColors.terracotta),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),

          // 2. Floating Tilted 3D Card Stack (Matched 1:1 to Screen 1 of Reference)
          GestureDetector(
            onTap: _pickPdfDocument,
            child: SizedBox(
              height: 235,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle radial terracotta glow behind cards
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.terracotta.withValues(alpha: 0.22),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // Back Tilted Card (White/Light Slate tilted right)
                  Transform.translate(
                    offset: const Offset(10, 28),
                    child: Transform.rotate(
                      angle: 0.14,
                      child: Container(
                        width: 265,
                        height: 158,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E24),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.borderBright),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 20,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'GLOBAL ATS ENGINE · 5 PILLARS',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Zero-Hallucination AI Rewrite',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Front Tilted Card (Terracotta Gradient tilted left with Cropped White Ring)
                  Transform.translate(
                    offset: const Offset(-6, -14),
                    child: Transform.rotate(
                      angle: -0.12,
                      child: Container(
                        width: 270,
                        height: 162,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFB5462F),
                              Color(0xFFE06348),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.terracotta.withValues(alpha: 0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -34,
                                top: 18,
                                bottom: 18,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.white.withValues(alpha: 0.92),
                                      width: 22,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'ATS SCORE',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.white.withValues(alpha: 0.8),
                                      ),
                                    ),
                                    const Text(
                                      '92 / 100',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.white,
                                        letterSpacing: -0.8,
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'TAP TO UPLOAD PDF (MAX 4MB)',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.white.withValues(alpha: 0.9),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Global Ready · Zero Bias',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.white.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 36),

          // 3. Centered Bold Headline & Subtitle (Matched 1:1 to "Easy Way to Save Your Money" in Screen 1)
          const Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w700,
                height: 1.22,
                letterSpacing: -0.3,
              ),
              children: [
                TextSpan(
                  text: 'Pass ATS Before\n',
                  style: TextStyle(color: AppColors.white),
                ),
                TextSpan(
                  text: 'Getting Rejected',
                  style: TextStyle(color: AppColors.terracottaBright),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'The best companion to scan your PDF resume, fix fatal ATS flaws, and level up your global career.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),

          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.crimson),
              ),
              child: Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.white, fontSize: 12.5),
              ),
            ),
          ],

          const SizedBox(height: 32),

          // 4. Full-Width Stadium Pill CTA Button (Matched 1:1 to "Get Started" pill in Screen 1)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _pickPdfDocument,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.terracotta,
                foregroundColor: AppColors.white,
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'Scan CV (PDF) — Free',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () =>
                ref.read(cvScanProvider.notifier).runSampleDemoScan(),
            child: const Text(
              'Or try instant sample CV demo →',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningProgress(ScanStep step) {
    final stepTitle = step == ScanStep.parsingPdf
        ? 'Extracting PDF text in-memory...'
        : step == ScanStep.rewriting
            ? 'Generating Zero-Hallucination STAR Resume...'
            : 'Auditing 5 Global ATS Pillars & Bias Rules...';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: AppColors.terracotta,
                strokeWidth: 4.5,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              stepTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Checking EEOC compliance, STAR action verbs, and role keywords...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Matched 1:1 to Screen 4 (Bottom-Left in Reference):
  /// Centered Top Metric Header + Curved Top Sheet + 2-Column Overview Square Cards + Issues
  Widget _buildCurvedResultsSheet(CvScanState scanState) {
    final result = scanState.analysisResult!;
    final isUnlocked = result.isUnlocked;
    final matchedCount = result.keywordMatch?.matched.length ?? 0;

    return Column(
      children: [
        // 1. Centered Top Metric Header (Matched to "Total Balance / $1,929.21" in Screen 4)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    result.fileName,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ref.read(cvScanProvider.notifier).resetScanner(),
                    child: const Text(
                      'New Scan ↺',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.terracottaBright,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Overall ATS Readiness',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${result.overallScore} / 100',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppColors.white,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${AppColors.getScoreLabel(result.overallScore)} · ${result.issues.length} flaws detected',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getScoreColor(result.overallScore),
                ),
              ),
            ],
          ),
        ),

        // 2. Curved Sheet Container (Matched to the rounded top sheet in Screen 4 & 5)
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Unlock Pill Action Bar (Matched to dark pill bar at top of sheet in Screen 5)
                  if (!isUnlocked) ...[
                    InkWell(
                      onTap: _showUnlockModal,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.terracotta,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_open_rounded,
                              color: AppColors.white,
                              size: 17,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Unlock Full Fixes & AI Rewrite (VIP Code)',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 2-Column Colored Square Overview Cards (Matched 1:1 to Income / Outcome squares in Screen 4)
                  const Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.terracotta,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: AppColors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Matched Skills',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$matchedCount Keywords',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.terracotta.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.terracottaBright,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'ATS Flaws',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${result.issues.length} Issues',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Diagnostic Issues List
                  const Text(
                    'Diagnostic Flaws',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...result.issues.map(
                    (issue) => IssueCard(
                      issue: issue,
                      onUnlockTap: isUnlocked ? null : _showUnlockModal,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // AI Zero-Hallucination Rewrite Section
                  _buildRewriteSection(scanState),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRewriteSection(CvScanState scanState) {
    final cv = scanState.rewrittenCv;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.terracotta.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppColors.terracottaBright),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Zero-Hallucination Resume Rewrite',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      'Single-column English STAR format with [placeholder] tags (+150 XP)',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (cv == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    ref.read(cvScanProvider.notifier).generateAiRewrite(),
                child: const Text('Rewrite CV Automatically (+150 XP)'),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cv.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    cv.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.terracottaBright,
                    ),
                  ),
                  const Divider(height: 20),
                  PlaceholderRichText(text: cv.summary),
                  const SizedBox(height: 12),
                  ...cv.sections.map(
                    (sec) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sec.heading.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                              letterSpacing: 0.7,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...sec.bullets.map(
                            (b) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: PlaceholderRichText(text: '• $b'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: cv.toMarkdown()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Markdown CV copied to clipboard!'),
                        backgroundColor: AppColors.emerald,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Share.share(
                      cv.toMarkdown(),
                      subject: '${cv.name} - Global ATS Resume',
                    );
                  },
                  icon: const Icon(Icons.ios_share_rounded, size: 16),
                  label: const Text('Export CV'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

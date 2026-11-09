import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/cv_analysis_model.dart';
import '../../providers/cv_provider.dart';
import '../../widgets/issue_card.dart';
import '../../widgets/placeholder_rich_text.dart';
import '../../widgets/score_ring_painter.dart';

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
            side: const BorderSide(color: AppColors.borderBright),
          ),
          title: const Row(
            children: [
              Icon(Icons.vpn_key_rounded, color: AppColors.accentGoldBright),
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
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
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
      appBar: AppBar(
        title: const Text(
          'GLOBAL ATS SCANNER',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          if (scanState.analysisResult != null)
            TextButton.icon(
              onPressed: () => ref.read(cvScanProvider.notifier).resetScanner(),
              icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.accentCyan),
              label: const Text(
                'New Scan',
                style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (scanState.isBusy) {
            return _buildScanningProgress(scanState.step);
          }

          if (scanState.analysisResult != null) {
            return _buildResultsDashboard(scanState);
          }

          return _buildUploaderHero(scanState.errorMessage);
        },
      ),
    );
  }

  Widget _buildUploaderHero(String? errorMessage) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Headline Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.borderBright, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'INTERNATIONAL ATS STANDARD • +75 XP',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accentCyan,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Beat the ATS Filter.\nLand Global Interviews.',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Upload your PDF resume to detect Indonesian personal data bias (photo, TTL, religion, marital status), passive duty bullets, and missing industry keywords.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),

                // Upload Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _pickPdfDocument,
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text('Select PDF Resume (Max 4 MB)'),
                  ),
                ),
                const SizedBox(height: 12),

                // 1-Tap Sample Demo Scan Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(cvScanProvider.notifier).runSampleDemoScan(),
                    icon: const Icon(
                      Icons.bolt_rounded,
                      color: AppColors.accentGoldBright,
                    ),
                    label: const Text('Try Instant Demo Scan (Sample CV)'),
                  ),
                ),
                const SizedBox(height: 14),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined, size: 14, color: AppColors.textMuted),
                    SizedBox(width: 6),
                    Text(
                      'Processed in-memory only. Never stored on disk.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.crimson),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.crimson),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: AppColors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          const Text(
            '5 GLOBAL ATS PILLARS WE AUDIT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 12),
          const _PillarExplainRow(
            icon: Icons.person_off_rounded,
            title: '1. Anti-Bias Personal Info (EEOC)',
            subtitle: 'Flags photos, age/TTL, marital status, religion, and NIK that trigger auto-rejection abroad.',
          ),
          const _PillarExplainRow(
            icon: Icons.view_headline_rounded,
            title: '2. ATS Parser Readability',
            subtitle: 'Detects multi-column collisions, complex tables, and unreadable graphic headers.',
          ),
          const _PillarExplainRow(
            icon: Icons.key_rounded,
            title: '3. Role Keyword Alignment',
            subtitle: 'Matches your skills against target global engineering & product job benchmarks.',
          ),
          const _PillarExplainRow(
            icon: Icons.insights_rounded,
            title: '4. STAR Quantified Achievements',
            subtitle: 'Identifies passive "Responsible for..." duties and converts them into measurable outcomes.',
          ),
          const _PillarExplainRow(
            icon: Icons.spellcheck_rounded,
            title: '5. International English Quality',
            subtitle: 'Eliminates stiff literal translations and empty buzzwords ("hard-working", "under pressure").',
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
              width: 68,
              height: 68,
              child: CircularProgressIndicator(
                color: AppColors.accentCyan,
                strokeWidth: 5,
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

  Widget _buildResultsDashboard(CvScanState scanState) {
    final result = scanState.analysisResult!;
    final isUnlocked = result.isUnlocked;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Score Ring + Summary Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderBright),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    ScoreRingWidget(score: result.overallScore, size: 130),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              result.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${result.issues.length} ATS Issues Detected',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            result.summary,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!isUnlocked) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showUnlockModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGoldBright,
                        foregroundColor: AppColors.background,
                      ),
                      icon: const Icon(Icons.lock_open_rounded, size: 18),
                      label: const Text(
                        'Unlock Full Fixes & AI Rewrite (VIP Code)',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 2. Keyword Match Section
          if (result.keywordMatch != null) ...[
            _buildKeywordCard(result.keywordMatch!, isUnlocked),
            const SizedBox(height: 20),
          ],

          // 3. Detected Issues List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DIAGNOSTIC ISSUES BY PILLAR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.9,
                ),
              ),
              Text(
                isUnlocked ? 'UNLOCKED' : 'FREE PREVIEW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isUnlocked ? AppColors.emerald : AppColors.accentGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...result.issues.map(
            (issue) => IssueCard(
              issue: issue,
              onUnlockTap: isUnlocked ? null : _showUnlockModal,
            ),
          ),
          const SizedBox(height: 20),

          // 4. AI Zero-Hallucination Resume Rewrite Section
          _buildRewriteSection(scanState),
        ],
      ),
    );
  }

  Widget _buildKeywordCard(KeywordMatch kw, bool isUnlocked) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.key_rounded, color: AppColors.accentCyan, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Role Benchmark: ${kw.jobTitle ?? "Software Engineer"}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'MATCHED KEYWORDS',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppColors.emerald,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: kw.matched
                .map(
                  (m) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      m,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emerald,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MISSING KEYWORDS (${kw.missingCount})',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.amber,
                  letterSpacing: 0.6,
                ),
              ),
              if (!isUnlocked)
                GestureDetector(
                  onTap: _showUnlockModal,
                  child: const Text(
                    'Unlock to reveal',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentGoldBright,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (isUnlocked && kw.missing.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: kw.missing
                  .map(
                    (m) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '+ $m',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.amber,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            )
          else
            const Text(
              '🔒 Missing industry keywords are hidden in the free preview.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }

  Widget _buildRewriteSection(CvScanState scanState) {
    final cv = scanState.rewrittenCv;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.accentCyan),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Zero-Hallucination Resume Rewrite',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      'Converts your CV to single-column English STAR format with [placeholder] tags (+150 XP)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (cv == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    ref.read(cvScanProvider.notifier).generateAiRewrite(),
                icon: const Icon(Icons.bolt_rounded),
                label: const Text('Generate ATS-Optimized Resume (+150 XP)'),
              ),
            )
          else ...[
            // Changes Log
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WHAT WE OPTIMIZED (ANTI-FABRICATION ACTIVE)',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accentGoldBright,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...cv.changes.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: AppColors.emerald)),
                          Expanded(
                            child: Text(
                              c,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Rewritten CV Document Preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderBright),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cv.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    cv.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentCyan,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cv.contact.join(' • '),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Divider(height: 24),
                  const Text(
                    'EXECUTIVE SUMMARY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  PlaceholderRichText(text: cv.summary),
                  const SizedBox(height: 16),

                  ...cv.sections.map(
                    (sec) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sec.heading.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...sec.bullets.map(
                            (b) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '•  ',
                                    style: TextStyle(
                                      color: AppColors.accentCyan,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Expanded(child: PlaceholderRichText(text: b)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Export Actions (Copy & Share)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: cv.toMarkdown()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Markdown CV copied to clipboard!'),
                          backgroundColor: AppColors.emerald,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 17),
                    label: const Text('Copy Markdown'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Share.share(
                        cv.toMarkdown(),
                        subject: '${cv.name} - Global ATS Resume',
                      );
                    },
                    icon: const Icon(Icons.ios_share_rounded, size: 17),
                    label: const Text('Export / Share'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PillarExplainRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PillarExplainRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accentCyan, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


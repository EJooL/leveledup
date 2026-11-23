import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/docx_generator.dart';
import '../../providers/cv_provider.dart';
import '../../widgets/issue_card.dart';
import '../../widgets/leveledup_arrow.dart';
import '../../widgets/placeholder_rich_text.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  final bool isActive;

  const ScannerScreen({
    super.key,
    this.isActive = true,
  });

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with TickerProviderStateMixin {
  AnimationController? _entranceController;
  AnimationController? _ambientController;

  Animation<double>? _glowReveal;
  Animation<double>? _backCardProgress;
  Animation<double>? _frontCardProgress;
  Animation<double>? _headlineProgress;
  Animation<double>? _ctaProgress;
  Animation<double>? _ambientFloat;

  void _ensureAnimationsInitialized() {
    if (_entranceController != null) return;

    final entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
    final ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );

    _entranceController = entrance;
    _ambientController = ambient;

    _glowReveal = CurvedAnimation(
      parent: entrance,
      curve: const Interval(0.0, 0.78, curve: Curves.easeOutCubic),
    );
    _backCardProgress = CurvedAnimation(
      parent: entrance,
      curve: const Interval(0.0, 0.72, curve: Curves.easeOutCubic),
    );
    _frontCardProgress = CurvedAnimation(
      parent: entrance,
      curve: const Interval(0.10, 0.86, curve: Curves.easeOutCubic),
    );
    _headlineProgress = CurvedAnimation(
      parent: entrance,
      curve: const Interval(0.22, 0.88, curve: Curves.easeOutCubic),
    );
    _ctaProgress = CurvedAnimation(
      parent: entrance,
      curve: const Interval(0.34, 1.0, curve: Curves.easeOutCubic),
    );
    _ambientFloat = CurvedAnimation(
      parent: ambient,
      curve: Curves.easeInOutSine,
    );

    if (widget.isActive) {
      entrance.forward();
      ambient.repeat(reverse: true);
    }
  }

  @override
  void initState() {
    super.initState();
    _ensureAnimationsInitialized();
  }

  @override
  void didUpdateWidget(covariant ScannerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureAnimationsInitialized();
    if (widget.isActive && !oldWidget.isActive) {
      _entranceController?.forward(from: 0.0);
      _ambientController?.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _ambientController?.stop();
    }
  }

  @override
  void dispose() {
    _entranceController?.dispose();
    _ambientController?.dispose();
    super.dispose();
  }
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
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          title: const Row(
            children: [
              Icon(Icons.vpn_key_rounded, color: AppColors.terracottaBright),
              SizedBox(width: 12),
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
              const SizedBox(height: 16),
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
    _ensureAnimationsInitialized();
    if (widget.isActive &&
        _entranceController!.status == AnimationStatus.dismissed) {
      _entranceController!.forward();
      _ambientController!.repeat(reverse: true);
    }
    final scanState = ref.watch(cvScanProvider);
    final Widget activeView;
    if (scanState.isBusy) {
      activeView = KeyedSubtree(
        key: const ValueKey('scanner_busy'),
        child: _buildScanningProgress(scanState.step),
      );
    } else if (scanState.analysisResult != null) {
      activeView = KeyedSubtree(
        key: ValueKey(
          'scanner_results_${scanState.scanToken ?? scanState.analysisResult!.overallScore}',
        ),
        child: _buildCurvedResultsSheet(scanState),
      );
    } else {
      activeView = KeyedSubtree(
        key: const ValueKey('scanner_splash'),
        child: _buildTiltedCardsSplashHero(scanState.errorMessage),
      );
    }

    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              fit: StackFit.expand,
              alignment: Alignment.topCenter,
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (child, animation) {
            final slide = Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: slide,
                child: child,
              ),
            );
          },
          child: activeView,
        ),
      ),
    );
  }

  /// Matched 1:1 to Screen 1 (Top-Left) of the Reference Image:
  /// Centered Brand Logo + Warm Card-Backed Glow + Sliding Tilted 3D Dual Card Stack
  Widget _buildTiltedCardsSplashHero(String? errorMessage) {
    final glowReveal = _glowReveal!;
    final backCardProgress = _backCardProgress!;
    final frontCardProgress = _frontCardProgress!;
    final headlineProgress = _headlineProgress!;
    final ctaProgress = _ctaProgress!;
    final ambientFloat = _ambientFloat!;
    final backCardWidget = Container(
      width: 264,
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderBright),
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
    );

    final frontCardWidget = Container(
      width: 268,
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.terracotta,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              right: -32,
              top: 16,
              bottom: 16,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.18),
                    width: 24,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
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
                  Text(
                    '92 / 100',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
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
                      const SizedBox(height: 4),
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
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        children: [
          // 1. Centered Top Brand Mark
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LeveledUpArrow(width: 16, height: 24),
              SizedBox(width: 8),
              Text.rich(
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
          const SizedBox(height: 32),

          // 2. Smooth Sliding Floating Tilted Card Stack with Warm Glow Behind Cards
          GestureDetector(
            onTap: _pickPdfDocument,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Wide Warm Orange/Terracotta Radial Glow Radiating Behind the Card Stack
                Positioned.fill(
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: OverflowBox(
                        maxWidth: 460,
                        maxHeight: 380,
                        child: AnimatedBuilder(
                          animation: Listenable.merge([glowReveal, ambientFloat]),
                          builder: (context, _) {
                            final glowT = glowReveal.value;
                            final glowIntensity =
                                glowT * (0.88 + (ambientFloat.value * 0.12));
                            final glowScale =
                                0.84 + (glowT * 0.16) + (ambientFloat.value * 0.05);

                            return Transform.scale(
                              scale: glowScale,
                              child: Container(
                                width: 440,
                                height: 360,
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: const Alignment(0.0, 0.0),
                                    radius: 0.54,
                                    colors: [
                                      AppColors.accentGoldBright
                                          .withValues(alpha: 0.72 * glowIntensity),
                                      AppColors.terracottaBright
                                          .withValues(alpha: 0.50 * glowIntensity),
                                      AppColors.terracotta
                                          .withValues(alpha: 0.22 * glowIntensity),
                                      AppColors.terracotta
                                          .withValues(alpha: 0.06 * glowIntensity),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.34, 0.62, 0.84, 1.0],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  clipBehavior: Clip.none,
                  child: SizedBox(
                    height: 240,
                    width: 320,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        backCardProgress,
                        frontCardProgress,
                        ambientFloat,
                      ]),
                      builder: (context, _) {
                        final backT = backCardProgress.value;
                        final frontT = frontCardProgress.value;
                        final drift = (ambientFloat.value - 0.5) * 2.0; // -1..+1

                        final backDx = 8.0 + (1.0 - backT) * 56.0;
                        final backDy = 24.0 + (1.0 - backT) * 28.0 + (drift * 3.5);
                        final backAngle =
                            0.14 + (1.0 - backT) * 0.12 - (drift * 0.01);

                        final frontDx = -8.0 - (1.0 - frontT) * 64.0;
                        final frontDy =
                            -16.0 + (1.0 - frontT) * 32.0 - (drift * 4.5);
                        final frontAngle =
                            -0.12 - (1.0 - frontT) * 0.12 + (drift * 0.012);
                        final frontScale = 0.92 + (frontT * 0.08);

                        return Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            // Back Tilted Card sliding in from lower-right
                            Opacity(
                              opacity: backT.clamp(0.0, 1.0),
                              child: Transform.translate(
                                offset: Offset(backDx, backDy),
                                child: Transform.rotate(
                                  angle: backAngle,
                                  child: backCardWidget,
                                ),
                              ),
                            ),
                            // Front Tilted Card sliding in from lower-left
                            Opacity(
                              opacity: frontT.clamp(0.0, 1.0),
                              child: Transform.translate(
                                offset: Offset(frontDx, frontDy),
                                child: Transform.rotate(
                                  angle: frontAngle,
                                  child: Transform.scale(
                                    scale: frontScale,
                                    child: frontCardWidget,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Centered Bold Headline & Subtitle sliding smoothly upward
          AnimatedBuilder(
            animation: headlineProgress,
            builder: (context, child) {
              final t = headlineProgress.value;
              return Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, (1.0 - t) * 20.0),
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
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
              ],
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

          // 4. Full-Width Stadium Pill CTA & Demo Buttons sliding smoothly upward
          AnimatedBuilder(
            animation: ctaProgress,
            builder: (context, child) {
              final t = ctaProgress.value;
              return Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, (1.0 - t) * 24.0),
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
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
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => ref
                          .read(cvScanProvider.notifier)
                          .runSampleDemoScan(language: 'id'),
                      icon: const Icon(
                        Icons.translate_rounded,
                        size: 16,
                        color: AppColors.terracottaBright,
                      ),
                      label: const Text(
                        'Demo CV (Indo)',
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => ref
                          .read(cvScanProvider.notifier)
                          .runSampleDemoScan(language: 'en'),
                      icon: const Icon(
                        Icons.language_rounded,
                        size: 16,
                        color: AppColors.terracottaBright,
                      ),
                      label: const Text(
                        'Demo CV (English)',
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 5. Flat "What the Scanner Audits" Card + Privacy Footnote
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Text(
                          'WHAT THE SCANNER AUDITS · 5 PILLARS',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.terracottaBright,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const Divider(color: AppColors.border, height: 1),
                      const _AuditPillarRow(
                        icon: Icons.verified_user_rounded,
                        accentColor: AppColors.terracottaBright,
                        title: 'EEOC & Bias Shield',
                        subtitle:
                            'Detects page-1 headshots, age, marital status, and personal data risks.',
                      ),
                      const Divider(color: AppColors.border, height: 1),
                      const _AuditPillarRow(
                        icon: Icons.auto_awesome_rounded,
                        accentColor: AppColors.accentGoldBright,
                        title: 'Zero-Hallucination STAR Rewrite',
                        subtitle:
                            'Flags weak bullets and inserts [placeholder] metrics instead of fabricating numbers.',
                      ),
                      const Divider(color: AppColors.border, height: 1),
                      const _AuditPillarRow(
                        icon: Icons.translate_rounded,
                        accentColor: AppColors.emerald,
                        title: 'Bilingual ATS Scoring (EN / ID)',
                        subtitle:
                            'Auto-detects CV language and benchmarks all 5 global ATS readiness pillars.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 12,
                      color: AppColors.textDim,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'IN-MEMORY PDF PARSE · MAX 4MB · NO FABRICATED METRICS',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDim,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
            : 'Detecting CV Language & Auditing 5 ATS Pillars...';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                color: AppColors.terracotta,
                strokeWidth: 4,
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.translate_rounded,
                            size: 16,
                            color: AppColors.terracottaBright,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              result.isIndonesian
                                  ? 'Indonesian CV Evaluation'
                                  : 'English CV Evaluation',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      ref.read(cvScanProvider.notifier).resetScanner();
                      _entranceController?.forward(from: 0.0);
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'New Scan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.terracottaBright,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.refresh_rounded,
                          size: 16,
                          color: AppColors.terracottaBright,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${AppColors.getScoreLabel(result.overallScore)} · ${result.issues.length} flaws detected',
                textAlign: TextAlign.center,
                style: GoogleFonts.jetBrainsMono(
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Unlock Pill Action Bar (Single Primary Terracotta CTA when locked)
                  if (!isUnlocked) ...[
                    InkWell(
                      onTap: _showUnlockModal,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
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
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Unlock Full Fixes & AI Rewrite (VIP Code)',
                                maxLines: 1,
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
                    const SizedBox(height: 24),
                  ],

                  // 2-Column Borderless Tonal Overview Tiles (Zero nested borders)
                  const Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, _) {
                      return Row(
                        children: [
                          Expanded(
                            child: Opacity(
                              opacity: t.clamp(0.0, 1.0),
                              child: Transform.translate(
                                offset: Offset((1.0 - t) * -18.0, (1.0 - t) * 12.0),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.emerald
                                              .withValues(alpha: 0.16),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.check_circle_outline_rounded,
                                          color: AppColors.emerald,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Matched Skills',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$matchedCount Keywords',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Opacity(
                              opacity: t.clamp(0.0, 1.0),
                              child: Transform.translate(
                                offset: Offset((1.0 - t) * 18.0, (1.0 - t) * 12.0),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.terracotta
                                              .withValues(alpha: 0.16),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.warning_amber_rounded,
                                          color: AppColors.terracottaBright,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'ATS Flaws',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${result.issues.length} Issues',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 24),

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
                  const SizedBox(height: 24),

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
    final isUnlocked = scanState.analysisResult?.isUnlocked ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppColors.border, height: 1),
        const SizedBox(height: 24),
        const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppColors.terracottaBright),
            SizedBox(width: 8),
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
                  SizedBox(height: 4),
                  Text(
                    'Single-column STAR format with [placeholder] tags (+150 XP)',
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
        const SizedBox(height: 16),
        if (cv == null)
          SizedBox(
            width: double.infinity,
            child: isUnlocked
                ? ElevatedButton(
                    onPressed: () =>
                        ref.read(cvScanProvider.notifier).generateAiRewrite(),
                    child: const Text(
                      'Rewrite CV Automatically (+150 XP)',
                      textAlign: TextAlign.center,
                    ),
                  )
                : OutlinedButton(
                    onPressed: () =>
                        ref.read(cvScanProvider.notifier).generateAiRewrite(),
                    child: const Text(
                      'Rewrite CV Automatically (+150 XP)',
                      textAlign: TextAlign.center,
                    ),
                  ),
          )
        else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
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
                const SizedBox(height: 2),
                Text(
                  cv.title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.terracottaBright,
                  ),
                ),
                if (cv.contact.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    cv.contact.join('  |  '),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                const Divider(color: AppColors.border, height: 20),
                Text(
                  cv.isIndonesian ? 'RINGKASAN' : 'SUMMARY',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                PlaceholderRichText(text: cv.summary),
                const SizedBox(height: 14),
                ...cv.sections.map(
                  (sec) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sec.heading.toUpperCase(),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const Divider(color: AppColors.border, height: 10),
                        if (sec.entries.isNotEmpty)
                          ...sec.entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          entry.title,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ),
                                      if (entry.date.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          entry.date,
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 10.5,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (entry.subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      entry.subtitle,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (entry.bullets.isNotEmpty)
                                    const SizedBox(height: 4),
                                  ...entry.bullets.map(
                                    (b) => Padding(
                                      padding: const EdgeInsets.only(bottom: 5),
                                      child: PlaceholderRichText(text: '• $b'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (sec.skillGroups.isNotEmpty)
                          ...sec.skillGroups.map(
                            (group) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text.rich(
                                TextSpan(
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.white,
                                    height: 1.4,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '${group.category}: ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(text: group.items),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
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
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (isUnlocked)
                ElevatedButton.icon(
                  onPressed: () async {
                    final savedPath =
                        await DocxCvGenerator.exportAndDownloadDocx(cv);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Word CV (.docx) saved locally to $savedPath!'),
                        backgroundColor: AppColors.emerald,
                      ),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Download Word CV (.docx)'),
                )
              else
                OutlinedButton.icon(
                  onPressed: () async {
                    final savedPath =
                        await DocxCvGenerator.exportAndDownloadDocx(cv);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Word CV (.docx) saved locally to $savedPath!'),
                        backgroundColor: AppColors.emerald,
                      ),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Download Word CV (.docx)'),
                ),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: cv.toMarkdown()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('CV text copied to clipboard!'),
                      backgroundColor: AppColors.emerald,
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy Text'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _AuditPillarRow extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;

  const _AuditPillarRow({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
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

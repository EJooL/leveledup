import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import 'leveledup_arrow.dart';

/// Full-screen matte dark "LeveledUp" celebration splash with upward-floating
/// vector arrows matching the LeveledUp brand mark.
///
/// Auto-dismisses smoothly after ~3 seconds, or dismisses early on any tap.
class LevelUpSplashOverlay extends StatefulWidget {
  final int newLevel;
  final String phaseLabel;
  final VoidCallback onDismiss;

  const LevelUpSplashOverlay({
    super.key,
    required this.newLevel,
    required this.phaseLabel,
    required this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required int newLevel,
    required String phaseLabel,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'LeveledUp Celebration',
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (dialogContext, _, __) {
        return LevelUpSplashOverlay(
          newLevel: newLevel,
          phaseLabel: phaseLabel,
          onDismiss: () {
            if (Navigator.of(dialogContext, rootNavigator: true).canPop()) {
              Navigator.of(dialogContext, rootNavigator: true).pop();
            }
          },
        );
      },
    );
  }

  @override
  State<LevelUpSplashOverlay> createState() => _LevelUpSplashOverlayState();
}

class _LevelUpSplashOverlayState extends State<LevelUpSplashOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _timelineController;
  late final AnimationController _earlyDismissController;
  bool _hasDismissed = false;
  bool _isEarlyDismissing = false;

  // 22 deterministic upward-floating vector arrows across balanced horizontal lanes
  static const List<_FloatingArrowSpec> _arrows = [
    _FloatingArrowSpec(x: 0.06, width: 14, speed: 1.05, delay: 0.00, maxOpacity: 0.42, tone: _ArrowTone.terracotta),
    _FloatingArrowSpec(x: 0.11, width: 22, speed: 0.85, delay: 0.14, maxOpacity: 0.28, tone: _ArrowTone.white),
    _FloatingArrowSpec(x: 0.16, width: 16, speed: 1.20, delay: 0.06, maxOpacity: 0.50, tone: _ArrowTone.gold),
    _FloatingArrowSpec(x: 0.21, width: 12, speed: 0.92, delay: 0.22, maxOpacity: 0.34, tone: _ArrowTone.terracotta),
    _FloatingArrowSpec(x: 0.26, width: 26, speed: 0.78, delay: 0.03, maxOpacity: 0.24, tone: _ArrowTone.terracotta),
    _FloatingArrowSpec(x: 0.31, width: 14, speed: 1.15, delay: 0.18, maxOpacity: 0.38, tone: _ArrowTone.white),
    _FloatingArrowSpec(x: 0.36, width: 18, speed: 0.96, delay: 0.10, maxOpacity: 0.46, tone: _ArrowTone.gold),
    _FloatingArrowSpec(x: 0.41, width: 12, speed: 1.28, delay: 0.26, maxOpacity: 0.30, tone: _ArrowTone.terracotta),
    _FloatingArrowSpec(x: 0.46, width: 20, speed: 0.82, delay: 0.05, maxOpacity: 0.22, tone: _ArrowTone.white),
    _FloatingArrowSpec(x: 0.50, width: 28, speed: 0.90, delay: 0.15, maxOpacity: 0.32, tone: _ArrowTone.terracotta),
    _FloatingArrowSpec(x: 0.55, width: 14, speed: 1.18, delay: 0.02, maxOpacity: 0.48, tone: _ArrowTone.gold),
    _FloatingArrowSpec(x: 0.60, width: 18, speed: 0.88, delay: 0.20, maxOpacity: 0.36, tone: _ArrowTone.terracotta),
    _FloatingArrowSpec(x: 0.65, width: 12, speed: 1.24, delay: 0.08, maxOpacity: 0.30, tone: _ArrowTone.white),
    _FloatingArrowSpec(x: 0.70, width: 24, speed: 0.80, delay: 0.16, maxOpacity: 0.40, tone: _ArrowTone.terracotta),
    _FloatingArrowSpec(x: 0.75, width: 16, speed: 1.10, delay: 0.04, maxOpacity: 0.52, tone: _ArrowTone.gold),
    _FloatingArrowSpec(x: 0.80, width: 14, speed: 0.95, delay: 0.24, maxOpacity: 0.28, tone: _ArrowTone.white),
    _FloatingArrowSpec(x: 0.85, width: 22, speed: 1.02, delay: 0.11, maxOpacity: 0.44, tone: _ArrowTone.terracotta),
    _FloatingArrowSpec(x: 0.90, width: 16, speed: 0.86, delay: 0.19, maxOpacity: 0.48, tone: _ArrowTone.gold),
    _FloatingArrowSpec(x: 0.94, width: 12, speed: 1.16, delay: 0.07, maxOpacity: 0.32, tone: _ArrowTone.white),
    _FloatingArrowSpec(x: 0.18, width: 18, speed: 1.08, delay: 0.32, maxOpacity: 0.38, tone: _ArrowTone.terracotta),
    _FloatingArrowSpec(x: 0.52, width: 16, speed: 1.12, delay: 0.34, maxOpacity: 0.42, tone: _ArrowTone.gold),
    _FloatingArrowSpec(x: 0.82, width: 20, speed: 0.94, delay: 0.30, maxOpacity: 0.36, tone: _ArrowTone.terracotta),
  ];

  @override
  void initState() {
    super.initState();
    _timelineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _earlyDismissController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _timelineController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finishDismiss();
      }
    });

    _timelineController.forward();
  }

  void _handleTapToDismiss() {
    if (_hasDismissed || _isEarlyDismissing) return;
    _isEarlyDismissing = true;
    _earlyDismissController.forward().whenComplete(_finishDismiss);
  }

  void _finishDismiss() {
    if (_hasDismissed || !mounted) return;
    _hasDismissed = true;
    widget.onDismiss();
  }

  @override
  void dispose() {
    _timelineController.dispose();
    _earlyDismissController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTapToDismiss,
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _timelineController,
            _earlyDismissController,
          ]),
          builder: (context, _) {
            final t = _timelineController.value;
            final earlyFade = 1.0 - Curves.easeInCubic.transform(
              _earlyDismissController.value,
            );

            // Smooth fade-in (0.00..0.14) and auto fade-out (0.86..1.00)
            final double envelope;
            if (t < 0.14) {
              envelope = Curves.easeOutCubic.transform((t / 0.14).clamp(0.0, 1.0));
            } else if (t > 0.86) {
              envelope = 1.0 -
                  Curves.easeInCubic.transform(((t - 0.86) / 0.14).clamp(0.0, 1.0));
            } else {
              envelope = 1.0;
            }
            final masterOpacity = (envelope * earlyFade).clamp(0.0, 1.0);

            // Centerpiece wordmark entrance (0.08..0.30)
            final titleT = ((t - 0.08) / 0.22).clamp(0.0, 1.0);
            final titleCurve = Curves.easeOutBack.transform(titleT);
            final titleOpacity =
                (Curves.easeOutCubic.transform(titleT) * masterOpacity)
                    .clamp(0.0, 1.0);
            final titleScale = 0.86 + (titleCurve * 0.14);

            // Badge & phase subtitle staggered entrance (0.18..0.36)
            final badgeT = ((t - 0.18) / 0.18).clamp(0.0, 1.0);
            final badgeCurve = Curves.easeOutCubic.transform(badgeT);
            final badgeOpacity = (badgeCurve * masterOpacity).clamp(0.0, 1.0);
            final badgeDy = (1.0 - badgeCurve) * 12.0;

            return Stack(
              fit: StackFit.expand,
              children: [
                // 1. Matte Obsidian Dark Backdrop (#09090B @ 92% opacity)
                ColoredBox(
                  color: AppColors.background
                      .withValues(alpha: 0.92 * masterOpacity),
                ),

                // 2. Upward-Floating Vector Arrows Field (22 staggered lanes)
                RepaintBoundary(
                  child: CustomPaint(
                    painter: _UpwardArrowsPainter(
                      progress: t,
                      masterOpacity: masterOpacity,
                      arrows: _arrows,
                    ),
                    size: Size.infinite,
                  ),
                ),

                // 3. Centerpiece LeveledUp Wordmark & Level Badge
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Column(
                      children: [
                        const Spacer(),
                        Opacity(
                          opacity: titleOpacity,
                          child: Transform.scale(
                            scale: titleScale,
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  LeveledUpArrow(width: 28, height: 42),
                                  SizedBox(width: 12),
                                  Text.rich(
                                    TextSpan(
                                      style: TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.9,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Leveled',
                                          style: TextStyle(
                                            color: AppColors.white,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'Up',
                                          style: TextStyle(
                                            color: AppColors.terracotta,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Opacity(
                          opacity: badgeOpacity,
                          child: Transform.translate(
                            offset: Offset(0, badgeDy),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: AppColors.borderBright,
                                    ),
                                  ),
                                  child: Text(
                                    'LEVEL ${widget.newLevel} UNLOCKED',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.accentGoldBright,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  widget.phaseLabel,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Opacity(
                          opacity: (badgeOpacity * 0.7).clamp(0.0, 1.0),
                          child: Text(
                            'TAP ANYWHERE TO CONTINUE',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

enum _ArrowTone { terracotta, gold, white }

class _FloatingArrowSpec {
  final double x;
  final double width;
  final double speed;
  final double delay;
  final double maxOpacity;
  final _ArrowTone tone;

  const _FloatingArrowSpec({
    required this.x,
    required this.width,
    required this.speed,
    required this.delay,
    required this.maxOpacity,
    required this.tone,
  });
}

class _UpwardArrowsPainter extends CustomPainter {
  final double progress;
  final double masterOpacity;
  final List<_FloatingArrowSpec> arrows;

  const _UpwardArrowsPainter({
    required this.progress,
    required this.masterOpacity,
    required this.arrows,
  });

  Color _resolveColor(_ArrowTone tone) {
    switch (tone) {
      case _ArrowTone.terracotta:
        return AppColors.terracotta;
      case _ArrowTone.gold:
        return AppColors.accentGoldBright;
      case _ArrowTone.white:
        return AppColors.white;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (masterOpacity <= 0.001) return;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (final arrow in arrows) {
      final elapsed = (progress - arrow.delay) * arrow.speed;
      if (elapsed <= 0.0 || elapsed >= 1.15) continue;

      final travel = (elapsed / 1.05).clamp(0.0, 1.0);
      final easedTravel = Curves.easeOut.transform(travel);

      // Smooth fade-in as arrow rises from bottom and fade-out near top edge
      final edgeFade = travel < 0.18
          ? (travel / 0.18)
          : (travel > 0.76 ? ((1.0 - travel) / 0.24) : 1.0);
      final alpha =
          (arrow.maxOpacity * edgeFade.clamp(0.0, 1.0) * masterOpacity)
              .clamp(0.0, 1.0);
      if (alpha <= 0.005) continue;

      final w = arrow.width;
      final h = arrow.width * 1.5;
      final cx = size.width * arrow.x;
      final topY = (size.height + h) - ((size.height + (h * 2.4)) * easedTravel);
      final leftX = cx - (w * 0.5);

      final path = Path()
        ..moveTo(leftX + w * 0.50, topY)
        ..lineTo(leftX + w, topY + h * 0.43)
        ..lineTo(leftX + w * 0.67, topY + h * 0.43)
        ..lineTo(leftX + w * 0.67, topY + h)
        ..lineTo(leftX + w * 0.33, topY + h)
        ..lineTo(leftX + w * 0.33, topY + h * 0.43)
        ..lineTo(leftX, topY + h * 0.43)
        ..close();

      paint.color = _resolveColor(arrow.tone).withValues(alpha: alpha);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _UpwardArrowsPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.masterOpacity != masterOpacity;
  }
}

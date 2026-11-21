import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Vector-crisp solid upward block arrow brand mark placed beside the LeveledUp wordmark.
class LeveledUpArrow extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const LeveledUpArrow({
    super.key,
    this.width = 16,
    this.height = 24,
    this.color = AppColors.terracotta,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _LeveledUpArrowPainter(color: color),
      ),
    );
  }
}

class _LeveledUpArrowPainter extends CustomPainter {
  final Color color;

  const _LeveledUpArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w * 0.50, 0)
      ..lineTo(w, h * 0.43)
      ..lineTo(w * 0.67, h * 0.43)
      ..lineTo(w * 0.67, h)
      ..lineTo(w * 0.33, h)
      ..lineTo(w * 0.33, h * 0.43)
      ..lineTo(0, h * 0.43)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LeveledUpArrowPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

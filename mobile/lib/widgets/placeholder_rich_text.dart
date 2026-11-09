import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Highlights square-bracket [placeholders] in amber/gold to enforce
/// the Zero-Hallucination / Anti-Fabrication policy from mvp.md.
class PlaceholderRichText extends StatelessWidget {
  final String text;
  final double fontSize;

  const PlaceholderRichText({
    super.key,
    required this.text,
    this.fontSize = 13.5,
  });

  @override
  Widget build(BuildContext context) {
    final regex = RegExp(r'\[[^\]]+\]');
    final spans = <InlineSpan>[];
    var lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: fontSize,
              height: 1.5,
            ),
          ),
        );
      }

      final placeholderText = match.group(0)!;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: AppColors.accentGoldBright.withValues(alpha: 0.7),
              ),
            ),
            child: Text(
              placeholderText,
              style: TextStyle(
                color: AppColors.accentGoldBright,
                fontSize: fontSize - 1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      );

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastMatchEnd),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: fontSize,
            height: 1.5,
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}


import 'package:flutter/material.dart';

/// Official LevUp (LeveledUp) Color Palette — Matched 1:1 to Reference UI.
/// Base: Matte Obsidian (#09090B), Charcoal Surfaces (#121215 / #18181C),
/// Primary Accent: Warm Terracotta (#B5462F), Typography: Crisp White (#FAFAFA) & Zinc (#A1A1AA).
class AppColors {
  AppColors._();

  // Base Canvas & Matte Surfaces
  static const Color background = Color(0xFF09090B);      // Main Obsidian Black #09090b
  static const Color surface = Color(0xFF121215);         // Dropzone & Card Surface #121215
  static const Color surfaceLight = Color(0xFF141418);    // Standard Card Container
  static const Color surfaceElevated = Color(0xFF18181C); // Pill & Icon Box Surface #18181c
  static const Color border = Color(0xFF27272A);          // 1px Hairline Border #27272a
  static const Color borderBright = Color(0xFF3F3F46);    // Hover / Active Border #3f3f46

  // Typography Hierarchy
  static const Color white = Color(0xFFFAFAFA);           // Crisp White #fafafa
  static const Color textPrimary = Color(0xFFFAFAFA);     // Headline & Primary Text
  static const Color textSecondary = Color(0xFFA1A1AA);   // Body Copy (Zinc-400) #a1a1aa
  static const Color textMuted = Color(0xFF71717A);       // Sub-labels (Zinc-500) #71717a
  static const Color textDim = Color(0xFF52525B);         // Monospace privacy note #52525b

  // Signature Brand Terracotta & Gamified Accents
  static const Color terracotta = Color(0xFFB5462F);      // Primary LevUp Terracotta #b5462f
  static const Color terracottaBright = Color(0xFFD0533A);// Highlighted Terracotta #d0533a
  static const Color accentCyan = Color(0xFFB5462F);      // Mapped to Terracotta for unified brand
  static const Color accentGold = Color(0xFFD97706);      // Warm Amber / XP Gold
  static const Color accentGoldBright = Color(0xFFF59E0B);// Amber 500
  static const Color accentPurple = Color(0xFFC2410C);    // Deep Rust Accent

  // Semantic Status Colors (ATS Score & Quests)
  static const Color emerald = Color(0xFF10B981);         // 80-100 Ready / Completed
  static const Color amber = Color(0xFFF59E0B);           // 60-79 Polish Needed
  static const Color orange = Color(0xFFB5462F);          // 40-59 Needs Improvement
  static const Color crimson = Color(0xFFEF4444);         // <40 Critical Risk

  /// Helper to get color for an ATS score (0 - 100)
  static Color getScoreColor(int score) {
    if (score >= 80) return emerald;
    if (score >= 60) return amber;
    if (score >= 40) return terracottaBright;
    return crimson;
  }

  /// Helper to get readiness label for an ATS score
  static String getScoreLabel(int score) {
    if (score >= 80) return 'READY TO SEND';
    if (score >= 60) return 'NEEDS POLISH';
    if (score >= 40) return 'NEEDS FIXES';
    return 'ATS REJECTION RISK';
  }
}

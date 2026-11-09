import 'package:flutter/material.dart';

/// Core color palette for LeveledUp Mobile.
/// Primary Base: #020617 (Deep Midnight Slate-950) & Pure White (#FFFFFF)
/// Accents: Electric Cyan, Level-Up Gold, Emerald, and Crimson.
class AppColors {
  AppColors._();

  // Base Canvas & Surfaces
  static const Color background = Color(0xFF020617); // Main palette #020617
  static const Color surface = Color(0xFF0B1120);    // Elevated dark surface
  static const Color surfaceLight = Color(0xFF0F172A); // Card container
  static const Color surfaceElevated = Color(0xFF1E293B); // Interactive card / chip
  static const Color border = Color(0x1AFFFFFF);     // 10% white subtle border
  static const Color borderBright = Color(0x33FFFFFF); // 20% white active border

  // Typography & Monochrome Accents
  static const Color white = Color(0xFFFFFFFF);      // Main contrast white
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Gamified & Brand Accents
  static const Color accentCyan = Color(0xFF38BDF8);     // Electric Cyan (Tech / Active)
  static const Color accentCyanDark = Color(0xFF0284C7);
  static const Color accentGold = Color(0xFFF59E0B);     // XP / Level-Up Gold
  static const Color accentGoldBright = Color(0xFFFBBF24);
  static const Color accentPurple = Color(0xFFA855F7);   // Epic Rank / Mastery

  // Semantic Status Colors (ATS Score & Quests)
  static const Color emerald = Color(0xFF10B981);        // 80-100 Ready / Completed
  static const Color amber = Color(0xFFF59E0B);          // 60-79 Polish Needed
  static const Color orange = Color(0xFFF97316);         // 40-59 Needs Improvement
  static const Color crimson = Color(0xFFF43F5E);        // <40 Critical Risk

  /// Helper to get color for an ATS score (0 - 100)
  static Color getScoreColor(int score) {
    if (score >= 80) return emerald;
    if (score >= 60) return amber;
    if (score >= 40) return orange;
    return crimson;
  }

  /// Helper to get readiness label for an ATS score
  static String getScoreLabel(int score) {
    if (score >= 80) return 'GLOBAL READY';
    if (score >= 60) return 'NEEDS POLISH';
    if (score >= 40) return 'NEEDS FIXES';
    return 'HIGH ATS RISK';
  }
}


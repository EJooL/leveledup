import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  /// Brand wordmark typography (`Poppins`) reserved exclusively for the
  /// `LeveledUp` logo wordmark.
  static TextStyle wordmark({
    double fontSize = 32,
    FontWeight fontWeight = FontWeight.w800,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Editorial display typography (`Bricolage Grotesque`) for headings and
  /// section titles with tight `-0.02em` letter-spacing.
  static TextStyle display({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.bricolageGrotesque(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing ?? (fontSize * -0.02),
    );
  }

  /// Primary editorial sans (`Plus Jakarta Sans`) for body copy, buttons,
  /// inputs, and long-form content.
  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Compact UI label style (`Plus Jakarta Sans`) for chips, badges, eyebrows,
  /// pill labels, and `[placeholder]` tokens.
  static TextStyle label({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Tabular-figure numeric style (`Plus Jakarta Sans` + `tnum`) for ATS
  /// scores, deltas, XP counters, and aligned metrics without monospace.
  static TextStyle numeric({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle _editorialHeading(
    TextStyle? base,
    double fallbackSize, {
    FontWeight fontWeight = FontWeight.w700,
  }) {
    final size = base?.fontSize ?? fallbackSize;
    return GoogleFonts.bricolageGrotesque(
      textStyle: base,
      fontSize: size,
      fontWeight: fontWeight,
      color: AppColors.white,
      letterSpacing: size * -0.02,
    );
  }

  static ThemeData get darkTheme {
    final plusJakartaFamily = GoogleFonts.plusJakartaSans().fontFamily;
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.dark().textTheme,
    ).apply(
      fontFamily: plusJakartaFamily,
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.white,
    );

    final editorialTextTheme = baseTextTheme.copyWith(
      displayLarge: _editorialHeading(baseTextTheme.displayLarge, 57),
      displayMedium: _editorialHeading(baseTextTheme.displayMedium, 45),
      displaySmall: _editorialHeading(baseTextTheme.displaySmall, 36),
      headlineLarge: _editorialHeading(baseTextTheme.headlineLarge, 32),
      headlineMedium: _editorialHeading(baseTextTheme.headlineMedium, 28),
      headlineSmall: _editorialHeading(baseTextTheme.headlineSmall, 24),
      titleLarge: _editorialHeading(baseTextTheme.titleLarge, 22),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: plusJakartaFamily,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.terracotta,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.terracotta,
        onPrimary: AppColors.white,
        secondary: AppColors.terracottaBright,
        onSecondary: AppColors.white,
        tertiary: AppColors.accentGoldBright,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.crimson,
      ),
      textTheme: editorialTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: display(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.terracotta,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
          shape: const StadiumBorder(),
          textStyle: body(
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: AppColors.surfaceElevated,
          side: const BorderSide(color: AppColors.border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: body(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        hintStyle: body(color: AppColors.textMuted, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.terracotta, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.terracotta.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return label(
              color: AppColors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            );
          }
          return label(
            color: AppColors.textMuted,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.terracottaBright, size: 23);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 21);
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: body(
          color: AppColors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: AppColors.terracottaBright,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}

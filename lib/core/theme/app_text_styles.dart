import 'package:flutter/material.dart';

/// Type scale. Fraunces for display (date, big numbers, screen titles),
/// Manrope for everything else. Colors are applied by the theme.
abstract final class AppTextStyles {
  static const String serif = 'Fraunces';
  static const String sans = 'Manrope';

  // Used only if a bundled font file is missing.
  static const List<String> _serifFallback = ['serif'];
  static const List<String> _sansFallback = ['sans-serif'];

  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  /// Extra letter spacing for codes (invite codes): easier to read out.
  static const double codeTracking = 2;
  static const double codeTrackingLarge = 3;

  static TextStyle _serif(double size, FontWeight weight, double height) {
    return TextStyle(
      fontFamily: serif,
      fontFamilyFallback: _serifFallback,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: -0.2,
    );
  }

  static TextStyle _sans(
    double size,
    FontWeight weight,
    double height, {
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: sans,
      fontFamilyFallback: _sansFallback,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextTheme textTheme(Color text, Color muted) {
    return TextTheme(
      // Big numbers (money totals). Tabular figures keep digits aligned.
      displayLarge: _serif(
        44,
        FontWeight.w500,
        1.1,
      ).copyWith(fontFeatures: tabular, color: text),
      // The date on Today.
      displayMedium: _serif(36, FontWeight.w500, 1.15).copyWith(color: text),
      displaySmall: _serif(30, FontWeight.w500, 1.2).copyWith(color: text),
      // Screen titles.
      headlineMedium: _serif(28, FontWeight.w500, 1.2).copyWith(color: text),
      headlineSmall: _serif(22, FontWeight.w500, 1.25).copyWith(color: text),
      titleLarge: _sans(18, FontWeight.w600, 1.3).copyWith(color: text),
      titleMedium: _sans(16, FontWeight.w600, 1.35).copyWith(color: text),
      titleSmall: _sans(14, FontWeight.w600, 1.35).copyWith(color: text),
      bodyLarge: _sans(16, FontWeight.w400, 1.45).copyWith(color: text),
      bodyMedium: _sans(15, FontWeight.w400, 1.45).copyWith(color: text),
      bodySmall: _sans(13, FontWeight.w400, 1.4).copyWith(color: muted),
      labelLarge: _sans(15, FontWeight.w600, 1.2).copyWith(color: text),
      labelMedium: _sans(
        13,
        FontWeight.w600,
        1.2,
        letterSpacing: 0.1,
      ).copyWith(color: text),
      labelSmall: _sans(
        12,
        FontWeight.w600,
        1.2,
        letterSpacing: 0.4,
      ).copyWith(color: muted),
    );
  }
}

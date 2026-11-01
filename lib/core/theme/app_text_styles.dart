import 'package:flutter/material.dart';

/// Type scale: one clean sans (Manrope) everywhere, with real hierarchy
/// from weight, size and tight tracking on big text. Colors are applied by
/// the theme.
abstract final class AppTextStyles {
  static const String sans = 'Manrope';

  // Used only if a bundled font file is missing.
  static const List<String> _sansFallback = ['sans-serif'];

  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  /// Extra letter spacing for codes (invite codes): easier to read out.
  static const double codeTracking = 2;
  static const double codeTrackingLarge = 3;

  /// Big text reads tighter; small labels a little looser.
  static const double _displayTracking = -1;
  static const double _headlineTracking = -0.5;

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

  static TextStyle _display(double size) =>
      _sans(size, FontWeight.w700, 1.1, letterSpacing: _displayTracking);

  static TextStyle _headline(double size) =>
      _sans(size, FontWeight.w700, 1.2, letterSpacing: _headlineTracking);

  static TextTheme textTheme(Color text, Color muted) {
    return TextTheme(
      // Big numbers (money totals). Tabular figures keep digits aligned.
      displayLarge: _display(44).copyWith(fontFeatures: tabular, color: text),
      // The date on Today.
      displayMedium: _display(34).copyWith(color: text),
      displaySmall: _display(30).copyWith(color: text),
      // Screen titles.
      headlineMedium: _headline(28).copyWith(color: text),
      headlineSmall: _headline(22).copyWith(color: text),
      titleLarge: _sans(18, FontWeight.w700, 1.3).copyWith(color: text),
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

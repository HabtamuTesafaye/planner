import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner/core/theme/app_colors.dart';

/// WCAG 2.x contrast ratio between two opaque colors.
double contrast(Color a, Color b) {
  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  double luminance(Color c) =>
      0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
  final la = luminance(a);
  final lb = luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  const aa = 4.5;
  // Non-text UI parts (icons, indicators, borders of active controls).
  const nonText = 3.0;

  for (final (name, c) in [
    ('light', AppColors.light),
    ('dark', AppColors.dark),
  ]) {
    group('$name theme text contrast (AA 4.5:1)', () {
      final textPairs = <String, (Color, Color)>{
        'text on background': (c.text, c.background),
        'text on surface': (c.text, c.surface),
        'text on surfaceSunken': (c.text, c.surfaceSunken),
        'text on accentSoft': (c.text, c.accentSoft),
        'text on successSoft': (c.text, c.successSoft),
        'muted on background': (c.muted, c.background),
        'muted on surface': (c.muted, c.surface),
        'muted on surfaceSunken': (c.muted, c.surfaceSunken),
        'accentText on background': (c.accentText, c.background),
        'accentText on surface': (c.accentText, c.surface),
        'onAccent on accentText (filled button)': (c.onAccent, c.accentText),
        'success on background': (c.success, c.background),
        'success on surface': (c.success, c.surface),
        // Snackbar: inverted colors.
        'snackbar text': (c.background, c.text),
      };
      textPairs.forEach((label, pair) {
        test(label, () {
          final ratio = contrast(pair.$1, pair.$2);
          expect(
            ratio,
            greaterThanOrEqualTo(aa),
            reason: '$label is ${ratio.toStringAsFixed(2)}:1',
          );
        });
      });
    });

    group('$name theme non-text contrast (3:1)', () {
      final pairs = <String, (Color, Color)>{
        'accent on background': (c.accent, c.background),
        'accent on surface': (c.accent, c.surface),
        'success check on surface': (c.success, c.surface),
      };
      pairs.forEach((label, pair) {
        test(label, () {
          expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(nonText));
        });
      });
    });
  }

  test('snackbar action color is readable on the snackbar', () {
    // Light theme snackbar is dark and uses the dark accent, and vice versa.
    expect(
      contrast(AppColors.dark.accentText, AppColors.light.text),
      greaterThanOrEqualTo(aa),
    );
    expect(
      contrast(AppColors.light.accentText, AppColors.dark.text),
      greaterThanOrEqualTo(aa),
    );
  });
}

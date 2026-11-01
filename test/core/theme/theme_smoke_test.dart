import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner/core/theme/app_colors.dart';
import 'package:planner/core/theme/app_text_styles.dart';
import 'package:planner/core/theme/app_theme.dart';

void main() {
  for (final (name, theme, tokens, brightness) in [
    ('light', AppTheme.light, AppColors.light, Brightness.light),
    ('dark', AppTheme.dark, AppColors.dark, Brightness.dark),
  ]) {
    group('$name theme', () {
      test('uses Material 3 and the right brightness', () {
        expect(theme.useMaterial3, isTrue);
        expect(theme.brightness, brightness);
        expect(theme.colorScheme.brightness, brightness);
      });

      test('is built from the tokens', () {
        expect(theme.extension<AppColors>(), tokens);
        expect(theme.scaffoldBackgroundColor, tokens.background);
        expect(theme.colorScheme.surface, tokens.surface);
        expect(theme.colorScheme.onSurface, tokens.text);
        expect(theme.colorScheme.primary, tokens.accentText);
        expect(theme.dividerTheme.color, tokens.divider);
      });

      test('uses bundled fonts with system fallbacks', () {
        expect(theme.textTheme.displayMedium!.fontFamily, AppTextStyles.serif);
        expect(theme.textTheme.bodyLarge!.fontFamily, AppTextStyles.sans);
        expect(
          theme.textTheme.displayMedium!.fontFamilyFallback,
          contains('serif'),
        );
        expect(
          theme.textTheme.displayLarge!.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
      });

      test('no tint overlays and no default blue', () {
        expect(theme.colorScheme.surfaceTint, Colors.transparent);
        expect(theme.colorScheme.primary, isNot(Colors.blue));
      });

      test('bottom sheets and snackbars are styled', () {
        expect(theme.bottomSheetTheme.showDragHandle, isTrue);
        expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
      });
    });
  }
}

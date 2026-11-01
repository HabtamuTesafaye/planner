import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_component_themes.dart';
import 'app_text_styles.dart';

/// Builds the light and dark [ThemeData]. The ColorScheme is assembled by
/// hand from [AppColors] (no `fromSeed`).
abstract final class AppTheme {
  static ThemeData get light => _build(AppColors.light, Brightness.light);
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  /// System bar style for the given brightness: transparent bars
  /// (edge-to-edge) with icons that contrast with the background.
  static SystemUiOverlayStyle overlayStyle(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: brightness,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    );
  }

  static ColorScheme _scheme(AppColors c, Brightness b) {
    return ColorScheme(
      brightness: b,
      primary: c.accentText,
      onPrimary: c.onAccent,
      primaryContainer: c.accentSoft,
      onPrimaryContainer: c.text,
      secondary: c.muted,
      onSecondary: c.surface,
      secondaryContainer: c.surfaceSunken,
      onSecondaryContainer: c.text,
      tertiary: c.success,
      onTertiary: c.surface,
      tertiaryContainer: c.successSoft,
      onTertiaryContainer: c.text,
      error: c.accentText,
      onError: c.onAccent,
      errorContainer: c.accentSoft,
      onErrorContainer: c.text,
      surface: c.surface,
      onSurface: c.text,
      onSurfaceVariant: c.muted,
      surfaceDim: c.background,
      surfaceBright: c.surface,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surface,
      surfaceContainerHighest: c.surfaceSunken,
      outline: c.border,
      outlineVariant: c.divider,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: c.text,
      onInverseSurface: c.background,
      inversePrimary: c.accent,
      surfaceTint: Colors.transparent,
    );
  }

  static ThemeData _build(AppColors c, Brightness b) {
    final scheme = _scheme(c, b);
    final text = AppTextStyles.textTheme(c.text, c.muted);
    final components = AppComponentThemes(c, text);

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      extensions: [c],
      fontFamily: AppTextStyles.sans,
      textTheme: text,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      dividerColor: c.divider,
      // Ripple is cheaper than sparkle on low-end devices.
      splashFactory: InkRipple.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      iconTheme: IconThemeData(color: c.text, size: 24, weight: 300),
      appBarTheme: AppBarThemeData(
        backgroundColor: c.background,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: text.headlineSmall,
        systemOverlayStyle: overlayStyle(b),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.accentText,
        selectionColor: c.accent.withValues(alpha: 0.25),
        selectionHandleColor: c.accentText,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.surfaceSunken,
      ),
      dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: c.muted,
        textColor: c.text,
        minVerticalPadding: 12,
      ),
      navigationBarTheme: components.navigationBar,
      filledButtonTheme: components.filledButton,
      outlinedButtonTheme: components.outlinedButton,
      textButtonTheme: components.textButton,
      iconButtonTheme: components.iconButton,
      inputDecorationTheme: components.inputDecoration,
      chipTheme: components.chip,
      segmentedButtonTheme: components.segmentedButton,
      snackBarTheme: components.snackBar,
      bottomSheetTheme: components.bottomSheet,
      datePickerTheme: components.datePicker,
      timePickerTheme: components.timePicker,
      dialogTheme: components.dialog,
    );
  }
}

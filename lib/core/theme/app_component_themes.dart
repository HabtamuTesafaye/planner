import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Component themes, kept apart from [AppTheme] so each file stays small.
/// Screens never style these widgets themselves.
class AppComponentThemes {
  const AppComponentThemes(this.c, this.text);

  final AppColors c;
  final TextTheme text;

  static const _controlShape = RoundedRectangleBorder(
    borderRadius: AppRadius.controlAll,
  );
  static const _minButton = Size(64, AppSizes.touchTarget);
  static const _buttonPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.xl,
    vertical: AppSpacing.md,
  );

  NavigationBarThemeData get navigationBar => NavigationBarThemeData(
    height: 68,
    elevation: 0,
    backgroundColor: c.background,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.transparent,
    indicatorColor: c.accentSoft,
    indicatorShape: const StadiumBorder(),
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    iconTheme: WidgetStateProperty.resolveWith(
      (s) => IconThemeData(
        size: AppSizes.icon,
        weight: 300,
        color: s.contains(WidgetState.selected) ? c.accentText : c.muted,
      ),
    ),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (s) => text.labelMedium!.copyWith(
        color: s.contains(WidgetState.selected) ? c.text : c.muted,
      ),
    ),
  );

  FilledButtonThemeData get filledButton => FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: c.accentText,
      foregroundColor: c.onAccent,
      disabledBackgroundColor: c.surfaceSunken,
      disabledForegroundColor: c.muted,
      minimumSize: _minButton,
      padding: _buttonPadding,
      shape: _controlShape,
      textStyle: text.labelLarge,
      elevation: 0,
    ),
  );

  OutlinedButtonThemeData get outlinedButton => OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: c.text,
      disabledForegroundColor: c.muted,
      minimumSize: _minButton,
      padding: _buttonPadding,
      shape: _controlShape,
      side: BorderSide(color: c.border),
      textStyle: text.labelLarge,
    ),
  );

  TextButtonThemeData get textButton => TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: c.accentText,
      disabledForegroundColor: c.muted,
      minimumSize: _minButton,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      shape: _controlShape,
      textStyle: text.labelLarge,
    ),
  );

  FloatingActionButtonThemeData get fab => FloatingActionButtonThemeData(
    backgroundColor: c.accentText,
    foregroundColor: c.onAccent,
    elevation: 0,
    focusElevation: 0,
    hoverElevation: 0,
    highlightElevation: 0,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetAll),
    extendedTextStyle: text.labelLarge,
  );

  IconButtonThemeData get iconButton => IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: c.text,
      minimumSize: const Size.square(AppSizes.touchTarget),
      iconSize: AppSizes.icon,
    ),
  );

  InputDecorationThemeData get inputDecoration {
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: AppRadius.controlAll,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecorationThemeData(
      filled: true,
      fillColor: c.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md + 2,
      ),
      border: border(c.border),
      enabledBorder: border(c.border),
      disabledBorder: border(c.divider),
      focusedBorder: border(c.accentText, 1.5),
      errorBorder: border(c.attention),
      focusedErrorBorder: border(c.attention, 1.5),
      labelStyle: text.bodyMedium!.copyWith(color: c.muted),
      floatingLabelStyle: text.labelMedium!.copyWith(color: c.text),
      hintStyle: text.bodyMedium!.copyWith(color: c.muted),
      helperStyle: text.bodySmall,
      errorStyle: text.bodySmall!.copyWith(color: c.attention),
      helperMaxLines: 2,
      errorMaxLines: 3,
    );
  }

  ChipThemeData get chip => ChipThemeData(
    backgroundColor: c.surface,
    selectedColor: c.accentSoft,
    disabledColor: c.surfaceSunken,
    checkmarkColor: c.accentText,
    labelStyle: text.labelMedium,
    secondaryLabelStyle: text.labelMedium,
    side: BorderSide(color: c.divider),
    shape: const StadiumBorder(),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    showCheckmark: false,
    elevation: 0,
    pressElevation: 0,
  );

  SegmentedButtonThemeData get segmentedButton => SegmentedButtonThemeData(
    style: SegmentedButton.styleFrom(
      backgroundColor: c.surface,
      foregroundColor: c.muted,
      selectedBackgroundColor: c.accentSoft,
      selectedForegroundColor: c.text,
      side: BorderSide(color: c.border),
      textStyle: text.labelMedium,
      minimumSize: const Size(0, AppSizes.touchTarget),
      shape: _controlShape,
    ),
  );

  SnackBarThemeData get snackBar => SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: c.text,
    contentTextStyle: text.bodyMedium!.copyWith(color: c.background),
    // The snackbar is inverted, so it uses the other theme's accent.
    actionTextColor: c == AppColors.light
        ? AppColors.dark.accentText
        : AppColors.light.accentText,
    shape: _controlShape,
    elevation: 0,
    insetPadding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      0,
      AppSpacing.lg,
      AppSpacing.lg,
    ),
  );

  BottomSheetThemeData get bottomSheet => BottomSheetThemeData(
    backgroundColor: c.surface,
    modalBackgroundColor: c.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    modalElevation: 0,
    showDragHandle: true,
    dragHandleColor: c.border,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
    constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
    clipBehavior: Clip.antiAlias,
  );

  DatePickerThemeData get datePicker => DatePickerThemeData(
    backgroundColor: c.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetAll),
    headerBackgroundColor: c.surface,
    headerForegroundColor: c.text,
    headerHeadlineStyle: text.headlineMedium,
    headerHelpStyle: text.labelMedium!.copyWith(color: c.muted),
    dividerColor: c.divider,
    todayForegroundColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected) ? c.onAccent : c.accentText,
    ),
    todayBorder: BorderSide(color: c.accentText),
    dayStyle: text.bodyMedium,
    yearStyle: text.bodyMedium,
    weekdayStyle: text.labelMedium!.copyWith(color: c.muted),
    cancelButtonStyle: TextButton.styleFrom(foregroundColor: c.muted),
    confirmButtonStyle: TextButton.styleFrom(foregroundColor: c.accentText),
  );

  TimePickerThemeData get timePicker => TimePickerThemeData(
    backgroundColor: c.surface,
    elevation: 0,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetAll),
    dialBackgroundColor: c.surfaceSunken,
    hourMinuteColor: c.surfaceSunken,
    hourMinuteTextColor: c.text,
    dayPeriodBorderSide: BorderSide(color: c.border),
    helpTextStyle: text.labelMedium!.copyWith(color: c.muted),
    cancelButtonStyle: TextButton.styleFrom(foregroundColor: c.muted),
    confirmButtonStyle: TextButton.styleFrom(foregroundColor: c.accentText),
  );

  DialogThemeData get dialog => DialogThemeData(
    backgroundColor: c.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetAll),
    titleTextStyle: text.headlineSmall,
    contentTextStyle: text.bodyMedium,
  );
}

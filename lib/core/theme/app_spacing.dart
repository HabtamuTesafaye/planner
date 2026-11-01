import 'package:flutter/widgets.dart';

/// Spacing scale: 4, 8, 12, 16, 24, 32. Nothing else.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Horizontal page padding.
  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: lg);
}

/// Corner radius tokens.
abstract final class AppRadius {
  /// Inputs and buttons.
  static const double control = 12;

  /// Bottom sheets and dialogs.
  static const double sheet = 16;

  static const BorderRadius controlAll = BorderRadius.all(
    Radius.circular(control),
  );
  static const BorderRadius sheetAll = BorderRadius.all(Radius.circular(sheet));
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}

/// Layout and sizing constants.
abstract final class AppSizes {
  /// Content is centered at this width on large screens.
  static const double maxContentWidth = 600;

  /// Minimum touch target.
  static const double touchTarget = 48;

  static const double icon = 24;
  static const double iconSmall = 22;

  /// Thin progress bar height.
  static const double progressBar = 6;
}

/// Animation durations (max 250 ms).
abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 250);
}

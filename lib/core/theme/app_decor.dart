import 'package:flutter/painting.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Shared decorations, so every card looks the same.
abstract final class AppDecor {
  /// A soft surface card: rounded, lifted by a small shadow in light mode
  /// and outlined by a hairline in dark mode.
  static BoxDecoration card(AppColors c) => BoxDecoration(
    color: c.surface,
    borderRadius: AppRadius.cardAll,
    border: Border.all(color: c.cardEdge),
    boxShadow: shadow(c),
  );

  static List<BoxShadow> shadow(AppColors c) => [
    BoxShadow(
      color: c.shadow,
      blurRadius: AppSizes.shadowBlur,
      offset: const Offset(0, AppSizes.shadowOffset),
    ),
  ];
}

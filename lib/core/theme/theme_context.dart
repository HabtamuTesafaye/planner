import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Short access to theme tokens from widgets: `context.colors.muted`,
/// `context.text.bodyLarge`.
extension ThemeContext on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;

  TextTheme get text => Theme.of(this).textTheme;
}

import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

/// Thin rounded progress bar (no CircularProgressIndicator, AGENTS.md 3).
/// [value] is 0..1; values above 1 show as full in the success color.
class ThinProgressBar extends StatelessWidget {
  const ThinProgressBar({
    required this.value,
    required this.semanticLabel,
    this.height = AppSizes.progressBar,
    super.key,
  });

  final double value;
  final String semanticLabel;

  /// Bar thickness; [AppSizes.progressBarHero] for a screen's main number.
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final clamped = value.clamp(0.0, 1.0);
    final complete = value >= 1;
    return Semantics(
      label: semanticLabel,
      value: '${(clamped * 100).round()}%',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: SizedBox(
          height: height,
          child: ColoredBox(
            color: colors.surfaceSunken,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: AppMotion.of(context, AppDurations.slow),
                curve: AppMotion.enter,
                widthFactor: clamped,
                heightFactor: 1,
                child: ColoredBox(
                  color: complete ? colors.success : colors.accent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

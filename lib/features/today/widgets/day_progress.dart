import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../data/models/task.dart';

/// Three small rings, like the app mark: filled when done, outlined when
/// planned, faint when the slot is free.
class DayProgress extends StatelessWidget {
  const DayProgress({required this.planned, required this.done, super.key});

  final int planned;
  final int done;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final duration = AppMotion.of(context, AppDurations.normal);
    return Semantics(
      label: '$done of $planned done, ${Task.dailyLimit - planned} free',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < Task.dailyLimit; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            AnimatedContainer(
              duration: duration,
              curve: AppMotion.enter,
              width: AppSizes.progressDot,
              height: AppSizes.progressDot,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < done ? colors.success : Colors.transparent,
                border: Border.all(
                  width: AppSizes.ringStroke,
                  color: i < done
                      ? colors.success
                      : (i < planned ? colors.muted : colors.divider),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

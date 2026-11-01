import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/circle_check.dart';
import '../../../data/models/project.dart';

/// One project step: check it off, plan it for today, swipe left to delete.
class StepRow extends StatelessWidget {
  const StepRow({
    required this.item,
    required this.plannedToday,
    required this.onToggle,
    required this.onPlan,
    required this.onDelete,
    super.key,
  });

  final ProjectItem item;
  final bool plannedToday;
  final VoidCallback onToggle;
  final VoidCallback onPlan;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Dismissible(
      key: ValueKey('step-${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: colors.surfaceSunken,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Icon(Symbols.delete, color: colors.attention),
      ),
      onUpdate: (d) {
        if (d.reached && !d.previousReached) {
          unawaited(HapticFeedback.selectionClick());
        }
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.rowMinHeight),
        padding: const EdgeInsets.only(left: AppSpacing.xs),
        child: Row(
          children: [
            CircleCheck(
              value: item.done,
              label: item.title,
              onChanged: (_) => onToggle(),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: AnimatedDefaultTextStyle(
                  duration: AppMotion.of(context, AppDurations.normal),
                  style: context.text.bodyLarge!.copyWith(
                    color: item.done ? colors.muted : colors.text,
                    decoration: item.done ? TextDecoration.lineThrough : null,
                    decorationColor: colors.muted,
                  ),
                  child: Text(item.title),
                ),
              ),
            ),
            if (plannedToday)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'Today',
                  style: context.text.labelMedium!.copyWith(
                    color: colors.accentText,
                  ),
                ),
              )
            else if (!item.done)
              IconButton(
                onPressed: onPlan,
                tooltip: 'Plan for today',
                icon: Icon(Symbols.wb_sunny, color: colors.muted),
              ),
          ],
        ),
      ),
    );
  }
}

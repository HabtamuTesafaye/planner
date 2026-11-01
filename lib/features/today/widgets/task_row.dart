import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/circle_check.dart';
import '../../../data/models/task.dart';

/// One task. Swipe right to complete (or reopen), left to delete. A light
/// haptic marks the moment a swipe will count.
class TaskRow extends StatelessWidget {
  const TaskRow({
    required this.task,
    required this.spaceName,
    required this.onToggle,
    required this.onDelete,
    super.key,
  });

  final Task task;

  /// Shown as a small tag when the user has more than one space.
  final String? spaceName;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Dismissible(
      key: ValueKey('task-${task.id}'),
      background: _SwipeBackground(
        color: colors.successSoft,
        iconColor: colors.success,
        icon: task.done ? Symbols.undo : Symbols.check,
        label: task.done ? 'Not done' : 'Done',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _SwipeBackground(
        color: colors.surfaceSunken,
        iconColor: colors.attention,
        icon: Symbols.delete,
        label: 'Delete',
        alignment: Alignment.centerRight,
      ),
      onUpdate: (details) {
        if (details.reached && !details.previousReached) {
          unawaited(HapticFeedback.selectionClick());
        }
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onToggle();
          return false; // the row stays; only its state changes
        }
        return true;
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.rowMinHeight),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.divider)),
        ),
        child: Row(
          children: [
            CircleCheck(
              value: task.done,
              label: task.title,
              onChanged: (_) => onToggle(),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _Title(task: task, spaceName: spaceName),
            ),
          ],
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.task, required this.spaceName});

  final Task task;
  final String? spaceName;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = context.text.bodyLarge!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedDefaultTextStyle(
            duration: AppMotion.of(context, AppDurations.normal),
            curve: AppMotion.standard,
            style: base.copyWith(
              color: task.done ? colors.muted : colors.text,
              decoration: task.done ? TextDecoration.lineThrough : null,
              decorationColor: colors.muted,
            ),
            child: Text(task.title),
          ),
          if (spaceName != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                if (task.projectItemId != null) ...[
                  Icon(
                    Symbols.folder_open,
                    size: AppSizes.tagIcon,
                    color: colors.muted,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    spaceName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelSmall,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.iconColor,
    required this.icon,
    required this.label,
    required this.alignment,
  });

  final Color color;
  final Color iconColor;
  final IconData icon;
  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: context.text.labelMedium!.copyWith(color: iconColor),
          ),
        ],
      ),
    );
  }
}

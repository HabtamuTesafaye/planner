import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

/// One short line, an optional detail, and at most one action.
/// Left-aligned like a note in a planner, not a centered illustration.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.message,
    this.detail,
    this.icon,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String message;
  final String? detail;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            ExcludeSemantics(
              child: Icon(icon, size: AppSizes.icon, color: colors.muted),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(message, style: context.text.titleMedium),
          if (detail != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              detail!,
              style: context.text.bodyMedium!.copyWith(color: colors.muted),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

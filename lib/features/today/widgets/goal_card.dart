import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/card_material.dart';

/// "Goal of the week" for the current space. Tap to edit.
class GoalCard extends StatelessWidget {
  const GoalCard({
    required this.goal,
    required this.spaceName,
    required this.onTap,
    super.key,
  });

  final String? goal;
  final String spaceName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final hasGoal = goal != null && goal!.isNotEmpty;
    return Semantics(
      button: true,
      label: hasGoal
          ? 'Goal of the week in $spaceName: $goal. Double tap to edit.'
          : 'Set a goal of the week for $spaceName.',
      excludeSemantics: true,
      child: CardMaterial(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Goal of the week · $spaceName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelMedium!.copyWith(color: colors.muted),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        hasGoal ? goal! : 'What would make this week a win?',
                        style: hasGoal
                            ? text.titleMedium
                            : text.bodyLarge!.copyWith(color: colors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  hasGoal ? Symbols.edit : Symbols.add,
                  size: AppSizes.iconSmall,
                  color: colors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

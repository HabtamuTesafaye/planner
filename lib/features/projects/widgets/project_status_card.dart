import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';

/// Says what to do next with a project, in plain words, with one button:
/// * every step done, project still active: "Mark project done";
/// * project done: "Reopen".
/// Shows nothing otherwise.
class ProjectStatusCard extends StatelessWidget {
  const ProjectStatusCard({
    required this.isDone,
    required this.allStepsDone,
    required this.onMarkDone,
    required this.onReopen,
    super.key,
  });

  final bool isDone;
  final bool allStepsDone;
  final VoidCallback onMarkDone;
  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context) {
    if (!isDone && !allStepsDone) return const SizedBox.shrink();
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.successSoft,
        borderRadius: AppRadius.cardAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Symbols.task_alt, color: c.success),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  isDone
                      ? 'This project is done.'
                      : 'Every step is done. Close the project?',
                  style: context.text.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (isDone)
            OutlinedButton(onPressed: onReopen, child: const Text('Reopen'))
          else
            FilledButton(
              onPressed: onMarkDone,
              child: const Text('Mark project done'),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/card_material.dart';
import '../../../core/widgets/thin_progress_bar.dart';
import '../../../data/models/project.dart';
import '../templates.dart';

/// A project in the list: icon, name, steps done and a thin progress bar.
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    required this.project,
    required this.steps,
    required this.onTap,
    super.key,
  });

  final Project project;
  final List<ProjectItem> steps;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final done = steps.where((s) => s.done).length;
    final template = ProjectTemplate.fromKey(project.template);
    final summary = steps.isEmpty
        ? 'No steps yet'
        : '$done of ${steps.length} steps';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: CardMaterial(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon on a soft tinted tile.
                    Container(
                      width: AppSizes.iconTile,
                      height: AppSizes.iconTile,
                      decoration: BoxDecoration(
                        color: project.isDone
                            ? colors.successSoft
                            : colors.accentSoft,
                        borderRadius: AppRadius.controlAll,
                      ),
                      child: Icon(
                        project.isDone ? Symbols.task_alt : template.icon,
                        size: AppSizes.iconSmall,
                        color: project.isDone
                            ? colors.success
                            : colors.accentText,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        project.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium,
                      ),
                    ),
                    Icon(
                      Symbols.chevron_right,
                      size: AppSizes.iconSmall,
                      color: colors.muted,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ThinProgressBar(
                  value: projectProgress(steps),
                  semanticLabel: '${project.name}: $summary',
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  project.isDone ? 'Done · $summary' : summary,
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

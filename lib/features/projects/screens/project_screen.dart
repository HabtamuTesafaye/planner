import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/grouped_list.dart';
import '../../../core/widgets/page_wash.dart';
import '../../../core/widgets/round_icon_button.dart';
import '../../../core/widgets/sheet_frame.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/thin_progress_bar.dart';
import '../../../data/models/project.dart';
import '../../../data/models/task.dart';
import '../../../router_redirect.dart';
import '../../today/providers/today_controller.dart';
import '../providers/projects_providers.dart';
import '../templates.dart';
import '../widgets/add_step_field.dart';
import '../widgets/project_menu.dart';
import '../widgets/project_status_card.dart';
import '../widgets/step_row.dart';
import '../widgets/step_sheet.dart';

/// One project: progress, checklist, and "plan for today" on each step.
class ProjectScreen extends ConsumerWidget {
  const ProjectScreen({required this.projectId, super.key});

  final String projectId;

  void _message(BuildContext context, String text, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), action: action));
  }

  Future<void> _plan(
    BuildContext context,
    WidgetRef ref,
    ProjectItem item,
  ) async {
    final error = await ref
        .read(todayControllerProvider.notifier)
        .add(title: item.title, spaceId: item.spaceId, projectItemId: item.id);
    if (context.mounted) {
      _message(context, error?.message ?? 'Planned for today');
    }
  }

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    Project project,
    ProjectStatus status,
  ) async {
    unawaited(HapticFeedback.lightImpact());
    final e = await ref
        .read(projectsControllerProvider.notifier)
        .setStatus(project, status);
    if (!context.mounted) return;
    if (e != null) return _message(context, e.message);
    if (status == ProjectStatus.done) {
      _message(context, '${project.name} is done. Nice work.');
      // Back to the list, where it now shows as done.
      _back(context);
    } else {
      _message(context, 'Back in progress');
    }
  }

  /// Back to the previous page, or to the projects list when there is none.
  static void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.projects);
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ProjectItem item,
  ) async {
    final controller = ref.read(projectsControllerProvider.notifier);
    final error = await controller.deleteStep(item);
    if (!context.mounted) return;
    if (error != null) return _message(context, error.message);
    _message(
      context,
      'Step deleted',
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => controller.restoreStep(item),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    final project = projects.value?.where((p) => p.id == projectId).firstOrNull;
    final steps = ref.watch(projectStepsProvider(projectId));
    final planned = {
      for (final t in ref.watch(todayTasksProvider).value ?? const <Task>[])
        if (t.projectItemId != null) t.projectItemId!,
    };
    final controller = ref.read(projectsControllerProvider.notifier);

    return Scaffold(
      body: PageWash(
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.maxContentWidth,
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                children: [
                  Row(
                    children: [
                      RoundIconButton(
                        onPressed: () => _back(context),
                        tooltip: 'Back to projects',
                        icon: Symbols.arrow_back,
                      ),
                      const Spacer(),
                      if (project != null) ProjectMenu(project: project),
                    ],
                  ),
                  if (project == null)
                    projects.isLoading
                        ? const SkeletonList()
                        : const EmptyState(
                            message: 'This project is gone.',
                            detail: 'Someone may have deleted it.',
                          )
                  else ...[
                    const SizedBox(height: AppSpacing.md),
                    FadeSlideIn(
                      child: Semantics(
                        header: true,
                        child: Text(
                          project.name,
                          style: context.text.headlineMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      ProjectTemplate.fromKey(project.template).label,
                      style: context.text.bodyMedium!.copyWith(
                        color: context.colors.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ..._checklist(
                      context,
                      ref,
                      project,
                      steps,
                      planned,
                      controller,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _checklist(
    BuildContext context,
    WidgetRef ref,
    Project project,
    AsyncValue<List<ProjectItem>> steps,
    Set<String> planned,
    ProjectsController controller,
  ) {
    final list = steps.value;
    if (list == null) return const [SkeletonList()];
    final done = list.where((s) => s.done).length;
    final summary = list.isEmpty
        ? 'No steps yet'
        : '$done of ${list.length} steps';
    return [
      ThinProgressBar(
        value: projectProgress(list),
        semanticLabel: '${project.name}: $summary',
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(summary, style: context.text.bodySmall),
      const SizedBox(height: AppSpacing.lg),
      ProjectStatusCard(
        isDone: project.isDone,
        allStepsDone: list.isNotEmpty && done == list.length,
        onMarkDone: () => _setStatus(context, ref, project, ProjectStatus.done),
        onReopen: () => _setStatus(context, ref, project, ProjectStatus.active),
      ),
      if (project.isDone || (list.isNotEmpty && done == list.length))
        const SizedBox(height: AppSpacing.lg),
      if (!project.isDone && done < list.length) ...[
        Row(
          children: [
            Icon(
              Symbols.wb_sunny,
              size: AppSizes.tagIcon,
              color: context.colors.accentText,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Tap a step to add a note. Tap the sun to plan it for today.',
                style: context.text.bodySmall!.copyWith(
                  color: context.colors.muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      for (final (i, item) in list.indexed)
        FadeSlideIn(
          key: ValueKey('in-${item.id}'),
          index: i,
          child: GroupTile(
            isFirst: i == 0,
            isLast: i == list.length - 1,
            child: StepRow(
              item: item,
              plannedToday: planned.contains(item.id),
              onToggle: () async {
                final e = await controller.toggleStep(item);
                if (e != null && context.mounted) _message(context, e.message);
              },
              onPlan: () => _plan(context, ref, item),
              onDelete: () => _delete(context, ref, item),
              onOpen: () => showAppSheet<bool>(context, StepSheet(item: item)),
            ),
          ),
        ),
      AddStepField(
        onAdd: (title) async {
          final next = list.isEmpty ? 0 : list.last.position + 1;
          final e = await controller.addStep(project, title, next);
          if (e != null && context.mounted) _message(context, e.message);
          return e == null;
        },
      ),
    ];
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/sheet_frame.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/app_exception.dart';
import '../../../data/models/project.dart';
import '../../space/providers/space_providers.dart';
import '../../space/widgets/space_switcher.dart';
import '../providers/projects_providers.dart';
import '../widgets/new_project_sheet.dart';
import '../widgets/project_card.dart';

/// Projects of the current space: active first, done below.
class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  static String path(String id) => '/projects/$id';

  Future<void> _new(BuildContext context, WidgetRef ref) async {
    final space = ref.read(currentSpaceProvider);
    if (space == null) return;
    final id = await showAppSheet<String>(
      context,
      NewProjectSheet(spaceId: space.id),
    );
    if (id != null && context.mounted) await context.push(path(id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    final items =
        ref.watch(projectItemsProvider).value ?? const <ProjectItem>[];

    List<ProjectItem> stepsOf(Project p) =>
        items.where((i) => i.projectId == p.id).toList();

    Widget card(Project p, int i) => FadeSlideIn(
      key: ValueKey('project-${p.id}'),
      index: i,
      child: ProjectCard(
        project: p,
        steps: stepsOf(p),
        onTap: () => context.push(path(p.id)),
      ),
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _new(context, ref),
        icon: const Icon(Symbols.add),
        label: const Text('New project'),
      ),
      body: PageBody(
        title: 'Projects',
        top: const SpaceSwitcher(),
        bottomPadding: AppSizes.fabClearance,
        onRefresh: () async => ref
          ..invalidate(projectsProvider)
          ..invalidate(projectItemsProvider),
        children: [
          const SizedBox(height: AppSpacing.lg),
          ...switch (projects) {
            AsyncValue(hasValue: true, :final value?) when value.isEmpty => [
              EmptyState(
                icon: Symbols.folder_open,
                message: 'No projects yet.',
                detail: 'Start one from a template and keep its steps here.',
                actionLabel: 'New project',
                onAction: () => _new(context, ref),
              ),
            ],
            AsyncValue(hasValue: true, :final value?) => [
              for (final (i, p) in value.where((p) => !p.isDone).indexed)
                card(p, i),
              if (value.any((p) => p.isDone)) ...[
                const SectionHeader(title: 'Done'),
                for (final (i, p) in value.where((p) => p.isDone).indexed)
                  card(p, i),
              ],
            ],
            AsyncValue(:final error?) => [
              EmptyState(
                message: AppException.from(error).message,
                actionLabel: 'Try again',
                onAction: () => ref.invalidate(projectsProvider),
              ),
            ],
            _ => [const SkeletonList()],
          },
        ],
      ),
    );
  }
}

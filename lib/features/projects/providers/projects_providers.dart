import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/ids.dart';
import '../../../data/app_exception.dart';
import '../../../data/models/project.dart';
import '../../../data/repositories/projects_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../space/providers/space_providers.dart';
import '../templates.dart';

/// Live projects of the current space.
final projectsProvider = StreamProvider<List<Project>>((ref) {
  final space = ref.watch(currentSpaceProvider);
  if (space == null) return Stream.value(const []);
  return ref.watch(projectsRepositoryProvider).watchProjects(space.id);
});

/// Live steps of every project in the current space.
final projectItemsProvider = StreamProvider<List<ProjectItem>>((ref) {
  final space = ref.watch(currentSpaceProvider);
  if (space == null) return Stream.value(const []);
  return ref.watch(projectsRepositoryProvider).watchItems(space.id);
});

/// Pending step changes (instant feedback), like Today's overlay.
@immutable
class ItemOverlay {
  const ItemOverlay({this.done = const {}, this.deleted = const {}});

  final Map<String, bool> done;
  final Set<String> deleted;

  ItemOverlay prunedBy(List<ProjectItem> server) {
    final byId = {for (final i in server) i.id: i};
    return ItemOverlay(
      done: {
        for (final e in done.entries)
          if (byId.containsKey(e.key) && byId[e.key]!.done != e.value)
            e.key: e.value,
      },
      deleted: {
        for (final id in deleted)
          if (byId.containsKey(id)) id,
      },
    );
  }
}

/// Steps of one project with pending changes applied, in order.
List<ProjectItem> itemsOf(
  String projectId,
  List<ProjectItem> server,
  ItemOverlay overlay,
) {
  return [
    for (final i in server)
      if (i.projectId == projectId && !overlay.deleted.contains(i.id))
        overlay.done.containsKey(i.id)
            ? i.copyWith(done: overlay.done[i.id])
            : i,
  ]..sort((a, b) => a.position.compareTo(b.position));
}

final projectStepsProvider =
    Provider.family<AsyncValue<List<ProjectItem>>, String>((ref, projectId) {
      final overlay = ref.watch(projectsControllerProvider);
      return ref
          .watch(projectItemsProvider)
          .whenData((all) => itemsOf(projectId, all, overlay));
    });

/// Actions on projects and steps. Each returns null on success, or the
/// error to show (already rolled back).
class ProjectsController extends Notifier<ItemOverlay> {
  @override
  ItemOverlay build() {
    ref.listen(projectItemsProvider, (_, next) {
      final list = next.value;
      if (list != null) state = state.prunedBy(list);
    });
    return const ItemOverlay();
  }

  ProjectsRepository get _repo => ref.read(projectsRepositoryProvider);
  String? get _userId => ref.read(currentUserIdProvider).value;

  /// Creates a project from [template]; returns its id.
  Future<(String?, AppException?)> create({
    required String spaceId,
    required String name,
    required ProjectTemplate template,
  }) async {
    final userId = _userId;
    if (userId == null) {
      return (null, const AppException(AppErrorKind.signedOut));
    }
    final project = Project(
      id: newUuid(),
      spaceId: spaceId,
      name: name.trim(),
      template: template.key,
      status: ProjectStatus.active,
      createdBy: userId,
      createdAt: DateTime.now(),
    );
    final steps = [
      for (final (i, title) in template.steps.indexed)
        ProjectItem(
          id: newUuid(),
          projectId: project.id,
          spaceId: spaceId,
          title: title,
          done: false,
          position: i,
          createdBy: userId,
        ),
    ];
    try {
      await _repo.createProject(project, steps);
      return (project.id, null);
    } on AppException catch (e) {
      return (null, e);
    }
  }

  Future<AppException?> addStep(
    Project project,
    String title,
    int position,
  ) async {
    final userId = _userId;
    if (userId == null) return const AppException(AppErrorKind.signedOut);
    return _try(
      () => _repo.addItem(
        ProjectItem(
          id: newUuid(),
          projectId: project.id,
          spaceId: project.spaceId,
          title: title.trim(),
          done: false,
          position: position,
          createdBy: userId,
        ),
      ),
    );
  }

  Future<AppException?> toggleStep(ProjectItem item) async {
    final next = !item.done;
    state = ItemOverlay(
      done: {...state.done, item.id: next},
      deleted: state.deleted,
    );
    final error = await _try(() => _repo.setItemDone(item.id, done: next));
    if (error != null) {
      state = ItemOverlay(
        done: {...state.done}..remove(item.id),
        deleted: state.deleted,
      );
    }
    return error;
  }

  Future<AppException?> deleteStep(ProjectItem item) async {
    state = ItemOverlay(done: state.done, deleted: {...state.deleted, item.id});
    AppException? error;
    try {
      if (!await _repo.deleteItem(item.id)) {
        error = const AppException(AppErrorKind.notAllowed);
      }
    } on AppException catch (e) {
      error = e;
    }
    if (error != null) {
      state = ItemOverlay(
        done: state.done,
        deleted: {...state.deleted}..remove(item.id),
      );
    }
    return error;
  }

  Future<AppException?> editStep(
    ProjectItem item, {
    required String title,
    required String? note,
  }) => _try(() => _repo.updateItem(item.id, title: title, note: note));

  Future<AppException?> restoreStep(ProjectItem item) =>
      _try(() => _repo.restoreItem(item));

  Future<AppException?> rename(Project p, String name) =>
      _try(() => _repo.rename(p.id, name));

  Future<AppException?> setStatus(Project p, ProjectStatus status) =>
      _try(() => _repo.setStatus(p.id, status));

  Future<AppException?> delete(Project p) async {
    try {
      final ok = await _repo.deleteProject(p.id);
      return ok ? null : const AppException(AppErrorKind.notAllowed);
    } on AppException catch (e) {
      return e;
    }
  }

  Future<AppException?> _try(Future<void> Function() run) async {
    try {
      await run();
      return null;
    } on AppException catch (e) {
      return e;
    }
  }
}

final projectsControllerProvider =
    NotifierProvider<ProjectsController, ItemOverlay>(ProjectsController.new);

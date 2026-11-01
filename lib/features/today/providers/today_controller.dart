import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/ids.dart';
import '../../../data/app_exception.dart';
import '../../../data/models/task.dart';
import '../../../data/repositories/tasks_repository.dart';
import '../../auth/providers/auth_providers.dart';
import 'today_providers.dart';

/// Changes the user made that the server has not confirmed yet. Shown on
/// top of the live list so the screen reacts instantly; each entry is
/// dropped once the live list agrees, or rolled back if the save fails.
@immutable
class TaskOverlay {
  const TaskOverlay({
    this.added = const {},
    this.done = const {},
    this.deleted = const {},
  });

  final Map<String, Task> added;
  final Map<String, bool> done;
  final Set<String> deleted;

  TaskOverlay copyWith({
    Map<String, Task>? added,
    Map<String, bool>? done,
    Set<String>? deleted,
  }) => TaskOverlay(
    added: added ?? this.added,
    done: done ?? this.done,
    deleted: deleted ?? this.deleted,
  );

  /// Drops entries the server list already reflects.
  TaskOverlay prunedBy(List<Task> server) {
    final byId = {for (final t in server) t.id: t};
    return TaskOverlay(
      added: {
        for (final e in added.entries)
          if (!byId.containsKey(e.key)) e.key: e.value,
      },
      done: {
        for (final e in done.entries)
          if (byId[e.key]?.done != e.value && byId.containsKey(e.key))
            e.key: e.value,
      },
      deleted: {
        for (final id in deleted)
          if (byId.containsKey(id)) id,
      },
    );
  }
}

/// The tasks to show for [day]: server list plus pending changes, oldest
/// first.
List<Task> mergeTasks(List<Task> server, TaskOverlay overlay, DateTime day) {
  final byId = {for (final t in server) t.id: t, ...overlay.added};
  final result = [
    for (final t in byId.values)
      if (!overlay.deleted.contains(t.id) &&
          t.day.year == day.year &&
          t.day.month == day.month &&
          t.day.day == day.day)
        overlay.done.containsKey(t.id)
            ? t.copyWith(done: overlay.done[t.id])
            : t,
  ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return result;
}

/// Today's tasks (live, with pending changes applied).
final todayTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final overlay = ref.watch(todayControllerProvider);
  final day = ref.watch(todayProvider);
  return ref
      .watch(myTasksProvider)
      .whenData((list) => mergeTasks(list, overlay, day));
});

/// Actions on today's tasks. Each returns null on success, or the error to
/// show (already rolled back).
class TodayController extends Notifier<TaskOverlay> {
  @override
  TaskOverlay build() {
    ref.listen(myTasksProvider, (_, next) {
      final list = next.value;
      if (list != null) state = state.prunedBy(list);
    });
    return const TaskOverlay();
  }

  TasksRepository get _repo => ref.read(tasksRepositoryProvider);

  /// Today's tasks as shown, computed from the sources directly (reading
  /// todayTasksProvider here would be a loop: it is built from this state).
  List<Task> get _today => mergeTasks(
    ref.read(myTasksProvider).value ?? const [],
    state,
    ref.read(todayProvider),
  );

  /// Adds a task for today in [spaceId]. Blocks a 4th in the app; the
  /// database blocks it too.
  Future<AppException?> add({
    required String title,
    required String spaceId,
    String? projectItemId,
  }) async {
    final userId = ref.read(currentUserIdProvider).value;
    if (userId == null) return const AppException(AppErrorKind.signedOut);
    if (_today.length >= Task.dailyLimit) {
      return const AppException(AppErrorKind.taskLimit);
    }
    final task = Task(
      id: newUuid(),
      spaceId: spaceId,
      userId: userId,
      title: title.trim(),
      day: ref.read(todayProvider),
      done: false,
      createdAt: DateTime.now(),
      projectItemId: projectItemId,
    );
    state = state.copyWith(added: {...state.added, task.id: task});
    try {
      await _repo.add(task);
      return null;
    } on AppException catch (e) {
      state = state.copyWith(added: {...state.added}..remove(task.id));
      return e;
    }
  }

  Future<AppException?> toggle(Task task) async {
    final next = !task.done;
    state = state.copyWith(done: {...state.done, task.id: next});
    try {
      await _repo.setDone(task.id, done: next);
      return null;
    } on AppException catch (e) {
      state = state.copyWith(done: {...state.done}..remove(task.id));
      return e;
    }
  }

  Future<AppException?> delete(Task task) async {
    state = state.copyWith(deleted: {...state.deleted, task.id});
    try {
      await _repo.delete(task.id);
      return null;
    } on AppException catch (e) {
      state = state.copyWith(deleted: {...state.deleted}..remove(task.id));
      return e;
    }
  }

  /// Undo for delete.
  Future<AppException?> restore(Task task) async {
    state = state.copyWith(
      deleted: {...state.deleted}..remove(task.id),
      added: {...state.added, task.id: task},
    );
    try {
      await _repo.restore(task);
      return null;
    } on AppException catch (e) {
      state = state.copyWith(added: {...state.added}..remove(task.id));
      return e;
    }
  }
}

final todayControllerProvider = NotifierProvider<TodayController, TaskOverlay>(
  TodayController.new,
);

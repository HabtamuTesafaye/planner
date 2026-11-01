import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/dates.dart';
import '../app_exception.dart';
import '../models/task.dart';
import '../supabase_client.dart';

/// Tasks. The database enforces the 3-a-day limit across all spaces and
/// returns `task_limit_reached`, mapped to the same friendly message the
/// app shows.
class TasksRepository {
  const TasksRepository(this._client);

  final SupabaseClient _client;

  /// Live list of my recent tasks (all spaces), newest days first. The
  /// realtime stream only sends rows RLS lets me read.
  Stream<List<Task>> watchMyTasks(String userId) => _client
      .from('tasks')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('day')
      .limit(60)
      .map((rows) => rows.map(Task.fromJson).toList(growable: false))
      .handleError((Object e, StackTrace s) => throw AppException.from(e, s));

  /// Live recent tasks of everyone in a space (for the progress cards).
  Stream<List<Task>> watchSpaceTasks(String spaceId) => _client
      .from('tasks')
      .stream(primaryKey: ['id'])
      .eq('team_id', spaceId)
      .order('day')
      .limit(200)
      .map((rows) => rows.map(Task.fromJson).toList(growable: false))
      .handleError((Object e, StackTrace s) => throw AppException.from(e, s));

  /// Tasks of every member of a space for one day (for the Space tab).
  Future<List<Task>> fetchSpaceTasks(
    String spaceId,
    DateTime from,
    DateTime to,
  ) => _guard(() async {
    final rows = await _client
        .from('tasks')
        .select()
        .eq('team_id', spaceId)
        .gte('day', Dates.toDb(from))
        .lte('day', Dates.toDb(to));
    return rows.map(Task.fromJson).toList(growable: false);
  });

  Future<void> add(Task task) =>
      _guard(() => _client.from('tasks').insert(task.toInsertJson()));

  Future<void> setDone(String id, {required bool done}) =>
      _guard(() => _client.from('tasks').update({'done': done}).eq('id', id));

  Future<void> rename(String id, String title) => _guard(
    () => _client.from('tasks').update({'title': title.trim()}).eq('id', id),
  );

  Future<void> delete(String id) =>
      _guard(() => _client.from('tasks').delete().eq('id', id));

  /// Undo for delete: puts the same task back (same id).
  Future<void> restore(Task task) => add(task);

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e, s) {
      throw AppException.from(e, s);
    }
  }
}

final tasksRepositoryProvider = Provider<TasksRepository>(
  (ref) => TasksRepository(ref.watch(supabaseClientProvider)),
);

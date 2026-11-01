import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_exception.dart';
import '../models/project.dart';
import '../supabase_client.dart';

/// Projects and their steps, shared inside a space.
class ProjectsRepository {
  const ProjectsRepository(this._client);

  final SupabaseClient _client;

  Stream<List<Project>> watchProjects(String spaceId) => _client
      .from('projects')
      .stream(primaryKey: ['id'])
      .eq('team_id', spaceId)
      .order('created_at')
      .map((rows) => rows.map(Project.fromJson).toList(growable: false))
      .handleError((Object e, StackTrace s) => throw AppException.from(e, s));

  /// Every step in the space (to show progress on each project card).
  Stream<List<ProjectItem>> watchItems(String spaceId) => _client
      .from('project_items')
      .stream(primaryKey: ['id'])
      .eq('team_id', spaceId)
      .order('position', ascending: true)
      .map((rows) => rows.map(ProjectItem.fromJson).toList(growable: false))
      .handleError((Object e, StackTrace s) => throw AppException.from(e, s));

  /// Creates the project and its first steps (from a template).
  Future<void> createProject(Project project, List<ProjectItem> steps) =>
      _guard(() async {
        await _client.from('projects').insert(project.toInsertJson());
        if (steps.isNotEmpty) {
          await _client.from('project_items').insert([
            for (final s in steps) s.toInsertJson(),
          ]);
        }
      });

  Future<void> rename(String projectId, String name) => _guard(
    () => _client
        .from('projects')
        .update({'name': name.trim()})
        .eq('id', projectId),
  );

  Future<void> setStatus(String projectId, ProjectStatus status) => _guard(
    () => _client
        .from('projects')
        .update({'status': status.name})
        .eq('id', projectId),
  );

  /// Returns false when the database refused (not the creator or owner).
  Future<bool> deleteProject(String projectId) => _guard(() async {
    final rows = await _client
        .from('projects')
        .delete()
        .eq('id', projectId)
        .select('id');
    return rows.isNotEmpty;
  });

  Future<void> addItem(ProjectItem item) =>
      _guard(() => _client.from('project_items').insert(item.toInsertJson()));

  Future<void> setItemDone(String itemId, {required bool done}) => _guard(
    () => _client.from('project_items').update({'done': done}).eq('id', itemId),
  );

  /// Returns false when the database refused (not the creator or owner).
  Future<bool> deleteItem(String itemId) => _guard(() async {
    final rows = await _client
        .from('project_items')
        .delete()
        .eq('id', itemId)
        .select('id');
    return rows.isNotEmpty;
  });

  /// Undo for delete (same id and position).
  Future<void> restoreItem(ProjectItem item) => addItem(item);

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e, s) {
      throw AppException.from(e, s);
    }
  }
}

final projectsRepositoryProvider = Provider<ProjectsRepository>(
  (ref) => ProjectsRepository(ref.watch(supabaseClientProvider)),
);

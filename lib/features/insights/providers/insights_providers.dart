import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/task.dart';
import '../../../data/repositories/tasks_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../today/providers/today_providers.dart';
import '../insights_logic.dart';

/// How many weeks of history the dashboard loads (the heatmap shows as many
/// as fit the screen).
const int insightWeeks = 26;

/// My tasks for the last [insightWeeks] weeks: loaded once, then merged with
/// the live list so today's changes show up immediately.
final activityTasksProvider = FutureProvider<List<Task>>((ref) async {
  final userId = ref.watch(currentUserIdProvider).value;
  if (userId == null) return const [];
  final today = ref.watch(todayProvider);
  final from = heatmapWeeks(today, insightWeeks).first;
  final history = await ref
      .watch(tasksRepositoryProvider)
      .fetchMyTasksSince(userId, from);
  final live = ref.watch(myTasksProvider).value ?? const <Task>[];
  final byId = {
    for (final t in history) t.id: t,
    for (final t in live) t.id: t,
  };
  return byId.values.toList(growable: false);
});

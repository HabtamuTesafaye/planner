import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/dates.dart';
import '../../../data/models/task.dart';
import '../../../data/models/weekly_goal.dart';
import '../../../data/repositories/goals_repository.dart';
import '../../../data/repositories/tasks_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../space/providers/space_providers.dart';

/// Current time. Overridden in tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Today's calendar date. Re-read when the app resumes (see TodayScreen).
final todayProvider = Provider<DateTime>(
  (ref) => Dates.dateOnly(ref.watch(clockProvider)()),
);

/// Live list of my recent tasks across all spaces.
final myTasksProvider = StreamProvider<List<Task>>((ref) {
  final userId = ref.watch(currentUserIdProvider).value;
  if (userId == null) return Stream.value(const []);
  return ref.watch(tasksRepositoryProvider).watchMyTasks(userId);
});

/// My goal of the week for the current space.
final weeklyGoalProvider = FutureProvider<WeeklyGoal?>((ref) async {
  final userId = ref.watch(currentUserIdProvider).value;
  final space = ref.watch(currentSpaceProvider);
  if (userId == null || space == null) return null;
  return ref
      .watch(goalsRepositoryProvider)
      .fetchGoal(
        spaceId: space.id,
        userId: userId,
        weekStart: Dates.weekStart(ref.watch(todayProvider)),
      );
});

/// Space id → name, for the small tag on each task.
final spaceNamesProvider = Provider<Map<String, String>>((ref) {
  final spaces = ref.watch(mySpacesProvider).value ?? const [];
  return {for (final s in spaces) s.id: s.name};
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/dates.dart';
import '../../../data/models/task.dart';
import '../../../data/models/weekly_goal.dart';
import '../../../data/repositories/goals_repository.dart';
import '../../../data/repositories/tasks_repository.dart';
import '../../outreach/providers/outreach_providers.dart';
import '../../review/providers/review_providers.dart';
import '../../today/providers/today_providers.dart';
import '../progress_logic.dart';
import 'space_providers.dart';

/// Live recent tasks of everyone in the current space.
final spaceTasksProvider = StreamProvider<List<Task>>((ref) {
  final space = ref.watch(currentSpaceProvider);
  if (space == null) return Stream.value(const []);
  return ref.watch(tasksRepositoryProvider).watchSpaceTasks(space.id);
});

/// Everyone's goal of the week in the current space.
final spaceGoalsProvider = FutureProvider<List<WeeklyGoal>>((ref) async {
  final space = ref.watch(currentSpaceProvider);
  if (space == null) return const [];
  return ref
      .watch(goalsRepositoryProvider)
      .fetchSpaceGoals(space.id, Dates.weekStart(ref.watch(todayProvider)));
});

/// One progress card per member. Tasks and contacts update live.
final spaceProgressProvider = Provider<AsyncValue<List<MemberProgress>>>((ref) {
  final members = ref.watch(spaceMembersProvider);
  final tasks = ref.watch(spaceTasksProvider);
  if (!members.hasValue || !tasks.hasValue) {
    final error = members.error ?? tasks.error;
    return error != null
        ? AsyncValue.error(error, StackTrace.current)
        : const AsyncValue.loading();
  }
  return AsyncValue.data(
    buildProgress(
      members: members.value!,
      spaceTasks: tasks.value!,
      contacts: ref.watch(contactsProvider).value ?? const [],
      goals: ref.watch(spaceGoalsProvider).value ?? const [],
      reviews: ref.watch(spaceReviewsProvider).value ?? const [],
      today: ref.watch(todayProvider),
    ),
  );
});

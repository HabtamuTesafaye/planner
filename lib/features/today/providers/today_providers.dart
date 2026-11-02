import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/dates.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/task.dart';
import '../../../data/models/weekly_goal.dart';
import '../../../data/repositories/goals_repository.dart';
import '../../../data/repositories/tasks_repository.dart';
import '../../../data/repositories/time_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../space/providers/space_providers.dart';

/// How far the phone's clock is from the server's (server minus phone).
/// Zero until the first sync; kept when offline.
class ServerClock extends Notifier<Duration> {
  /// Smaller differences are network noise, not a wrong clock.
  static const Duration tolerance = Duration(seconds: 30);

  @override
  Duration build() => Duration.zero;

  /// Reads the server time and stores the difference. Never throws: if the
  /// server can't be reached, the last known difference stays.
  Future<void> sync() async {
    try {
      final before = DateTime.now();
      final server = await ref.read(timeRepositoryProvider).serverNow();
      final after = DateTime.now();
      // The server answered somewhere between before and after.
      final phoneAtAnswer = before.add(after.difference(before) ~/ 2);
      final offset = server.difference(phoneAtAnswer);
      if ((offset - state).abs() > tolerance) state = offset;
    } on Object catch (e, s) {
      Log.error('Could not read the server time', e, s);
    }
  }
}

final serverClockProvider = NotifierProvider<ServerClock, Duration>(
  ServerClock.new,
);

/// Current time: the server's clock, in the phone's time zone. A phone set
/// to the wrong date or time still plans on the real today. Overridden in
/// tests.
final clockProvider = Provider<DateTime Function()>((ref) {
  final offset = ref.watch(serverClockProvider);
  return () => DateTime.now().add(offset);
});

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

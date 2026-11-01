import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:planner/core/widgets/circle_check.dart';
import 'package:planner/data/app_exception.dart';
import 'package:planner/data/models/profile.dart';
import 'package:planner/data/models/space.dart';
import 'package:planner/data/models/task.dart';
import 'package:planner/features/auth/providers/auth_providers.dart';
import 'package:planner/features/space/providers/space_providers.dart';
import 'package:planner/features/today/providers/today_providers.dart';
import 'package:planner/features/today/screens/today_screen.dart';

import '../../helpers.dart';

final _spaces = [
  Space(
    id: 's1',
    name: 'Personal',
    kind: SpaceKind.personal,
    joinCode: null,
    createdAt: DateTime(2026),
  ),
  Space(
    id: 's2',
    name: 'Elvaris',
    kind: SpaceKind.team,
    joinCode: 'ABCDEFGH',
    createdAt: DateTime(2026),
  ),
];

Task _task(String id, String space, {bool done = false, int order = 0}) => Task(
  id: id,
  spaceId: space,
  userId: 'u1',
  title: 'Task $id',
  day: DateTime(2026, 11, 2),
  done: done,
  createdAt: DateTime(2026, 11, 2, 8, order),
);

List<Override> _overrides(List<Task> tasks) => [
  currentUserIdProvider.overrideWith((ref) => Stream.value('u1')),
  currentProfileProvider.overrideWith(
    (ref) async => const Profile(id: 'u1', displayName: 'Abebe'),
  ),
  mySpacesProvider.overrideWith((ref) async => _spaces),
  myTasksProvider.overrideWith((ref) => Stream.value(tasks)),
  weeklyGoalProvider.overrideWith((ref) async => null),
  clockProvider.overrideWithValue(() => DateTime(2026, 11, 2, 9)),
];

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('three tasks fit a small phone at 1.5x ($brightness)', (
      tester,
    ) async {
      useSmallPhone(tester, brightness: brightness);
      await pumpScreen(
        tester,
        const TodayScreen(),
        overrides: _overrides([
          _task('a', 's1', done: true),
          _task('b', 's2', order: 1),
          _task('c', 's2', order: 2),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Monday'), findsOneWidget);
      expect(find.byType(CircleCheck), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('each task shows its space when you have several', (
    tester,
  ) async {
    useSmallPhone(tester);
    await pumpScreen(
      tester,
      const TodayScreen(),
      overrides: _overrides([_task('a', 's1'), _task('b', 's2', order: 1)]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Personal'), findsWidgets);
    expect(find.text('Elvaris'), findsOneWidget);
  });

  testWidgets('adding a 4th shows the kind limit message', (tester) async {
    useSmallPhone(tester);
    await pumpScreen(
      tester,
      const TodayScreen(),
      overrides: _overrides([
        _task('a', 's1'),
        _task('b', 's1', order: 1),
        _task('c', 's1', order: 2),
      ]),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    expect(
      find.text(const AppException(AppErrorKind.taskLimit).message),
      findsOneWidget,
    );
    expect(find.text('Add a task'), findsNothing); // no sheet opened
  });

  testWidgets('empty day: one line and one button', (tester) async {
    useSmallPhone(tester);
    await pumpScreen(tester, const TodayScreen(), overrides: _overrides([]));
    await tester.pumpAndSettle();
    expect(find.text('Nothing planned yet.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Add a task'), findsOneWidget);
  });

  testWidgets('goal card invites a goal when none is set', (tester) async {
    useSmallPhone(tester);
    await pumpScreen(tester, const TodayScreen(), overrides: _overrides([]));
    await tester.pumpAndSettle();
    expect(find.text('What would make this week a win?'), findsOneWidget);
  });
}

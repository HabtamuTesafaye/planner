import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner/data/models/profile.dart';
import 'package:planner/data/models/space.dart';
import 'package:planner/data/models/task.dart';
import 'package:planner/features/auth/providers/auth_providers.dart';
import 'package:planner/features/insights/insights_logic.dart';
import 'package:planner/features/insights/providers/insights_providers.dart';
import 'package:planner/features/insights/screens/insights_screen.dart';
import 'package:planner/features/insights/widgets/activity_heatmap.dart';
import 'package:planner/features/money/providers/money_providers.dart';
import 'package:planner/features/outreach/providers/outreach_providers.dart';
import 'package:planner/features/projects/providers/projects_providers.dart';
import 'package:planner/features/space/providers/space_providers.dart';
import 'package:planner/features/today/providers/today_providers.dart';

import '../../helpers.dart';

// Wed 4 Nov 2026 (week of Mon 2 Nov).
final _today = DateTime(2026, 11, 4);

Task t(DateTime day, {bool done = true, String id = ''}) => Task(
  id: '${day.toIso8601String()}-$done-$id',
  spaceId: 's1',
  userId: 'u1',
  title: 'x',
  day: day,
  done: done,
  createdAt: day,
);

void main() {
  final tasks = [
    t(DateTime(2026, 11, 2), id: 'a'),
    t(DateTime(2026, 11, 2), id: 'b'),
    t(DateTime(2026, 11, 3)),
    t(DateTime(2026, 11, 4), done: false),
    t(DateTime(2026, 10, 26), id: 'c'), // last week, Monday
    t(DateTime(2026, 10, 27), done: false),
  ];

  test('done per day counts only finished tasks', () {
    final byDay = doneByDay(tasks);
    expect(byDay[DateTime(2026, 11, 2)], 2);
    expect(byDay[DateTime(2026, 11, 4)], isNull);
  });

  test('heatmap weeks end with this week, Mondays only', () {
    final weeks = heatmapWeeks(_today, 3);
    expect(weeks, [
      DateTime(2026, 10, 19),
      DateTime(2026, 10, 26),
      DateTime(2026, 11, 2),
    ]);
    expect(weeks.every((d) => d.weekday == DateTime.monday), isTrue);
  });

  test('month labels never collide or hang off the edge', () {
    // 26 weeks ending in the week of Nov 2: starts in May (1 column of May).
    final weeks = heatmapWeeks(_today, 26);
    final cols = monthLabelColumns(weeks);
    for (var i = 1; i < cols.length; i++) {
      expect(cols[i] - cols[i - 1], greaterThanOrEqualTo(4));
    }
    expect(weeks.length - cols.last, greaterThanOrEqualTo(3));
    // A short partial first month gives way to the next month's label.
    final firstMonthColumns = weeks
        .takeWhile((w) => w.month == weeks.first.month)
        .length;
    if (firstMonthColumns < 4) expect(cols.first, firstMonthColumns);
  });

  test('weekly totals oldest first', () {
    final weekly = weeklyDone(doneByDay(tasks), _today, 2);
    expect(weekly.map((w) => w.done), [1, 3]);
  });

  test('summary: week, last week, active days, completion, best day', () {
    final s = summarize(tasks, _today);
    expect(s.doneThisWeek, 3);
    expect(s.doneLastWeek, 1);
    expect(s.activeDays30, 3);
    expect(s.completion30, closeTo(4 / 6, 0.001));
    expect(s.bestWeekday, DateTime.monday);
    expect(s.totalDone, 4);
  });

  test('empty history: no completion, no best day', () {
    final s = summarize(const [], _today);
    expect(s.completion30, isNull);
    expect(s.bestWeekday, isNull);
    expect(s.doneThisWeek, 0);
  });

  for (final brightness in Brightness.values) {
    testWidgets('insights fit a small phone at 1.5x ($brightness)', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      useSmallPhone(tester, brightness: brightness);
      await pumpScreen(
        tester,
        const InsightsScreen(),
        overrides: [
          currentUserIdProvider.overrideWith((ref) => Stream.value('u1')),
          currentProfileProvider.overrideWith(
            (ref) async => const Profile(id: 'u1', displayName: 'Abebe'),
          ),
          mySpacesProvider.overrideWith(
            (ref) async => [
              Space(
                id: 's1',
                name: 'Personal',
                kind: SpaceKind.personal,
                joinCode: null,
                createdAt: DateTime(2026),
              ),
            ],
          ),
          activityTasksProvider.overrideWith((ref) async => tasks),
          incomeEntriesProvider.overrideWith((ref) => Stream.value(const [])),
          contactsProvider.overrideWith((ref) => Stream.value(const [])),
          projectsProvider.overrideWith((ref) => Stream.value(const [])),
          projectItemsProvider.overrideWith((ref) => Stream.value(const [])),
          clockProvider.overrideWithValue(() => _today),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text('Done this week'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byType(ActivityHeatmap),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle(); // let the fade-in finish
      expect(
        find.bySemanticsLabel(RegExp('Activity over the last')),
        findsOneWidget,
      );
      // Scroll the whole page: no overflow anywhere.
      await tester.scrollUntilVisible(
        find.text('Active projects'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle(); // let the fade-in finish
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('tapping a heatmap day tells you what happened', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpScreen(
      tester,
      const InsightsScreen(),
      overrides: [
        currentUserIdProvider.overrideWith((ref) => Stream.value('u1')),
        currentProfileProvider.overrideWith((ref) async => null),
        mySpacesProvider.overrideWith((ref) async => const []),
        activityTasksProvider.overrideWith((ref) async => tasks),
        clockProvider.overrideWithValue(() => _today),
      ],
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.bySemanticsLabel(RegExp(r'Mon, Nov 2 · 2 tasks done')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mon, Nov 2 · 2 tasks done'), findsWidgets);
    semantics.dispose();
  });
}

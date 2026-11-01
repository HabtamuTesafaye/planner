import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner/data/models/income.dart';
import 'package:planner/data/models/profile.dart';
import 'package:planner/data/models/space.dart';
import 'package:planner/features/auth/providers/auth_providers.dart';
import 'package:planner/features/money/money_logic.dart';
import 'package:planner/features/money/providers/money_providers.dart';
import 'package:planner/features/money/screens/money_screen.dart';
import 'package:planner/features/space/providers/space_providers.dart';
import 'package:planner/features/today/providers/today_providers.dart';

import '../../helpers.dart';

IncomeEntry entry(String id, DateTime month, int cents, {int minute = 0}) =>
    IncomeEntry(
      id: id,
      spaceId: 's1',
      userId: 'u1',
      month: month,
      cents: cents,
      note: 'Note $id',
      createdAt: DateTime(2026, 11, 2, 9, minute),
    );

void main() {
  group('month boundaries', () {
    test('31st at 23:59 is still that month; the 1st is the next', () {
      expect(monthOf(DateTime(2026, 10, 31, 23, 59)), DateTime(2026, 10));
      expect(monthOf(DateTime(2026, 11)), DateTime(2026, 11));
    });

    test('December to January', () {
      expect(monthOf(DateTime(2026, 12, 31, 23, 59)), DateTime(2026, 12));
      expect(monthOf(DateTime(2027)), DateTime(2027));
    });

    test('totals only count their own month', () {
      final all = [
        entry('oct', DateTime(2026, 10), 100000),
        entry('nov1', DateTime(2026, 11), 1250050),
        entry('nov2', DateTime(2026, 11), 50),
        entry('dec', DateTime(2026, 12), 7),
      ];
      expect(monthTotal(all, DateTime(2026, 11, 30)), 1250100);
      expect(monthTotal(all, DateTime(2026, 10, 31)), 100000);
      expect(monthTotal(all, DateTime(2027)), 0);
    });

    test('previous months: newest first, current and later excluded', () {
      final all = [
        entry('a', DateTime(2026, 9), 100),
        entry('b', DateTime(2026, 10), 200),
        entry('c', DateTime(2026, 10), 300),
        entry('d', DateTime(2026, 11), 999),
      ];
      final history = previousMonths(all, DateTime(2026, 11, 15));
      expect(history.map((h) => h.month), [
        DateTime(2026, 10),
        DateTime(2026, 9),
      ]);
      expect(history.first.cents, 500);
    });
  });

  group('exact money', () {
    test('summing many small amounts has no floating point drift', () {
      final all = [
        for (var i = 0; i < 1000; i++) entry('$i', DateTime(2026, 11), 10),
      ];
      expect(monthTotal(all, DateTime(2026, 11)), 10000); // exactly 100.00
    });

    test('cents from the database and back', () {
      expect(centsFromJson(12500.5), 1250050);
      expect(centsFromJson('12500.50'), 1250050);
      expect(centsFromJson(0.1), 10);
      expect(centsToDb(1250050), '12500.50');
      expect(centsToDb(7), '0.07');
    });

    test('progress toward the target', () {
      expect(targetProgress(2500000, 5000000), 0.5);
      expect(targetProgress(100, null), 0);
      expect(targetProgress(6000000, 5000000), greaterThan(1));
    });
  });

  for (final brightness in Brightness.values) {
    testWidgets('money screen fits a small phone at 1.5x ($brightness)', (
      tester,
    ) async {
      useSmallPhone(tester, brightness: brightness);
      await pumpScreen(
        tester,
        const MoneyScreen(),
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
          incomeEntriesProvider.overrideWith(
            (ref) => Stream.value([
              entry('a', DateTime(2026, 11), 1250000),
              entry('b', DateTime(2026, 10), 300000),
            ]),
          ),
          monthlyTargetProvider.overrideWith(
            (ref) async => MonthlyTarget(
              spaceId: 's1',
              month: DateTime(2026, 11),
              cents: 5000000,
            ),
          ),
          clockProvider.overrideWithValue(() => DateTime(2026, 11, 15)),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text('12,500 ETB'), findsWidgets);
      expect(find.text('25% of 50,000 ETB'), findsOneWidget);
      // Below the fold on a small phone; the list builds it when scrolled to.
      await tester.scrollUntilVisible(
        find.text('Previous months'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Previous months'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:planner/core/utils/dates.dart';
import 'package:planner/core/utils/ids.dart';

void main() {
  group('week (starts Monday)', () {
    test('a mid-week day', () {
      // Wed 4 Nov 2026
      expect(Dates.weekStart(DateTime(2026, 11, 4, 15)), DateTime(2026, 11, 2));
      expect(Dates.weekEnd(DateTime(2026, 11, 4)), DateTime(2026, 11, 8));
    });

    test('Monday and Sunday belong to the same week', () {
      expect(Dates.weekStart(DateTime(2026, 11, 2)), DateTime(2026, 11, 2));
      expect(Dates.weekStart(DateTime(2026, 11, 8)), DateTime(2026, 11, 2));
    });

    test('across a month boundary', () {
      // Sun 1 Nov 2026 is in the week of Mon 26 Oct.
      expect(Dates.weekStart(DateTime(2026, 11)), DateTime(2026, 10, 26));
    });

    test('across a year boundary', () {
      // Fri 1 Jan 2027 is in the week of Mon 28 Dec 2026.
      expect(Dates.weekStart(DateTime(2027)), DateTime(2026, 12, 28));
      expect(Dates.weekEnd(DateTime(2026, 12, 29)), DateTime(2027, 1, 3));
    });
  });

  group('months', () {
    test('month start, 31st to 1st', () {
      expect(
        Dates.monthStart(DateTime(2026, 10, 31, 23, 59)),
        DateTime(2026, 10),
      );
      expect(Dates.monthStart(DateTime(2026, 11)), DateTime(2026, 11));
    });

    test('previous and next month across December/January', () {
      expect(Dates.previousMonth(DateTime(2027)), DateTime(2026, 12));
      expect(Dates.nextMonth(DateTime(2026, 12)), DateTime(2027));
    });
  });

  test('days between uses calendar dates (no DST surprises)', () {
    expect(Dates.daysBetween(DateTime(2026, 3, 28), DateTime(2026, 3, 30)), 2);
    expect(Dates.daysBetween(DateTime(2026, 11, 5), DateTime(2026, 11, 2)), -3);
    expect(
      Dates.daysBetween(DateTime(2026, 11, 2, 23), DateTime(2026, 11, 3, 1)),
      1,
    );
  });

  test('database date round trip', () {
    expect(Dates.toDb(DateTime(2026, 1, 5, 22, 30)), '2026-01-05');
    expect(Dates.fromDb('2026-01-05'), DateTime(2026, 1, 5));
  });

  test('isSameDay ignores the time', () {
    expect(
      Dates.isSameDay(DateTime(2026, 11, 1, 1), DateTime(2026, 11, 1, 23)),
      isTrue,
    );
    expect(Dates.isSameDay(DateTime(2026, 11), DateTime(2026, 11, 2)), isFalse);
  });

  test('newUuid makes valid, unique v4 ids', () {
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    final ids = {for (var i = 0; i < 200; i++) newUuid()};
    expect(ids, hasLength(200));
    expect(ids.every(pattern.hasMatch), isTrue);
  });
}

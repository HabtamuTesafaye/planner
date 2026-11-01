import 'package:flutter/foundation.dart';

import '../../core/utils/dates.dart';
import '../../data/models/task.dart';

/// Tasks done per calendar day (only done tasks count).
Map<DateTime, int> doneByDay(Iterable<Task> tasks) {
  final counts = <DateTime, int>{};
  for (final t in tasks) {
    if (!t.done) continue;
    final d = Dates.dateOnly(t.day);
    counts[d] = (counts[d] ?? 0) + 1;
  }
  return counts;
}

/// Mondays of the last [weeks] weeks, oldest first, ending with this week.
List<DateTime> heatmapWeeks(DateTime today, int weeks) {
  final current = Dates.weekStart(today);
  return [
    for (var i = weeks - 1; i >= 0; i--)
      DateTime(current.year, current.month, current.day - 7 * i),
  ];
}

/// Tasks done in each of the last [weeks] weeks, oldest first.
List<({DateTime weekStart, int done})> weeklyDone(
  Map<DateTime, int> byDay,
  DateTime today,
  int weeks,
) {
  return [
    for (final start in heatmapWeeks(today, weeks))
      (
        weekStart: start,
        done: [
          for (var d = 0; d < 7; d++)
            byDay[DateTime(start.year, start.month, start.day + d)] ?? 0,
        ].fold(0, (a, b) => a + b),
      ),
  ];
}

/// The headline numbers. Calm facts: no streaks, no scores.
@immutable
class InsightSummary {
  const InsightSummary({
    required this.doneThisWeek,
    required this.doneLastWeek,
    required this.activeDays30,
    required this.completion30,
    required this.bestWeekday,
    required this.totalDone,
  });

  final int doneThisWeek;
  final int doneLastWeek;

  /// Days in the last 30 with at least one task done.
  final int activeDays30;

  /// Done / planned over the last 30 days, 0..1 (null when nothing planned).
  final double? completion30;

  /// Weekday (1 = Monday) with the most tasks done in the last 12 weeks,
  /// or null when there is nothing yet.
  final int? bestWeekday;

  /// Tasks done in the whole loaded history.
  final int totalDone;
}

InsightSummary summarize(Iterable<Task> tasks, DateTime today) {
  final list = tasks.toList();
  final byDay = doneByDay(list);
  final thisWeek = Dates.weekStart(today);
  final lastWeek = DateTime(thisWeek.year, thisWeek.month, thisWeek.day - 7);

  int doneIn(DateTime start) => [
    for (var d = 0; d < 7; d++)
      byDay[DateTime(start.year, start.month, start.day + d)] ?? 0,
  ].fold(0, (a, b) => a + b);

  final from30 = DateTime(today.year, today.month, today.day - 29);
  bool in30(DateTime d) =>
      !Dates.dateOnly(d).isBefore(from30) && !Dates.dateOnly(d).isAfter(today);
  final planned30 = list.where((t) => in30(t.day)).length;
  final done30 = list.where((t) => t.done && in30(t.day)).length;

  final from12w = DateTime(
    thisWeek.year,
    thisWeek.month,
    thisWeek.day - 7 * 11,
  );
  final perWeekday = <int, int>{};
  byDay.forEach((day, n) {
    if (!day.isBefore(from12w)) {
      perWeekday[day.weekday] = (perWeekday[day.weekday] ?? 0) + n;
    }
  });
  int? best;
  for (final e in perWeekday.entries) {
    if (best == null ||
        e.value > perWeekday[best]! ||
        (e.value == perWeekday[best]! && e.key < best)) {
      best = e.key;
    }
  }

  return InsightSummary(
    doneThisWeek: doneIn(thisWeek),
    doneLastWeek: doneIn(lastWeek),
    activeDays30: byDay.entries.where((e) => in30(e.key) && e.value > 0).length,
    completion30: planned30 == 0 ? null : done30 / planned30,
    bestWeekday: best,
    totalDone: byDay.values.fold(0, (a, b) => a + b),
  );
}

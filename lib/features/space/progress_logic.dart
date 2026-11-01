import 'package:flutter/foundation.dart';

import '../../core/utils/dates.dart';
import '../../data/models/contact.dart';
import '../../data/models/task.dart';
import '../../data/models/team_member.dart';
import '../../data/models/weekly_goal.dart';
import '../../data/models/weekly_review.dart';

/// One member's week in a space, derived from existing tables. Calm facts
/// only: no scores, no rankings.
@immutable
class MemberProgress {
  const MemberProgress({
    required this.member,
    required this.todayPlanned,
    required this.todayDone,
    required this.doneThisWeek,
    required this.contactsThisWeek,
    required this.goal,
    required this.lastReview,
    required this.todayTasks,
  });

  final TeamMember member;
  final int todayPlanned;
  final int todayDone;
  final int doneThisWeek;
  final int contactsThisWeek;
  final String? goal;
  final DateTime? lastReview;
  final List<Task> todayTasks;
}

/// Builds a card for every member, in member order (oldest first).
List<MemberProgress> buildProgress({
  required List<TeamMember> members,
  required List<Task> spaceTasks,
  required List<Contact> contacts,
  required List<WeeklyGoal> goals,
  required List<WeeklyReview> reviews,
  required DateTime today,
}) {
  final weekStart = Dates.weekStart(today);
  final weekEnd = Dates.weekEnd(today);
  bool inWeek(DateTime d) =>
      !Dates.dateOnly(d).isBefore(weekStart) &&
      !Dates.dateOnly(d).isAfter(weekEnd);

  return [
    for (final m in members)
      () {
        final mine = spaceTasks.where((t) => t.userId == m.userId);
        final todays = mine.where((t) => Dates.isSameDay(t.day, today)).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        final reviewDates =
            reviews
                .where((r) => r.userId == m.userId)
                .map((r) => r.updatedAt ?? r.weekStart)
                .toList()
              ..sort((a, b) => b.compareTo(a));
        return MemberProgress(
          member: m,
          todayPlanned: todays.length,
          todayDone: todays.where((t) => t.done).length,
          doneThisWeek: mine.where((t) => t.done && inWeek(t.day)).length,
          contactsThisWeek: contacts
              .where((c) => c.ownerId == m.userId && inWeek(c.createdAt))
              .length,
          goal: goals
              .where((g) => g.userId == m.userId && g.weekStart == weekStart)
              .map((g) => g.goal)
              .firstOrNull,
          lastReview: reviewDates.firstOrNull,
          todayTasks: todays,
        );
      }(),
  ];
}

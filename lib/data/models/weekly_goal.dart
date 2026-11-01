import 'package:flutter/foundation.dart';

import '../../core/utils/dates.dart';

/// A person's goal for one week in one space.
@immutable
class WeeklyGoal {
  const WeeklyGoal({
    required this.spaceId,
    required this.userId,
    required this.weekStart,
    required this.goal,
  });

  factory WeeklyGoal.fromJson(Map<String, dynamic> json) => WeeklyGoal(
    spaceId: json['team_id'] as String,
    userId: json['user_id'] as String,
    weekStart: Dates.fromDb(json['week_start'] as String),
    goal: json['goal'] as String,
  );

  static const int maxLength = 200;

  final String spaceId;
  final String userId;

  /// Monday of the week.
  final DateTime weekStart;
  final String goal;

  Map<String, dynamic> toJson() => {
    'team_id': spaceId,
    'user_id': userId,
    'week_start': Dates.toDb(weekStart),
    'goal': goal.trim(),
  };

  @override
  bool operator ==(Object other) =>
      other is WeeklyGoal &&
      other.spaceId == spaceId &&
      other.userId == userId &&
      other.weekStart == weekStart &&
      other.goal == goal;

  @override
  int get hashCode => Object.hash(spaceId, userId, weekStart, goal);
}

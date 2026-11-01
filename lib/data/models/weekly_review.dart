import 'package:flutter/foundation.dart';

import '../../core/utils/dates.dart';

/// A person's short review of one week in one space.
@immutable
class WeeklyReview {
  const WeeklyReview({
    required this.spaceId,
    required this.userId,
    required this.weekStart,
    required this.did,
    required this.blocked,
    required this.nextGoal,
    this.updatedAt,
  });

  factory WeeklyReview.fromJson(Map<String, dynamic> json) => WeeklyReview(
    spaceId: json['team_id'] as String,
    userId: json['user_id'] as String,
    weekStart: Dates.fromDb(json['week_start'] as String),
    did: json['did'] as String? ?? '',
    blocked: json['blocked'] as String? ?? '',
    nextGoal: json['next_goal'] as String? ?? '',
    updatedAt: switch (json['updated_at']) {
      final String t => DateTime.parse(t).toLocal(),
      _ => null,
    },
  );

  static const int maxText = 1000;
  static const int maxGoal = 200;

  final String spaceId;
  final String userId;

  /// Monday of the reviewed week.
  final DateTime weekStart;
  final String did;
  final String blocked;
  final String nextGoal;
  final DateTime? updatedAt;

  bool get isEmpty =>
      did.trim().isEmpty && blocked.trim().isEmpty && nextGoal.trim().isEmpty;

  Map<String, dynamic> toJson() => {
    'team_id': spaceId,
    'user_id': userId,
    'week_start': Dates.toDb(weekStart),
    'did': did.trim(),
    'blocked': blocked.trim(),
    'next_goal': nextGoal.trim(),
  };

  @override
  bool operator ==(Object other) =>
      other is WeeklyReview &&
      other.spaceId == spaceId &&
      other.userId == userId &&
      other.weekStart == weekStart &&
      other.did == did &&
      other.blocked == blocked &&
      other.nextGoal == nextGoal;

  @override
  int get hashCode =>
      Object.hash(spaceId, userId, weekStart, did, blocked, nextGoal);
}

import 'package:flutter/foundation.dart';

import '../../core/utils/dates.dart';

/// One of a person's (max 3) tasks for a day, in a space.
@immutable
class Task {
  const Task({
    required this.id,
    required this.spaceId,
    required this.userId,
    required this.title,
    required this.day,
    required this.done,
    required this.createdAt,
    this.doneAt,
    this.projectItemId,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    spaceId: json['team_id'] as String,
    userId: json['user_id'] as String,
    title: json['title'] as String,
    day: Dates.fromDb(json['day'] as String),
    done: json['done'] as bool? ?? false,
    doneAt: _time(json['done_at']),
    createdAt: _time(json['created_at']) ?? DateTime.now(),
    projectItemId: json['project_item_id'] as String?,
  );

  static const int maxTitleLength = 120;
  static const int dailyLimit = 3;

  final String id;
  final String spaceId;
  final String userId;
  final String title;

  /// Calendar date (local).
  final DateTime day;
  final bool done;
  final DateTime? doneAt;
  final DateTime createdAt;

  /// The project step this task was planned from, if any.
  final String? projectItemId;

  Task copyWith({bool? done}) => Task(
    id: id,
    spaceId: spaceId,
    userId: userId,
    title: title,
    day: day,
    done: done ?? this.done,
    doneAt: doneAt,
    createdAt: createdAt,
    projectItemId: projectItemId,
  );

  /// Columns sent on insert. done_at and created_at belong to the database.
  Map<String, dynamic> toInsertJson() => {
    'id': id,
    'team_id': spaceId,
    'user_id': userId,
    'title': title.trim(),
    'day': Dates.toDb(day),
    'done': done,
    if (projectItemId != null) 'project_item_id': projectItemId,
  };

  Map<String, dynamic> toJson() => {
    ...toInsertJson(),
    'done_at': doneAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  static DateTime? _time(Object? value) =>
      value is String ? DateTime.parse(value).toLocal() : null;

  @override
  bool operator ==(Object other) =>
      other is Task &&
      other.id == id &&
      other.spaceId == spaceId &&
      other.title == title &&
      other.day == day &&
      other.done == done &&
      other.projectItemId == projectItemId;

  @override
  int get hashCode => Object.hash(id, spaceId, title, day, done, projectItemId);
}

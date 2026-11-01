import 'package:flutter/foundation.dart';

/// A team. [joinCode] is visible to members only (RLS).
@immutable
class Team {
  const Team({
    required this.id,
    required this.name,
    required this.joinCode,
    required this.createdAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) => Team(
    id: json['id'] as String,
    name: json['name'] as String,
    joinCode: json['join_code'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  final String id;
  final String name;
  final String joinCode;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'join_code': joinCode,
    'created_at': createdAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is Team &&
      other.id == id &&
      other.name == name &&
      other.joinCode == joinCode &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, name, joinCode, createdAt);
}

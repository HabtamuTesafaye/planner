import 'package:flutter/foundation.dart';

enum SpaceKind {
  personal,
  team;

  static SpaceKind parse(String? value) =>
      value == 'personal' ? SpaceKind.personal : SpaceKind.team;
}

/// A space: the user's private Personal space, or a shared team space.
/// Stored in the `teams` table. [joinCode] is null for personal spaces and
/// visible to members only (RLS).
@immutable
class Space {
  const Space({
    required this.id,
    required this.name,
    required this.kind,
    required this.joinCode,
    required this.createdAt,
  });

  factory Space.fromJson(Map<String, dynamic> json) => Space(
    id: json['id'] as String,
    name: json['name'] as String,
    kind: SpaceKind.parse(json['kind'] as String?),
    joinCode: json['join_code'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  final String id;
  final String name;
  final SpaceKind kind;
  final String? joinCode;
  final DateTime createdAt;

  bool get isPersonal => kind == SpaceKind.personal;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kind': kind.name,
    'join_code': joinCode,
    'created_at': createdAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is Space &&
      other.id == id &&
      other.name == name &&
      other.kind == kind &&
      other.joinCode == joinCode &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, name, kind, joinCode, createdAt);
}

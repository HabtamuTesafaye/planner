import 'package:flutter/foundation.dart';

enum TeamRole {
  owner,
  member;

  static TeamRole parse(String value) =>
      value == 'owner' ? TeamRole.owner : TeamRole.member;
}

/// A member of a team, with their display name from `profiles`.
@immutable
class TeamMember {
  const TeamMember({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
  });

  /// Expects a `team_members` row with `profiles(display_name)` embedded.
  factory TeamMember.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return TeamMember(
      userId: json['user_id'] as String,
      displayName: (profile?['display_name'] as String?) ?? 'Teammate',
      role: TeamRole.parse(json['role'] as String),
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  final String userId;
  final String displayName;
  final TeamRole role;
  final DateTime joinedAt;

  bool get isOwner => role == TeamRole.owner;

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'role': role.name,
    'joined_at': joinedAt.toIso8601String(),
    'profiles': {'display_name': displayName},
  };

  @override
  bool operator ==(Object other) =>
      other is TeamMember &&
      other.userId == userId &&
      other.displayName == displayName &&
      other.role == role &&
      other.joinedAt == joinedAt;

  @override
  int get hashCode => Object.hash(userId, displayName, role, joinedAt);
}

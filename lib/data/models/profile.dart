import 'package:flutter/foundation.dart';

/// A user's public profile.
@immutable
class Profile {
  const Profile({required this.id, required this.displayName});

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    displayName: json['display_name'] as String,
  );

  final String id;
  final String displayName;

  Map<String, dynamic> toJson() => {'id': id, 'display_name': displayName};

  @override
  bool operator ==(Object other) =>
      other is Profile && other.id == id && other.displayName == displayName;

  @override
  int get hashCode => Object.hash(id, displayName);
}

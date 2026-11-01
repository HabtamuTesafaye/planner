import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode, TimeOfDay;

/// A user's profile: display name, selected space and settings.
@immutable
class Profile {
  const Profile({
    required this.id,
    required this.displayName,
    this.lastSpaceId,
    this.themeMode = ThemeMode.system,
    this.reminderTime,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    displayName: json['display_name'] as String,
    lastSpaceId: json['last_team_id'] as String?,
    themeMode: parseThemeMode(json['theme'] as String?),
    reminderTime: parseTime(json['reminder_time'] as String?),
  );

  final String id;
  final String displayName;

  /// The space selected last time (may be stale; the app checks it).
  final String? lastSpaceId;
  final ThemeMode themeMode;

  /// Daily reminder in device local time; null means off.
  final TimeOfDay? reminderTime;

  Map<String, dynamic> toJson() => {
    'id': id,
    'display_name': displayName,
    'last_team_id': lastSpaceId,
    'theme': themeMode.name,
    'reminder_time': reminderTime == null ? null : formatTime(reminderTime!),
  };

  static ThemeMode parseThemeMode(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  /// Postgres `time` ("07:30:00") to [TimeOfDay].
  static TimeOfDay? parseTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:00';

  @override
  bool operator ==(Object other) =>
      other is Profile &&
      other.id == id &&
      other.displayName == displayName &&
      other.lastSpaceId == lastSpaceId &&
      other.themeMode == themeMode &&
      other.reminderTime == reminderTime;

  @override
  int get hashCode =>
      Object.hash(id, displayName, lastSpaceId, themeMode, reminderTime);
}

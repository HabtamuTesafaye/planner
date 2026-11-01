import 'package:flutter/material.dart' show ThemeMode, TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:planner/data/models/profile.dart';
import 'package:planner/data/models/space.dart';
import 'package:planner/data/models/team_member.dart';

void main() {
  test('Space maps a team space and back', () {
    final space = Space.fromJson(const {
      'id': 't1',
      'name': 'Founders',
      'kind': 'team',
      'join_code': 'ABCDEFGH',
      'created_at': '2026-11-01T08:00:00.000Z',
    });
    expect(space.name, 'Founders');
    expect(space.isPersonal, isFalse);
    expect(space.joinCode, 'ABCDEFGH');
    expect(space.createdAt, DateTime.utc(2026, 11, 1, 8));
    expect(Space.fromJson(space.toJson()), space);
  });

  test('Space maps a personal space (no code)', () {
    final space = Space.fromJson(const {
      'id': 'p1',
      'name': 'Personal',
      'kind': 'personal',
      'join_code': null,
      'created_at': '2026-11-01T08:00:00Z',
    });
    expect(space.isPersonal, isTrue);
    expect(space.joinCode, isNull);
  });

  test('TeamMember reads the embedded profile name and role', () {
    final member = TeamMember.fromJson(const {
      'user_id': 'u1',
      'role': 'owner',
      'joined_at': '2026-11-01T08:00:00Z',
      'profiles': {'display_name': 'Abebe'},
    });
    expect(member.displayName, 'Abebe');
    expect(member.isOwner, isTrue);
    expect(TeamMember.fromJson(member.toJson()), member);
  });

  test('TeamMember without a visible profile falls back to "Teammate"', () {
    final member = TeamMember.fromJson(const {
      'user_id': 'u2',
      'role': 'member',
      'joined_at': '2026-11-01T08:00:00Z',
      'profiles': null,
    });
    expect(member.displayName, 'Teammate');
    expect(member.isOwner, isFalse);
  });

  test('Profile maps settings and round-trips', () {
    final profile = Profile.fromJson(const {
      'id': 'u1',
      'display_name': 'Sara',
      'last_team_id': 't1',
      'theme': 'dark',
      'reminder_time': '07:30:00',
    });
    expect(profile.displayName, 'Sara');
    expect(profile.lastSpaceId, 't1');
    expect(profile.themeMode, ThemeMode.dark);
    expect(profile.reminderTime, const TimeOfDay(hour: 7, minute: 30));
    expect(Profile.fromJson(profile.toJson()), profile);
  });

  test('Profile defaults: system theme, no reminder', () {
    final profile = Profile.fromJson(const {'id': 'u1', 'display_name': 'S'});
    expect(profile.themeMode, ThemeMode.system);
    expect(profile.reminderTime, isNull);
  });
}

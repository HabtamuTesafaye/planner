import 'package:flutter_test/flutter_test.dart';
import 'package:planner/data/models/profile.dart';
import 'package:planner/data/models/team.dart';
import 'package:planner/data/models/team_member.dart';

void main() {
  test('Team maps the database row and back', () {
    final json = {
      'id': 't1',
      'name': 'Founders',
      'join_code': 'ABCDEFGH',
      'created_at': '2026-11-01T08:00:00.000Z',
    };
    final team = Team.fromJson(json);
    expect(team.name, 'Founders');
    expect(team.joinCode, 'ABCDEFGH');
    expect(team.createdAt, DateTime.utc(2026, 11, 1, 8));
    expect(Team.fromJson(team.toJson()), team);
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

  test('Profile maps and round-trips', () {
    final profile = Profile.fromJson(const {
      'id': 'u1',
      'display_name': 'Sara',
    });
    expect(profile.displayName, 'Sara');
    expect(Profile.fromJson(profile.toJson()), profile);
  });
}

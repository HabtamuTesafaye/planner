import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_exception.dart';
import '../models/team.dart';
import '../models/team_member.dart';
import '../supabase_client.dart';

/// Teams and memberships. Creating, joining and leaving go through the
/// database functions in 008_rpcs, which enforce the rules.
class TeamRepository {
  const TeamRepository(this._client);

  final SupabaseClient _client;

  Future<Team> createTeam(String name) => _guard(() async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'create_team',
      params: {'p_name': name.trim()},
    );
    return Team.fromJson(row);
  });

  /// [code] is sent as typed; the database ignores case, spaces and dashes.
  Future<Team> joinTeam(String code) => _guard(() async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'join_team',
      params: {'p_code': code},
    );
    return Team.fromJson(row);
  });

  Future<void> leaveTeam() => _guard(() => _client.rpc<void>('leave_team'));

  /// The caller's team, or null if they are not in one.
  Future<Team?> fetchMyTeam(String userId) => _guard(() async {
    final row = await _client
        .from('team_members')
        .select('teams(id, name, join_code, created_at)')
        .eq('user_id', userId)
        .maybeSingle();
    final team = row?['teams'] as Map<String, dynamic>?;
    return team == null ? null : Team.fromJson(team);
  });

  /// Members of a team with their names, oldest first.
  Future<List<TeamMember>> fetchMembers(String teamId) => _guard(() async {
    final rows = await _client
        .from('team_members')
        .select('user_id, role, joined_at, profiles(display_name)')
        .eq('team_id', teamId)
        .order('joined_at');
    return rows.map(TeamMember.fromJson).toList(growable: false);
  });

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e, s) {
      throw AppException.from(e, s);
    }
  }
}

final teamRepositoryProvider = Provider<TeamRepository>(
  (ref) => TeamRepository(ref.watch(supabaseClientProvider)),
);

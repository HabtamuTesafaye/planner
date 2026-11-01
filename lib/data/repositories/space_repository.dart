import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_exception.dart';
import '../models/space.dart';
import '../models/team_member.dart';
import '../supabase_client.dart';

/// Spaces and memberships. Creating, joining and leaving go through the
/// database functions (011_spaces), which enforce the rules.
class SpaceRepository {
  const SpaceRepository(this._client);

  final SupabaseClient _client;

  static const _spaceColumns = 'id, name, kind, join_code, created_at';

  Future<Space> createSpace(String name) => _guard(() async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'create_team',
      params: {'p_name': name.trim()},
    );
    return Space.fromJson(row);
  });

  /// [code] is sent as typed; the database ignores case, spaces and dashes.
  Future<Space> joinSpace(String code) => _guard(() async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'join_team',
      params: {'p_code': code},
    );
    return Space.fromJson(row);
  });

  Future<void> leaveSpace(String spaceId) => _guard(
    () => _client.rpc<void>('leave_team', params: {'p_team_id': spaceId}),
  );

  /// Every space the user belongs to: Personal first, then by name.
  Future<List<Space>> fetchMySpaces(String userId) => _guard(() async {
    final rows = await _client
        .from('team_members')
        .select('teams($_spaceColumns)')
        .eq('user_id', userId);
    final spaces = [
      for (final row in rows)
        if (row['teams'] case final Map<String, dynamic> team)
          Space.fromJson(team),
    ];
    return sortSpaces(spaces);
  });

  Future<void> renameSpace(String spaceId, String name) => _guard(
    () => _client.from('teams').update({'name': name.trim()}).eq('id', spaceId),
  );

  /// Members of a space with their names, oldest first.
  Future<List<TeamMember>> fetchMembers(String spaceId) => _guard(() async {
    final rows = await _client
        .from('team_members')
        .select('user_id, role, joined_at, profiles(display_name)')
        .eq('team_id', spaceId)
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

/// Personal space first, then team spaces by name.
List<Space> sortSpaces(Iterable<Space> spaces) {
  final list = spaces.toList()
    ..sort((a, b) {
      if (a.isPersonal != b.isPersonal) return a.isPersonal ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  return List.unmodifiable(list);
}

final spaceRepositoryProvider = Provider<SpaceRepository>(
  (ref) => SpaceRepository(ref.watch(supabaseClientProvider)),
);

import 'package:flutter/material.dart' show ThemeMode, TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_exception.dart';
import '../models/profile.dart';
import '../supabase_client.dart';

/// The signed-in user's profile and settings. Created by a database trigger
/// on sign-up. Settings live here so no extra local-storage package is
/// needed.
class ProfileRepository {
  const ProfileRepository(this._client);

  final SupabaseClient _client;

  /// The signed-in user's own profile with settings. Settings columns are
  /// private (teammates only see names), so this goes through
  /// get_my_profile(), which only ever returns the caller's row.
  Future<Profile?> fetchProfile(String userId) => _guard(() async {
    final rows = await _client.rpc<List<dynamic>>('get_my_profile');
    final mine = rows.cast<Map<String, dynamic>>().where(
      (r) => r['id'] == userId,
    );
    return mine.isEmpty ? null : Profile.fromJson(mine.first);
  });

  Future<void> setLastSpace(String userId, String spaceId) =>
      _update(userId, {'last_team_id': spaceId});

  Future<void> setThemeMode(String userId, ThemeMode mode) =>
      _update(userId, {'theme': mode.name});

  Future<void> setReminderTime(String userId, TimeOfDay? time) => _update(
    userId,
    {'reminder_time': time == null ? null : Profile.formatTime(time)},
  );

  Future<void> setDisplayName(String userId, String name) =>
      _update(userId, {'display_name': name.trim()});

  Future<void> _update(String userId, Map<String, dynamic> values) =>
      _guard(() => _client.from('profiles').update(values).eq('id', userId));

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e, s) {
      throw AppException.from(e, s);
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(supabaseClientProvider)),
);

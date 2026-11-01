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

  Future<Profile?> fetchProfile(String userId) => _guard(() async {
    final row = await _client
        .from('profiles')
        .select('id, display_name, last_team_id, theme, reminder_time')
        .eq('id', userId)
        .maybeSingle();
    return row == null ? null : Profile.fromJson(row);
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/dates.dart';
import '../app_exception.dart';
import '../models/weekly_goal.dart';
import '../supabase_client.dart';

/// Goal of the week, per person per space.
class GoalsRepository {
  const GoalsRepository(this._client);

  final SupabaseClient _client;

  Future<WeeklyGoal?> fetchGoal({
    required String spaceId,
    required String userId,
    required DateTime weekStart,
  }) => _guard(() async {
    final row = await _client
        .from('weekly_goals')
        .select()
        .eq('team_id', spaceId)
        .eq('user_id', userId)
        .eq('week_start', Dates.toDb(weekStart))
        .maybeSingle();
    return row == null ? null : WeeklyGoal.fromJson(row);
  });

  /// Goals of every member of a space for one week (for the Space tab).
  Future<List<WeeklyGoal>> fetchSpaceGoals(
    String spaceId,
    DateTime weekStart,
  ) => _guard(() async {
    final rows = await _client
        .from('weekly_goals')
        .select()
        .eq('team_id', spaceId)
        .eq('week_start', Dates.toDb(weekStart));
    return rows.map(WeeklyGoal.fromJson).toList(growable: false);
  });

  /// Saves the goal; an empty goal removes it.
  Future<void> saveGoal(WeeklyGoal goal) => _guard(() async {
    if (goal.goal.trim().isEmpty) {
      await _client
          .from('weekly_goals')
          .delete()
          .eq('team_id', goal.spaceId)
          .eq('user_id', goal.userId)
          .eq('week_start', Dates.toDb(goal.weekStart));
      return;
    }
    await _client
        .from('weekly_goals')
        .upsert(goal.toJson(), onConflict: 'team_id,user_id,week_start');
  });

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e, s) {
      throw AppException.from(e, s);
    }
  }
}

final goalsRepositoryProvider = Provider<GoalsRepository>(
  (ref) => GoalsRepository(ref.watch(supabaseClientProvider)),
);

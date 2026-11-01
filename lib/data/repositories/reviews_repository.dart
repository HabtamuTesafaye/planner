import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/dates.dart';
import '../app_exception.dart';
import '../models/weekly_goal.dart';
import '../models/weekly_review.dart';
import '../supabase_client.dart';

/// Weekly reviews of a space. One per person per week; saving again edits
/// it. The "next week's goal" also becomes next week's goal of the week.
class ReviewsRepository {
  const ReviewsRepository(this._client);

  final SupabaseClient _client;

  /// Recent reviews of everyone in the space, newest week first.
  Future<List<WeeklyReview>> fetchSpaceReviews(String spaceId) =>
      _guard(() async {
        final rows = await _client
            .from('weekly_reviews')
            .select()
            .eq('team_id', spaceId)
            .order('week_start', ascending: false)
            .limit(60);
        return rows.map(WeeklyReview.fromJson).toList(growable: false);
      });

  Future<void> save(WeeklyReview review) => _guard(() async {
    await _client
        .from('weekly_reviews')
        .upsert(review.toJson(), onConflict: 'team_id,user_id,week_start');
    final goal = review.nextGoal.trim();
    if (goal.isEmpty) return;
    final next = Dates.weekStart(review.weekStart.add(const Duration(days: 7)));
    await _client
        .from('weekly_goals')
        .upsert(
          WeeklyGoal(
            spaceId: review.spaceId,
            userId: review.userId,
            weekStart: next,
            goal: goal.length > WeeklyGoal.maxLength
                ? goal.substring(0, WeeklyGoal.maxLength)
                : goal,
          ).toJson(),
          onConflict: 'team_id,user_id,week_start',
        );
  });

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e, s) {
      throw AppException.from(e, s);
    }
  }
}

final reviewsRepositoryProvider = Provider<ReviewsRepository>(
  (ref) => ReviewsRepository(ref.watch(supabaseClientProvider)),
);

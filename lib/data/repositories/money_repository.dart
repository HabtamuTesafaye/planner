import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/dates.dart';
import '../app_exception.dart';
import '../models/income.dart';
import '../supabase_client.dart';

/// Income entries and monthly targets of a space.
class MoneyRepository {
  const MoneyRepository(this._client);

  final SupabaseClient _client;

  /// Live entries of the space, newest months first (enough for history).
  Stream<List<IncomeEntry>> watchEntries(String spaceId) => _client
      .from('income_entries')
      .stream(primaryKey: ['id'])
      .eq('team_id', spaceId)
      .order('month')
      .limit(500)
      .map((rows) => rows.map(IncomeEntry.fromJson).toList(growable: false))
      .handleError((Object e, StackTrace s) => throw AppException.from(e, s));

  Future<MonthlyTarget?> fetchTarget(String spaceId, DateTime month) =>
      _guard(() async {
        final row = await _client
            .from('monthly_targets')
            .select()
            .eq('team_id', spaceId)
            .eq('month', Dates.toDb(Dates.monthStart(month)))
            .maybeSingle();
        return row == null ? null : MonthlyTarget.fromJson(row);
      });

  Future<void> setTarget(MonthlyTarget target) => _guard(
    () => _client
        .from('monthly_targets')
        .upsert(target.toJson(), onConflict: 'team_id,month'),
  );

  Future<void> add(IncomeEntry entry) =>
      _guard(() => _client.from('income_entries').insert(entry.toInsertJson()));

  /// Returns false when the database refused (not the creator or owner).
  Future<bool> delete(String id) => _guard(() async {
    final rows = await _client
        .from('income_entries')
        .delete()
        .eq('id', id)
        .select('id');
    return rows.isNotEmpty;
  });

  /// Undo for delete (same id).
  Future<void> restore(IncomeEntry entry) => add(entry);

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e, s) {
      throw AppException.from(e, s);
    }
  }
}

final moneyRepositoryProvider = Provider<MoneyRepository>(
  (ref) => MoneyRepository(ref.watch(supabaseClientProvider)),
);

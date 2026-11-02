import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_exception.dart';
import '../supabase_client.dart';

/// The server's clock. Phones can have the wrong date or time; the server's
/// is the reference for "today" (see [ServerClock]).
class TimeRepository {
  const TimeRepository(this._client);

  final SupabaseClient _client;

  Future<DateTime> serverNow() async {
    try {
      final value = await _client.rpc<String>('server_now');
      return DateTime.parse(value);
    } catch (e, s) {
      throw AppException.from(e, s);
    }
  }
}

final timeRepositoryProvider = Provider<TimeRepository>(
  (ref) => TimeRepository(ref.watch(supabaseClientProvider)),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';

/// Initializes Supabase once at startup. The session is persisted by
/// supabase_flutter itself; the app never stores passwords or tokens.
Future<void> initSupabase(AppConfig config) async {
  await Supabase.initialize(
    url: config.supabaseUrl,
    // The anon key is public by design; RLS protects the data.
    publishableKey: config.supabaseAnonKey,
  );
}

/// The Supabase client. Only repositories in `lib/data/` use it.
/// Overridden in tests.
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

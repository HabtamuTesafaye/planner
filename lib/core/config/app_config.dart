import 'package:flutter/foundation.dart';

/// Values passed at build time with
/// `--dart-define-from-file=env/staging.json`.
///
/// The anon key is public by design: data is protected by Row Level
/// Security, not by hiding this key. Never put the service_role key here.
@immutable
class AppConfig {
  const AppConfig({required this.supabaseUrl, required this.supabaseAnonKey});

  /// Reads the compile-time environment.
  factory AppConfig.fromEnvironment() => const AppConfig(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  final String supabaseUrl;
  final String supabaseAnonKey;

  /// Names of settings that are missing or malformed. Empty when the
  /// config is usable.
  List<String> get problems {
    final result = <String>[];
    final uri = Uri.tryParse(supabaseUrl.trim());
    if (supabaseUrl.trim().isEmpty) {
      result.add('SUPABASE_URL is missing');
    } else if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      result.add('SUPABASE_URL must be an https:// address');
    }
    if (supabaseAnonKey.trim().isEmpty) {
      result.add('SUPABASE_ANON_KEY is missing');
    }
    return result;
  }

  bool get isComplete => problems.isEmpty;
}

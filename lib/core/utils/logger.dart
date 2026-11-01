import 'dart:developer' as developer;

/// Tiny logger. Never use `print` in committed code (AGENTS.md section 10).
/// Messages go to the debug console only; nothing is sent anywhere.
abstract final class Log {
  static void info(String message) => developer.log(message, name: 'planner');

  static void error(String message, Object error, [StackTrace? stack]) {
    developer.log(
      message,
      name: 'planner',
      error: error,
      stackTrace: stack,
      level: 1000,
    );
  }
}

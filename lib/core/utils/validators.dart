import 'join_code.dart';

/// Form validators. Each returns null when valid, or a short message.
/// Limits match the database checks.
abstract final class Validators {
  static const int minPasswordLength = 8;
  static const int maxNameLength = 60;

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? displayName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Add your name so your teammate knows it is you.';
    if (v.length > maxNameLength) {
      return 'Keep it under $maxNameLength characters.';
    }
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email.';
    if (!_email.hasMatch(v)) return 'That email address looks incomplete.';
    return null;
  }

  /// For sign-up: enforces the minimum length.
  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.length < minPasswordLength) {
      return 'Use at least $minPasswordLength characters.';
    }
    return null;
  }

  /// For sign-in: only checks it is not empty.
  static String? password(String? value) {
    if ((value ?? '').isEmpty) return 'Enter your password.';
    return null;
  }

  static String? teamName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Give your team a name.';
    if (v.length > maxNameLength) {
      return 'Keep it under $maxNameLength characters.';
    }
    return null;
  }

  static String? joinCode(String? value) {
    if (!JoinCode.isComplete(value ?? '')) {
      return 'The code has ${JoinCode.length} letters and numbers.';
    }
    return null;
  }
}

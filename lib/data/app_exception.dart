import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/logger.dart';

/// What went wrong, in terms the app cares about.
enum AppErrorKind {
  wrongCredentials,
  emailNotConfirmed,
  emailInUse,
  weakPassword,
  invalidEmail,
  invalidCode,
  alreadyMember,
  tooManySpaces,
  cannotLeavePersonal,
  notInTeam,
  invalidTeamName,
  taskLimit,
  rateLimited,
  signedOut,
  network,
  unknown,
}

/// The only error type the UI sees. Every Supabase, network or unknown
/// error is translated here, in one place, into a short friendly message.
/// Raw exception text never reaches the screen.
class AppException implements Exception {
  const AppException(this.kind);

  /// Translates any thrown object. Unknown errors are logged, never
  /// swallowed silently.
  factory AppException.from(Object error, [StackTrace? stack]) {
    if (error is AppException) return error;
    final kind = _classify(error);
    if (kind == AppErrorKind.unknown) {
      Log.error('Unexpected error', error, stack);
    }
    return AppException(kind);
  }

  final AppErrorKind kind;

  String get message => switch (kind) {
    AppErrorKind.wrongCredentials =>
      "That email and password don't match. Check them and try again.",
    AppErrorKind.emailNotConfirmed =>
      'Please confirm your email first. We sent you a link.',
    AppErrorKind.emailInUse =>
      'This email already has an account. Sign in instead.',
    AppErrorKind.weakPassword =>
      'Choose a stronger password: at least 8 characters.',
    AppErrorKind.invalidEmail => 'That email address looks incomplete.',
    AppErrorKind.invalidCode =>
      "That code didn't work. Check it with your teammate and try again.",
    AppErrorKind.alreadyMember => "You're already in this space.",
    AppErrorKind.tooManySpaces =>
      'You can be in up to 20 spaces. Leave one to add another.',
    AppErrorKind.cannotLeavePersonal =>
      'Your personal space stays with you. It cannot be left.',
    AppErrorKind.notInTeam => "You're not in this space anymore.",
    AppErrorKind.invalidTeamName =>
      'Give the space a name of up to 60 characters.',
    AppErrorKind.taskLimit => 'Three is the limit. Finish or remove one first.',
    AppErrorKind.rateLimited =>
      'Too many tries in a short time. Wait a minute and try again.',
    AppErrorKind.signedOut => 'Your session ended. Please sign in again.',
    AppErrorKind.network =>
      "Can't reach the server. Check your connection and try again.",
    AppErrorKind.unknown =>
      "That didn't work, and it's not your fault. Please try again.",
  };

  @override
  String toString() => 'AppException($kind)';

  static AppErrorKind _classify(Object error) {
    if (error is SocketException ||
        error is TimeoutException ||
        error is HandshakeException ||
        error is AuthRetryableFetchException) {
      return AppErrorKind.network;
    }
    if (error is AuthException) return _fromAuth(error);
    if (error is PostgrestException) return _fromServerMessage(error.message);
    // http's ClientException ("Failed host lookup", "Connection refused").
    final text = error.toString();
    if (text.contains('ClientException') ||
        text.contains('Failed host lookup') ||
        text.contains('Connection refused') ||
        text.contains('Network is unreachable')) {
      return AppErrorKind.network;
    }
    return AppErrorKind.unknown;
  }

  static AppErrorKind _fromAuth(AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
        return AppErrorKind.wrongCredentials;
      case 'email_not_confirmed':
        return AppErrorKind.emailNotConfirmed;
      case 'user_already_exists':
      case 'email_exists':
        return AppErrorKind.emailInUse;
      case 'weak_password':
        return AppErrorKind.weakPassword;
      case 'email_address_invalid':
      case 'validation_failed':
        return AppErrorKind.invalidEmail;
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return AppErrorKind.rateLimited;
    }
    if (e.statusCode == '429') return AppErrorKind.rateLimited;
    // Older servers send no code for a wrong password.
    if (e.message.toLowerCase().contains('invalid login credentials')) {
      return AppErrorKind.wrongCredentials;
    }
    return AppErrorKind.unknown;
  }

  /// Error codes raised by our own database functions (see README).
  static AppErrorKind _fromServerMessage(String message) {
    return switch (message) {
      'invalid_code' => AppErrorKind.invalidCode,
      'already_in_team' || 'already_member' => AppErrorKind.alreadyMember,
      'too_many_spaces' => AppErrorKind.tooManySpaces,
      'cannot_leave_personal' => AppErrorKind.cannotLeavePersonal,
      'not_in_team' => AppErrorKind.notInTeam,
      'invalid_team_name' => AppErrorKind.invalidTeamName,
      'task_limit_reached' => AppErrorKind.taskLimit,
      'not_authenticated' => AppErrorKind.signedOut,
      _ => AppErrorKind.unknown,
    };
  }
}

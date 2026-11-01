import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:planner/data/app_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

AppErrorKind kindOf(Object error) => AppException.from(error).kind;

void main() {
  group('auth errors', () {
    test('wrong password', () {
      expect(
        kindOf(
          const AuthApiException(
            'Invalid login credentials',
            statusCode: '400',
            code: 'invalid_credentials',
          ),
        ),
        AppErrorKind.wrongCredentials,
      );
      // Older servers: no code, only the message.
      expect(
        kindOf(const AuthException('Invalid login credentials')),
        AppErrorKind.wrongCredentials,
      );
    });

    test('email already used', () {
      expect(
        kindOf(const AuthApiException('x', code: 'user_already_exists')),
        AppErrorKind.emailInUse,
      );
      expect(
        kindOf(const AuthApiException('x', code: 'email_exists')),
        AppErrorKind.emailInUse,
      );
    });

    test('email not confirmed, weak password, rate limit', () {
      expect(
        kindOf(const AuthApiException('x', code: 'email_not_confirmed')),
        AppErrorKind.emailNotConfirmed,
      );
      expect(
        kindOf(const AuthApiException('x', code: 'weak_password')),
        AppErrorKind.weakPassword,
      );
      expect(
        kindOf(const AuthApiException('x', statusCode: '429')),
        AppErrorKind.rateLimited,
      );
    });
  });

  group('team errors from the database', () {
    for (final (message, kind) in [
      ('invalid_code', AppErrorKind.invalidCode),
      ('already_in_team', AppErrorKind.alreadyInTeam),
      ('not_in_team', AppErrorKind.notInTeam),
      ('invalid_team_name', AppErrorKind.invalidTeamName),
      ('task_limit_reached', AppErrorKind.taskLimit),
      ('not_authenticated', AppErrorKind.signedOut),
    ]) {
      test(message, () {
        expect(
          kindOf(PostgrestException(message: message, code: 'P0001')),
          kind,
        );
      });
    }
  });

  group('no connection', () {
    test('socket, timeout and retryable fetch', () {
      expect(kindOf(const SocketException('x')), AppErrorKind.network);
      expect(kindOf(TimeoutException('x')), AppErrorKind.network);
      expect(
        kindOf(AuthRetryableFetchException(message: 'x')),
        AppErrorKind.network,
      );
    });

    test('http client failures', () {
      expect(
        kindOf(Exception('ClientException: Failed host lookup')),
        AppErrorKind.network,
      );
    });
  });

  test('unknown errors get a friendly generic message', () {
    final e = AppException.from(StateError('boom 0x1234'));
    expect(e.kind, AppErrorKind.unknown);
    expect(e.message, isNot(contains('boom')));
  });

  test('every message is human and never raw exception text', () {
    for (final kind in AppErrorKind.values) {
      final message = AppException(kind).message;
      expect(message, isNotEmpty);
      expect(message, isNot(contains('Exception')));
      expect(message, isNot(contains('_')), reason: '$kind: $message');
    }
  });

  test('an AppException passes through unchanged', () {
    const original = AppException(AppErrorKind.invalidCode);
    expect(AppException.from(original), same(original));
  });
}

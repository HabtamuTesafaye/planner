import 'package:flutter_test/flutter_test.dart';
import 'package:planner/core/utils/validators.dart';

void main() {
  test('display name: required, max 60', () {
    expect(Validators.displayName('  '), isNotNull);
    expect(Validators.displayName('Habtamu'), isNull);
    expect(Validators.displayName('x' * 61), isNotNull);
  });

  test('email: needs a real-looking address', () {
    expect(Validators.email(''), isNotNull);
    expect(Validators.email('name@'), isNotNull);
    expect(Validators.email('name@example'), isNotNull);
    expect(Validators.email(' name@example.com '), isNull);
  });

  test('new password: at least 8 characters', () {
    expect(Validators.newPassword('1234567'), isNotNull);
    expect(Validators.newPassword('12345678'), isNull);
  });

  test('sign-in password: only required', () {
    expect(Validators.password(''), isNotNull);
    expect(Validators.password('x'), isNull);
  });

  test('team name: required, max 60', () {
    expect(Validators.teamName(''), isNotNull);
    expect(Validators.teamName('Founders'), isNull);
    expect(Validators.teamName('x' * 61), isNotNull);
  });

  test('join code: 8 valid characters, any case and spacing', () {
    expect(Validators.joinCode('abcd efgh'), isNull);
    expect(Validators.joinCode('ABCD'), isNotNull);
  });
}

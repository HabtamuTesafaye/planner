import 'package:flutter_test/flutter_test.dart';
import 'package:planner/core/config/app_config.dart';

void main() {
  test('complete config has no problems', () {
    const config = AppConfig(
      supabaseUrl: 'https://abc.supabase.co',
      supabaseAnonKey: 'key',
    );
    expect(config.isComplete, isTrue);
  });

  test('missing values are reported', () {
    const config = AppConfig(supabaseUrl: '', supabaseAnonKey: ' ');
    expect(config.isComplete, isFalse);
    expect(config.problems, hasLength(2));
  });

  test('non-https url is rejected', () {
    const config = AppConfig(
      supabaseUrl: 'http://abc.supabase.co',
      supabaseAnonKey: 'key',
    );
    expect(config.problems.single, contains('https'));
  });

  test('no dart-define in tests means setup is needed', () {
    expect(AppConfig.fromEnvironment().isComplete, isFalse);
  });
}

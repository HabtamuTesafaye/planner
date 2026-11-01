import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:planner/core/utils/dates.dart';
import 'package:planner/data/app_exception.dart';
import 'package:planner/data/repositories/time_repository.dart';
import 'package:planner/features/today/providers/today_providers.dart';

class MockTime extends Mock implements TimeRepository {}

ProviderContainer _container(TimeRepository time) {
  final c = ProviderContainer(
    overrides: [timeRepositoryProvider.overrideWithValue(time)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('a phone two days behind still plans on the real today', () async {
    final time = MockTime();
    final real = DateTime.now().add(const Duration(days: 2));
    when(time.serverNow).thenAnswer((_) async => real);
    final c = _container(time);
    await c.read(serverClockProvider.notifier).sync();
    expect(c.read(todayProvider), Dates.dateOnly(real));
  });

  test('a few seconds of difference is ignored (network noise)', () async {
    final time = MockTime();
    when(
      time.serverNow,
    ).thenAnswer((_) async => DateTime.now().add(const Duration(seconds: 3)));
    final c = _container(time);
    await c.read(serverClockProvider.notifier).sync();
    expect(c.read(serverClockProvider), Duration.zero);
  });

  test('offline: the last known difference stays, no crash', () async {
    final time = MockTime();
    final real = DateTime.now().add(const Duration(hours: 5));
    when(time.serverNow).thenAnswer((_) async => real);
    final c = _container(time);
    await c.read(serverClockProvider.notifier).sync();
    final known = c.read(serverClockProvider);
    when(time.serverNow).thenThrow(const AppException(AppErrorKind.network));
    await c.read(serverClockProvider.notifier).sync();
    expect(c.read(serverClockProvider), known);
    expect(known.inMinutes, closeTo(300, 1));
  });

  test('a wrong date from the database gets a clear message', () {
    expect(
      const AppException(AppErrorKind.wrongDate).message,
      contains('automatic date and time'),
    );
  });
}

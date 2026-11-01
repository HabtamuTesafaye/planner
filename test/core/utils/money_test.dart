import 'package:flutter_test/flutter_test.dart';
import 'package:planner/core/utils/money.dart';

void main() {
  group('ETB formatting', () {
    test('thousands separator, no decimals when whole', () {
      expect(Money.etb(12500), '12,500 ETB');
      expect(Money.etb(0), '0 ETB');
      expect(Money.etb(1250000), '1,250,000 ETB');
    });

    test('two decimals only when needed', () {
      expect(Money.etb(12500.5), '12,500.50 ETB');
      expect(Money.etb(99.99), '99.99 ETB');
    });

    test('floating point noise is rounded away', () {
      expect(Money.etb(0.1 + 0.2), '0.30 ETB');
      expect(Money.etb(100.0000001), '100 ETB');
    });
  });

  group('parsing what people type', () {
    test('accepts plain, comma and space separated numbers', () {
      expect(Money.parsePositive('12500'), 12500);
      expect(Money.parsePositive('12,500'), 12500);
      expect(Money.parsePositive('12 500.5'), 12500.5);
      expect(Money.parsePositive('300 ETB'), 300);
    });

    test('rejects zero, negatives, letters and too many decimals', () {
      expect(Money.parsePositive('0'), isNull);
      expect(Money.parsePositive('-5'), isNull);
      expect(Money.parsePositive('abc'), isNull);
      expect(Money.parsePositive('1.234'), isNull);
      expect(Money.parsePositive(''), isNull);
    });
  });
}

import 'package:intl/intl.dart';

/// Ethiopian Birr formatting: `12,500 ETB`, decimals only when needed
/// (`12,500.50 ETB`).
abstract final class Money {
  static const String currency = 'ETB';
  static final NumberFormat _whole = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _cents = NumberFormat('#,##0.00', 'en_US');

  /// Number only, no currency: `12,500` or `12,500.50`.
  static String amount(num value) {
    final rounded = (value * 100).round() / 100;
    return rounded == rounded.roundToDouble()
        ? _whole.format(rounded)
        : _cents.format(rounded);
  }

  /// `12,500 ETB`
  static String etb(num value) => '${amount(value)} $currency';

  /// Parses what people type: `12500`, `12,500`, `12 500.5`. Returns null
  /// when it is not a number above zero with at most two decimals.
  static double? parsePositive(String input) {
    final cleaned = input
        .replaceAll(RegExp(r'[,\s]'), '')
        .replaceAll('ETB', '');
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(cleaned)) return null;
    final value = double.tryParse(cleaned);
    if (value == null || value <= 0 || value >= 10000000000) return null;
    return value;
  }
}

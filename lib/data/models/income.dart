import 'package:flutter/foundation.dart';

import '../../core/utils/dates.dart';

/// Amounts are kept as whole cents (int) so sums never pick up floating
/// point errors. The database column is numeric(12,2).
int centsFromJson(Object? value) {
  // numeric(12,2) stays far below 2^53 cents, so rounding is exact.
  if (value is num) return (value * 100).round();
  if (value is String) return ((double.tryParse(value) ?? 0) * 100).round();
  return 0;
}

/// Exact decimal string for the database (`12500.50`).
String centsToDb(int cents) =>
    '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';

/// One income entry in a space, counted in [month] (its first day).
@immutable
class IncomeEntry {
  const IncomeEntry({
    required this.id,
    required this.spaceId,
    required this.userId,
    required this.month,
    required this.cents,
    required this.note,
    required this.createdAt,
    this.source = '',
  });

  factory IncomeEntry.fromJson(Map<String, dynamic> json) => IncomeEntry(
    id: json['id'] as String,
    spaceId: json['team_id'] as String,
    userId: json['user_id'] as String?,
    month: Dates.fromDb(json['month'] as String),
    cents: centsFromJson(json['amount']),
    note: json['note'] as String? ?? '',
    source: json['source'] as String? ?? '',
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
  );

  static const int maxNote = 200;
  static const int maxSource = 60;

  final String id;
  final String spaceId;
  final String? userId;
  final DateTime month;
  final int cents;
  final String note;

  /// Where it came from ("Salary", "Café client"); empty when not given.
  final String source;
  final DateTime createdAt;

  double get amount => cents / 100;

  Map<String, dynamic> toInsertJson() => {
    'id': id,
    'team_id': spaceId,
    'user_id': userId,
    'month': Dates.toDb(month),
    'amount': centsToDb(cents),
    'note': note.trim(),
    'source': source.trim(),
  };

  @override
  bool operator ==(Object other) =>
      other is IncomeEntry &&
      other.id == id &&
      other.month == month &&
      other.cents == cents &&
      other.note == note &&
      other.source == source;

  @override
  int get hashCode => Object.hash(id, month, cents, note, source);
}

/// The income target of a space for one month.
@immutable
class MonthlyTarget {
  const MonthlyTarget({
    required this.spaceId,
    required this.month,
    required this.cents,
  });

  factory MonthlyTarget.fromJson(Map<String, dynamic> json) => MonthlyTarget(
    spaceId: json['team_id'] as String,
    month: Dates.fromDb(json['month'] as String),
    cents: centsFromJson(json['target']),
  );

  final String spaceId;
  final DateTime month;
  final int cents;

  Map<String, dynamic> toJson() => {
    'team_id': spaceId,
    'month': Dates.toDb(month),
    'target': centsToDb(cents),
  };
}

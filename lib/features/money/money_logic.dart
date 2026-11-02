import '../../core/utils/dates.dart';
import '../../data/models/income.dart';

/// The month an entry made at [moment] belongs to (its first day). The
/// 31st at 23:59 is still that month; the 1st at 00:00 is the next.
DateTime monthOf(DateTime moment) => Dates.monthStart(moment);

/// Total of [month] in cents (exact integer sum).
int monthTotal(Iterable<IncomeEntry> entries, DateTime month) {
  final m = Dates.monthStart(month);
  return entries.where((e) => e.month == m).fold(0, (sum, e) => sum + e.cents);
}

/// Totals of every month before [current], newest first.
List<({DateTime month, int cents})> previousMonths(
  Iterable<IncomeEntry> entries,
  DateTime current,
) {
  final m = Dates.monthStart(current);
  final totals = <DateTime, int>{};
  for (final e in entries) {
    if (e.month.isBefore(m)) totals[e.month] = (totals[e.month] ?? 0) + e.cents;
  }
  final months = totals.keys.toList()..sort((a, b) => b.compareTo(a));
  return [for (final month in months) (month: month, cents: totals[month]!)];
}

/// Entries of [month], newest first.
List<IncomeEntry> entriesOf(Iterable<IncomeEntry> entries, DateTime month) {
  final m = Dates.monthStart(month);
  return entries.where((e) => e.month == m).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

/// Progress toward the target, 0..1+ (0 without a target).
double targetProgress(int totalCents, int? targetCents) =>
    targetCents == null || targetCents <= 0 ? 0 : totalCents / targetCents;

/// Sources used before in this space, most recent first, for one-tap reuse.
List<String> knownSources(Iterable<IncomeEntry> entries, {int limit = 8}) {
  final sorted = entries.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final seen = <String>{};
  final out = <String>[];
  for (final e in sorted) {
    final s = e.source.trim();
    if (s.isEmpty || !seen.add(s.toLowerCase())) continue;
    out.add(s);
    if (out.length == limit) break;
  }
  return out;
}

/// Label for entries without a source in the breakdown.
const String otherSource = 'Other';

/// Totals per source for [entries] (one month), largest first. Sources that
/// differ only in case count as one.
List<({String label, int cents})> totalsBySource(
  Iterable<IncomeEntry> entries,
) {
  final labels = <String, String>{};
  final cents = <String, int>{};
  for (final e in entries) {
    final label = e.source.trim().isEmpty ? otherSource : e.source.trim();
    final key = label.toLowerCase();
    labels.putIfAbsent(key, () => label);
    cents[key] = (cents[key] ?? 0) + e.cents;
  }
  final rows = [
    for (final k in cents.keys) (label: labels[k]!, cents: cents[k]!),
  ]..sort((a, b) => b.cents.compareTo(a.cents));
  return rows;
}

/// Date helpers. All work on local calendar dates (no time of day).
/// Weeks start on Monday (AGENTS.md section 2).
abstract final class Dates {
  /// The calendar date of [moment] (midnight, local).
  static DateTime dateOnly(DateTime moment) =>
      DateTime(moment.year, moment.month, moment.day);

  /// Monday of the week containing [day].
  static DateTime weekStart(DateTime day) {
    final d = dateOnly(day);
    return DateTime(d.year, d.month, d.day - (d.weekday - DateTime.monday));
  }

  /// Sunday of the week containing [day].
  static DateTime weekEnd(DateTime day) {
    final start = weekStart(day);
    return DateTime(start.year, start.month, start.day + 6);
  }

  /// First day of the month containing [day].
  static DateTime monthStart(DateTime day) => DateTime(day.year, day.month);

  /// First day of the month before [month]'s month (handles January).
  static DateTime previousMonth(DateTime month) =>
      DateTime(month.year, month.month - 1);

  /// First day of the month after [month]'s month (handles December).
  static DateTime nextMonth(DateTime month) =>
      DateTime(month.year, month.month + 1);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Whole days from [from] to [to] (negative if [to] is earlier).
  /// Uses calendar dates, so daylight-saving changes don't matter.
  static int daysBetween(DateTime from, DateTime to) {
    final a = DateTime.utc(from.year, from.month, from.day);
    final b = DateTime.utc(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  /// `yyyy-MM-dd` for Postgres `date` columns.
  static String toDb(DateTime day) {
    final d = dateOnly(day);
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  /// Parses a Postgres `date` (`yyyy-MM-dd`) as a local calendar date.
  static DateTime fromDb(String value) {
    final parts = value.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }
}

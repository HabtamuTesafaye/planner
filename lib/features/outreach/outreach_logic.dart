import 'package:intl/intl.dart';

import '../../core/utils/dates.dart';
import '../../data/models/contact.dart';

/// Pipeline order: overdue follow-ups first (most overdue on top), then the
/// soonest upcoming, then leads with no date (newest activity first).
/// Closed leads (paid, not now) go to the end.
List<Contact> sortContacts(Iterable<Contact> contacts) {
  int rank(Contact c) =>
      c.status.isClosed ? 2 : (c.nextFollowUp == null ? 1 : 0);
  return contacts.toList()..sort((a, b) {
    final r = rank(a).compareTo(rank(b));
    if (r != 0) return r;
    final da = a.nextFollowUp;
    final db = b.nextFollowUp;
    if (da != null && db != null && da != db) return da.compareTo(db);
    return b.updatedAt.compareTo(a.updatedAt);
  });
}

/// Is the follow-up date before [today]? Closed leads are never overdue.
bool isOverdue(Contact c, DateTime today) =>
    !c.status.isClosed &&
    c.nextFollowUp != null &&
    Dates.daysBetween(today, c.nextFollowUp!) < 0;

/// Plain words for a follow-up date: "3 days overdue", "Today",
/// "Tomorrow", "In 4 days", or the date for anything further away.
String followUpText(DateTime date, DateTime today) {
  final days = Dates.daysBetween(today, date);
  if (days < -1) return '${-days} days overdue';
  if (days == -1) return '1 day overdue';
  if (days == 0) return 'Today';
  if (days == 1) return 'Tomorrow';
  if (days < 7) return 'In $days days';
  return DateFormat.MMMd().format(date);
}

/// Which leads to show.
class OutreachFilter {
  const OutreachFilter({this.status, this.mineOnly = false});

  /// Null shows every status.
  final ContactStatus? status;
  final bool mineOnly;

  OutreachFilter copyWith({
    ContactStatus? Function()? status,
    bool? mineOnly,
  }) => OutreachFilter(
    status: status == null ? this.status : status(),
    mineOnly: mineOnly ?? this.mineOnly,
  );

  bool matches(Contact c, String? myUserId) =>
      (status == null || c.status == status) &&
      (!mineOnly || c.ownerId == myUserId);

  @override
  bool operator ==(Object other) =>
      other is OutreachFilter &&
      other.status == status &&
      other.mineOnly == mineOnly;

  @override
  int get hashCode => Object.hash(status, mineOnly);
}

/// Filtered and sorted, ready to show.
List<Contact> visibleContacts(
  Iterable<Contact> all,
  OutreachFilter filter,
  String? myUserId,
) => sortContacts(all.where((c) => filter.matches(c, myUserId)));

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner/data/models/contact.dart';
import 'package:planner/data/models/profile.dart';
import 'package:planner/data/models/space.dart';
import 'package:planner/features/auth/providers/auth_providers.dart';
import 'package:planner/features/outreach/outreach_logic.dart';
import 'package:planner/features/outreach/providers/outreach_providers.dart';
import 'package:planner/features/outreach/screens/outreach_screen.dart';
import 'package:planner/features/space/providers/space_providers.dart';
import 'package:planner/features/today/providers/today_providers.dart';

import '../../helpers.dart';

final _today = DateTime(2026, 11, 10);

Contact contact(
  String id, {
  DateTime? followUp,
  ContactStatus status = ContactStatus.contacted,
  String owner = 'u1',
  int updatedMinute = 0,
}) => Contact(
  id: id,
  spaceId: 's1',
  ownerId: owner,
  name: 'Lead $id',
  status: status,
  nextFollowUp: followUp,
  createdAt: DateTime(2026, 11),
  updatedAt: DateTime(2026, 11, 1, 9, updatedMinute),
);

void main() {
  group('sort order', () {
    test('overdue first, then soonest, then no date, closed last', () {
      final sorted = sortContacts([
        contact('none'),
        contact('later', followUp: DateTime(2026, 11, 20)),
        contact(
          'paid',
          followUp: DateTime(2026, 11),
          status: ContactStatus.paid,
        ),
        contact('overdue3', followUp: DateTime(2026, 11, 7)),
        contact('soon', followUp: DateTime(2026, 11, 11)),
        contact('overdue1', followUp: DateTime(2026, 11, 9)),
      ]);
      expect(sorted.map((c) => c.id), [
        'overdue3',
        'overdue1',
        'soon',
        'later',
        'none',
        'paid',
      ]);
    });

    test('leads without a date: most recently updated first', () {
      final sorted = sortContacts([
        contact('old', updatedMinute: 1),
        contact('new', updatedMinute: 9),
      ]);
      expect(sorted.first.id, 'new');
    });
  });

  group('follow-up words', () {
    test('overdue, today, tomorrow, soon, far away', () {
      expect(followUpText(DateTime(2026, 11, 7), _today), '3 days overdue');
      expect(followUpText(DateTime(2026, 11, 9), _today), '1 day overdue');
      expect(followUpText(_today, _today), 'Today');
      expect(followUpText(DateTime(2026, 11, 11), _today), 'Tomorrow');
      expect(followUpText(DateTime(2026, 11, 14), _today), 'In 4 days');
      expect(followUpText(DateTime(2026, 12, 25), _today), 'Dec 25');
    });

    test('overdue only for open leads with a past date', () {
      expect(
        isOverdue(contact('a', followUp: DateTime(2026, 11, 9)), _today),
        isTrue,
      );
      expect(isOverdue(contact('b', followUp: _today), _today), isFalse);
      expect(
        isOverdue(
          contact(
            'c',
            followUp: DateTime(2026, 11),
            status: ContactStatus.dead,
          ),
          _today,
        ),
        isFalse,
      );
      expect(isOverdue(contact('d'), _today), isFalse);
    });
  });

  group('filters', () {
    final all = [
      contact('a'),
      contact('b', status: ContactStatus.meeting),
      contact('c', owner: 'u2', status: ContactStatus.meeting),
    ];

    test('by status', () {
      final r = visibleContacts(
        all,
        const OutreachFilter(status: ContactStatus.meeting),
        'u1',
      );
      expect(r.map((c) => c.id).toSet(), {'b', 'c'});
    });

    test('mine only', () {
      final r = visibleContacts(
        all,
        const OutreachFilter(mineOnly: true),
        'u1',
      );
      expect(r.map((c) => c.id).toSet(), {'a', 'b'});
    });

    test('both together', () {
      final r = visibleContacts(
        all,
        const OutreachFilter(status: ContactStatus.meeting, mineOnly: true),
        'u1',
      );
      expect(r.single.id, 'b');
    });
  });

  for (final brightness in Brightness.values) {
    testWidgets('outreach list fits a small phone at 1.5x ($brightness)', (
      tester,
    ) async {
      useSmallPhone(tester, brightness: brightness);
      await pumpScreen(
        tester,
        const OutreachScreen(),
        overrides: [
          currentUserIdProvider.overrideWith((ref) => Stream.value('u1')),
          currentProfileProvider.overrideWith(
            (ref) async => const Profile(id: 'u1', displayName: 'Abebe'),
          ),
          mySpacesProvider.overrideWith(
            (ref) async => [
              Space(
                id: 's1',
                name: 'Personal',
                kind: SpaceKind.personal,
                joinCode: null,
                createdAt: DateTime(2026),
              ),
            ],
          ),
          contactsProvider.overrideWith(
            (ref) => Stream.value([
              contact('a', followUp: DateTime(2026, 11, 7)),
              contact('b', followUp: DateTime(2026, 11, 12)),
            ]),
          ),
          clockProvider.overrideWithValue(() => _today),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text('3 days overdue'), findsOneWidget);
      expect(find.text('In 2 days'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

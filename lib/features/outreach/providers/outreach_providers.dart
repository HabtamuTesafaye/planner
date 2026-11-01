import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/contact.dart';
import '../../../data/repositories/contacts_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../space/providers/space_providers.dart';
import '../outreach_logic.dart';

/// Live contacts of the current space.
final contactsProvider = StreamProvider<List<Contact>>((ref) {
  final space = ref.watch(currentSpaceProvider);
  if (space == null) return Stream.value(const []);
  return ref.watch(contactsRepositoryProvider).watchContacts(space.id);
});

class OutreachFilterNotifier extends Notifier<OutreachFilter> {
  @override
  OutreachFilter build() {
    // A different space starts with every lead visible.
    ref.watch(currentSpaceProvider.select((s) => s?.id));
    return const OutreachFilter();
  }

  void setStatus(ContactStatus? status) =>
      state = state.copyWith(status: () => status);

  void setMineOnly({required bool mineOnly}) =>
      state = state.copyWith(mineOnly: mineOnly);
}

final outreachFilterProvider =
    NotifierProvider<OutreachFilterNotifier, OutreachFilter>(
      OutreachFilterNotifier.new,
    );

/// Filtered and sorted contacts to show.
final visibleContactsProvider = Provider<AsyncValue<List<Contact>>>((ref) {
  final filter = ref.watch(outreachFilterProvider);
  final me = ref.watch(currentUserIdProvider).value;
  return ref
      .watch(contactsProvider)
      .whenData((all) => visibleContacts(all, filter, me));
});

/// Member id → name in the current space (for "who owns it").
final memberNamesProvider = Provider<Map<String, String>>((ref) {
  final members = ref.watch(spaceMembersProvider).value ?? const [];
  return {for (final m in members) m.userId: m.displayName};
});

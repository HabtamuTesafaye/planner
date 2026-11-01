import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/logger.dart';
import '../../../data/app_exception.dart';
import '../../../data/models/space.dart';
import '../../../data/models/team_member.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/space_repository.dart';
import '../../auth/providers/auth_providers.dart';

enum SpacesStatus { loading, ready, error }

/// Every space the signed-in user belongs to, Personal first.
final mySpacesProvider = FutureProvider<List<Space>>((ref) async {
  final userId = ref.watch(currentUserIdProvider).value;
  if (userId == null) return const [];
  return ref.watch(spaceRepositoryProvider).fetchMySpaces(userId);
});

/// The space chosen in this session. Null until the user picks one; then
/// the profile's last choice (or Personal) is used.
class SelectedSpaceNotifier extends Notifier<String?> {
  @override
  String? build() {
    // A different user starts fresh.
    ref.watch(currentUserIdProvider);
    return null;
  }

  /// Switches space and remembers it on the profile (best effort).
  Future<void> select(String spaceId) async {
    state = spaceId;
    final userId = ref.read(currentUserIdProvider).value;
    if (userId == null) return;
    try {
      await ref.read(profileRepositoryProvider).setLastSpace(userId, spaceId);
    } on AppException catch (e, s) {
      // Not worth bothering the user: the switch still works this session.
      Log.error('Could not remember the selected space', e, s);
    }
  }
}

final selectedSpaceIdProvider =
    NotifierProvider<SelectedSpaceNotifier, String?>(SelectedSpaceNotifier.new);

/// The space the app is showing: the chosen one if the user is still in it,
/// otherwise the profile's last choice, otherwise Personal.
final currentSpaceProvider = Provider<Space?>((ref) {
  final spaces = ref.watch(mySpacesProvider).value;
  if (spaces == null || spaces.isEmpty) return null;
  final wanted =
      ref.watch(selectedSpaceIdProvider) ??
      ref.watch(currentProfileProvider).value?.lastSpaceId;
  return pickSpace(spaces, wanted);
});

/// [wanted] if present, else the personal space, else the first.
Space pickSpace(List<Space> spaces, String? wanted) {
  for (final s in spaces) {
    if (s.id == wanted) return s;
  }
  return spaces.firstWhere((s) => s.isPersonal, orElse: () => spaces.first);
}

/// Members of the current space, oldest first.
final spaceMembersProvider = FutureProvider<List<TeamMember>>((ref) async {
  final space = ref.watch(currentSpaceProvider);
  if (space == null) return const [];
  return ref.watch(spaceRepositoryProvider).fetchMembers(space.id);
});

/// Space state for routing. While the list reloads because the user
/// changed (`isReloading`), the previous user's spaces must not be trusted.
final spacesStatusProvider = Provider<SpacesStatus>((ref) {
  final spaces = ref.watch(mySpacesProvider);
  if (spaces.isReloading) return SpacesStatus.loading;
  if (spaces.hasValue) {
    // Everyone has a personal space; an empty list means it failed to load.
    return spaces.value!.isEmpty ? SpacesStatus.error : SpacesStatus.ready;
  }
  if (spaces.hasError) return SpacesStatus.error;
  return SpacesStatus.loading;
});

/// After creating or joining: reload the list and switch to the new space.
Future<void> refreshAndSelect(WidgetRef ref, String spaceId) async {
  ref.invalidate(mySpacesProvider);
  await ref.read(mySpacesProvider.future);
  await ref.read(selectedSpaceIdProvider.notifier).select(spaceId);
}

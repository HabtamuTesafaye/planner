import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/profile.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/profile_repository.dart';

enum AuthStatus { unknown, signedOut, signedIn }

/// The signed-in user's id, or null. Repeats are filtered out so token
/// refreshes do not rebuild everything.
final currentUserIdProvider = StreamProvider<String?>(
  (ref) => ref.watch(authRepositoryProvider).userIdChanges().distinct(),
);

/// Whether someone is signed in. `unknown` only for the first moments of
/// app start, before the stored session is read.
final authStatusProvider = Provider<AuthStatus>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (!userId.hasValue) {
    return userId.hasError ? AuthStatus.signedOut : AuthStatus.unknown;
  }
  return userId.value == null ? AuthStatus.signedOut : AuthStatus.signedIn;
});

/// The signed-in user's profile (display name).
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final userId = ref.watch(currentUserIdProvider).value;
  if (userId == null) return null;
  return ref.watch(profileRepositoryProvider).fetchProfile(userId);
});

/// True after the user opened a password-reset link, until they set a new
/// password. The router then shows the new-password screen.
class PasswordRecoveryNotifier extends Notifier<bool> {
  @override
  bool build() {
    final sub = ref
        .watch(authRepositoryProvider)
        .passwordRecoveries()
        .listen((_) => state = true);
    ref.onDispose(sub.cancel);
    return false;
  }

  void finish() => state = false;
}

final passwordRecoveryProvider =
    NotifierProvider<PasswordRecoveryNotifier, bool>(
      PasswordRecoveryNotifier.new,
    );

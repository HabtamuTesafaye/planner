import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/logger.dart';
import '../app_exception.dart';
import '../supabase_client.dart';

/// Result of a sign-up. With email confirmation on, there is no session
/// until the user taps the link in their email.
enum SignUpOutcome { signedIn, confirmEmail }

/// Accounts and sessions. Session persistence is handled by
/// supabase_flutter; nothing is stored here.
class AuthRepository {
  const AuthRepository(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  /// The signed-in user's id (null when signed out): the current value
  /// first, then every change. Token refreshes repeat the same id.
  Stream<String?> userIdChanges() async* {
    yield _auth.currentUser?.id;
    // A failed email link (for example, expired) arrives as an error event.
    // Log it and keep listening, so the sign-in state stays usable.
    yield* _auth.onAuthStateChange
        .handleError((Object e, StackTrace s) => Log.error('Auth event', e, s))
        .map((state) => state.session?.user.id);
  }

  Future<SignUpOutcome> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email.trim(),
        password: password,
        data: {'display_name': displayName.trim()},
        emailRedirectTo: AppConfig.authRedirectUrl,
      );
      // With confirmation on, an existing email returns a user with no
      // identities instead of an error.
      final identities = response.user?.identities;
      if (response.user != null && identities != null && identities.isEmpty) {
        throw const AppException(AppErrorKind.emailInUse);
      }
      return response.session == null
          ? SignUpOutcome.confirmEmail
          : SignUpOutcome.signedIn;
    } catch (e, s) {
      throw AppException.from(e, s);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithPassword(email: email.trim(), password: password);
    } catch (e, s) {
      throw AppException.from(e, s);
    }
  }

  /// Sends the confirmation email again.
  Future<void> resendConfirmation(String email) async {
    try {
      await _auth.resend(
        type: OtpType.signup,
        email: email.trim(),
        emailRedirectTo: AppConfig.authRedirectUrl,
      );
    } catch (e, s) {
      throw AppException.from(e, s);
    }
  }

  /// Signs out on this device. Works offline: the local session is always
  /// cleared even if the server can't be reached.
  Future<void> signOut() async {
    try {
      await _auth.signOut(); // Default scope is local (this device).
    } catch (e, s) {
      throw AppException.from(e, s);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);

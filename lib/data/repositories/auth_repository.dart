import 'dart:convert';
import 'dart:io';

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

  /// Whether Google sign-in is switched on for this Supabase project (public
  /// auth settings; no secrets involved). Unknown counts as off.
  Future<bool> isGoogleEnabled() async {
    final config = AppConfig.fromEnvironment();
    final http = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await http.getUrl(
        Uri.parse('${config.supabaseUrl}/auth/v1/settings'),
      );
      request.headers.set('apikey', config.supabaseAnonKey);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final external = json['external'] as Map<String, dynamic>? ?? const {};
      return external['google'] == true;
    } on Object catch (e, s) {
      Log.error('Could not read auth settings', e, s);
      return false;
    } finally {
      http.close();
    }
  }

  /// Opens Google sign-in in the browser. When it finishes, Google sends the
  /// user back to the app (deep link), and supabase_flutter completes the
  /// sign-in with PKCE; the router then moves on by itself.
  Future<void> signInWithGoogle() async {
    try {
      if (!await isGoogleEnabled()) {
        throw const AppException(AppErrorKind.googleNotSetUp);
      }
      await _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: AppConfig.authRedirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e, s) {
      throw AppException.from(e, s);
    }
  }

  /// Emails a reset link. The link opens the app (PKCE deep link) and
  /// signs the user in with a password-recovery event. The answer is the
  /// same whether or not the email has an account.
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: AppConfig.authRedirectUrl,
      );
    } catch (e, s) {
      throw AppException.from(e, s);
    }
  }

  /// Fires once the user has opened a reset link and is signed in for it.
  Stream<void> passwordRecoveries() => _auth.onAuthStateChange
      .handleError((Object e, StackTrace s) => Log.error('Auth event', e, s))
      .where((state) => state.event == AuthChangeEvent.passwordRecovery);

  /// Sets a new password for the signed-in user.
  Future<void> updatePassword(String password) async {
    try {
      await _auth.updateUser(UserAttributes(password: password));
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

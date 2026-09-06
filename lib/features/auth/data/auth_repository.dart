/// Auth data access. The only place in this feature that touches Supabase
/// (CLAUDE.md rule 1).
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/supabase/supabase_failure.dart';
import '../domain/app_user.dart';
import '../domain/profile.dart';

class AuthRepository {
  const AuthRepository(this._client);

  final SupabaseClient _client;

  /// The current user, synchronously.
  ///
  /// Available immediately after `Supabase.initialize` restores a stored
  /// session, which is what lets the router redirect without a loading flash
  /// on a warm start.
  AppUser? get currentUser => _toAppUser(_client.auth.currentUser);

  /// Emits the current user, then every subsequent change.
  ///
  /// The leading `yield` matters: a bare `onAuthStateChange` does not replay
  /// the restored session, so a listener subscribing after startup would sit
  /// on `null` until the next sign-in.
  Stream<AppUser?> watchAuthState() async* {
    yield currentUser;
    yield* _client.auth.onAuthStateChange
        .map((AuthState event) => _toAppUser(event.session?.user));
  }

  /// Sends a one-time code to [email].
  ///
  /// `shouldCreateUser` is left at its default: signing in and signing up are
  /// the same act for email OTP, and the `on_auth_user_created` trigger
  /// creates the profile row either way.
  Future<void> requestOtp(String email) => runGuarded(() async {
        await _client.auth.signInWithOtp(email: email.trim());
      });

  /// Exchanges [token] for a session.
  Future<AppUser> verifyOtp({
    required String email,
    required String token,
  }) =>
      runGuarded(() async {
        final AuthResponse response = await _client.auth.verifyOTP(
          email: email.trim(),
          token: token.trim(),
          type: OtpType.email,
        );
        final AppUser? user = _toAppUser(response.user);
        if (user == null) {
          throw const UnauthorizedFailure(
              message: 'That code was not accepted.');
        }
        return user;
      });

  Future<void> signOut() => runGuarded(() async {
        await _client.auth.signOut();
      });

  /// The caller's own profile row, or null if the trigger has not run yet.
  Future<Profile?> fetchOwnProfile() => runGuarded(() async {
        final String? id = _client.auth.currentUser?.id;
        if (id == null) return null;

        final Map<String, dynamic>? row = await _client
            .from('profiles')
            .select('id, display_name, locale')
            .eq('id', id)
            .maybeSingle();
        if (row == null) return null;

        return Profile(
          id: row['id'] as String,
          displayName: row['display_name'] as String,
          locale: AppLocale.fromCode(row['locale'] as String),
        );
      });

  AppUser? _toAppUser(User? user) {
    if (user == null) return null;
    return AppUser(id: user.id, email: user.email ?? '');
  }
}

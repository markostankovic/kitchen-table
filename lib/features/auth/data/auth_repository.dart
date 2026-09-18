/// Auth data access. The only place in this feature that touches Supabase
/// (CLAUDE.md rule 1).
///
/// `google_sign_in` is held to the same boundary: every `GoogleSignIn*` type,
/// `GoogleSignInException` included, is confined to this file, exactly as
/// `AuthException` is (`tool/check_layers.dart`).
library;

import 'dart:io' show Platform;

import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/env/google_auth.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/supabase/supabase_failure.dart';
import '../domain/app_user.dart';
import '../domain/profile.dart';

class AuthRepository {
  const AuthRepository(this._client);

  final SupabaseClient _client;

  /// Whether [GoogleSignIn.initialize] has already run in this process.
  ///
  /// Static because what it tracks is static: `GoogleSignIn.instance` is a
  /// process-wide singleton, so a flag on the repository instance would let a
  /// rebuilt `authRepositoryProvider` re-initialize an SDK that is already
  /// initialized. (It is `keepAlive`, so that does not happen today -- but the
  /// flag should describe the singleton, not the provider's lifetime.)
  ///
  /// Initialization is lazy rather than done at startup: the client IDs are
  /// compile-time constants, so there is nothing to await before the first
  /// frame, and a warm start that restores a stored session never wakes the
  /// native SDK at all.
  static bool _googleInitialized = false;

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

  /// Signs in with Google. Returns null when the user dismissed the chooser.
  ///
  /// Null rather than an [AppFailure] is deliberate: backing out of the
  /// account picker is not an error, and D92's vocabulary has no sentence for
  /// it that would not be a lie on screen.
  ///
  /// The native ID-token flow, not a browser redirect -- which is why neither
  /// platform registers a deep link and `site_url` is untouched. The token
  /// goes straight to GoTrue, which terminates it in an ordinary Supabase
  /// session; it reaches [watchAuthState] through `onAuthStateChange` like
  /// every other sign-in, so nothing downstream needed a change.
  ///
  /// No `authorizeScopes(['email', 'profile'])` call, which Supabase's own
  /// Flutter snippet has: it exists only to obtain an `accessToken`,
  /// `accessToken` is optional on `signInWithIdToken`, GoTrue validates the
  /// `idToken` by itself, and asking for it costs a second consent sheet on
  /// Android. (The same snippet uses `attemptLightweightAuthentication()`,
  /// which is the *silent* restore path and returns null when there is no
  /// session to restore -- wrong for a button press. [authenticate] is right.)
  ///
  /// `AppUser` models only `id` and `email`; Google's `full_name` and
  /// `avatar_url` land in `user_metadata` and are left unmodelled.
  Future<AppUser?> signInWithGoogle() => runGuarded(() async {
        await _ensureGoogleInitialized();
        try {
          final GoogleSignInAccount account =
              await GoogleSignIn.instance.authenticate();
          final String? idToken = account.authentication.idToken;
          if (idToken == null) {
            // Not reachable through any documented path -- `idToken` is
            // nullable on the token container only so the class can grow.
            throw const UnknownFailure(
                message: 'Google returned no ID token.',
                code: FailureCode.googleSignInFailed);
          }

          final AuthResponse response = await _client.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
          );
          return _toAppUser(response.user);
        } on GoogleSignInException catch (e) {
          if (e.code == GoogleSignInExceptionCode.canceled) return null;
          throw UnknownFailure(
              message: 'Google sign-in failed: ${e.code.name}.',
              code: FailureCode.googleSignInFailed,
              cause: e);
        }
      });

  /// Runs the plugin's one-shot `initialize()`, once.
  ///
  /// Android wants [GoogleAuth.serverClientId] alone -- the Android client is
  /// matched by package name and signing SHA-1 (D97), not by an ID passed
  /// here. iOS additionally needs its own `clientId`.
  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: GoogleAuth.serverClientId,
      clientId: Platform.isIOS ? GoogleAuth.iosClientId : null,
    );
    _googleInitialized = true;
  }

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

  /// Sets the caller's own preferred locale (D77).
  ///
  /// A plain update, the same shape as `RecipeRepository.update` -- the
  /// column's check constraint and the `profiles_update_own` RLS policy
  /// already exist (migration 2), so there is nothing to add server-side.
  /// `appLocaleProvider` (`core/l10n/app_locale.dart`) is what turns this
  /// write into the whole app re-rendering; the caller invalidates
  /// `ownProfileProvider` after a successful call.
  Future<void> updateLocale(AppLocale locale) => runGuarded(() async {
        final String? id = _client.auth.currentUser?.id;
        if (id == null) {
          throw const UnauthorizedFailure(
              message: 'You are not signed in any more.',
              code: FailureCode.signInAgain);
        }

        await _client
            .from('profiles')
            .update(<String, dynamic>{'locale': locale.code}).eq('id', id);
      });

  AppUser? _toAppUser(User? user) {
    if (user == null) return null;
    return AppUser(id: user.id, email: user.email ?? '');
  }
}

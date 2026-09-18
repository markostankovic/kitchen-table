/// Google OAuth client IDs (D96).
///
/// Committed constants rather than `env/*.json` keys, which is a deliberate
/// carve-out from D95's "env files carry only what differs between local and
/// hosted". These are neither secret nor environment-specific:
///
/// - Not secret. An OAuth *client ID* is public by construction -- it ships
///   inside every APK and is handed to Google in the clear on every sign-in.
///   What protects an Android client is the package name plus the registered
///   signing SHA-1, not the secrecy of this string. The web client *secret* is
///   the one thing here that is secret, and it is not in this file: it reaches
///   GoTrue only through `SUPABASE_AUTH_EXTERNAL_GOOGLE_SECRET` at
///   `make config-push` time.
///
/// - Not environment-specific. One Google Cloud project serves both the local
///   stack and the hosted one, so unlike `SUPABASE_URL` there is nothing here
///   for an env file to vary. Putting them in `env/*.json` would mean two
///   gitignored files that must be kept byte-identical -- a drift hazard in
///   exchange for no secrecy at all.
///
/// Pure Dart, like `env.dart` beside it.
///
/// Note what is *not* here: either Android client ID. A Google Cloud Android
/// OAuth client binds to one package name plus one signing SHA-1, so D97's two
/// keystores mean two separate clients -- and the app names neither of them.
/// Android authenticates by package + signature and asks for a token audienced
/// at [GoogleAuth.serverClientId]. The two Android IDs appear only in
/// `client_id` in `[auth.external.google]` (`supabase/config.toml`), so that
/// GoTrue accepts a token however the build was signed.
library;

abstract final class GoogleAuth {
  /// The Web OAuth client ID.
  ///
  /// Despite the name, this is what Android passes as `serverClientId`: it is
  /// the audience (`aud`) that Supabase validates the ID token against, and it
  /// must appear in `client_id` in `[auth.external.google]`
  /// (`supabase/config.toml`). Nothing web-facing uses it -- the app has no
  /// web target.
  static const String serverClientId =
      '170737862197-eml0dti7is91l4q43p1622aoa37qnqu5.apps.googleusercontent.com';

  /// The iOS OAuth client ID, bound to bundle id `com.kitchentable.kitchenTable`.
  ///
  /// Passed as `clientId` on iOS only; Android wants [serverClientId] alone.
  /// Registered now rather than in the iOS slice so that `client_id` in
  /// `config.toml` -- a single comma-separated list -- is written once, and
  /// `make config-push` with its magic-link comment-out dance (D95) is not
  /// repeated later just to append an ID.
  static const String iosClientId =
      '170737862197-2sgi0fe9f9pgilffv5bdiqqh79p91g3k.apps.googleusercontent.com';
}

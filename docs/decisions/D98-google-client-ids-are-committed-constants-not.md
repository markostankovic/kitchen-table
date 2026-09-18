# D98 — Google client IDs are committed constants, not `env/*.json` keys
**Status:** active
**Touches:** lib/core/env/google_auth.dart, supabase/config.toml, lib/features/auth/data/auth_repository.dart

**Decided.** The Google OAuth client IDs live in `lib/core/env/google_auth.dart`
as committed `const` strings, not in the gitignored `env/*.json` files beside
them. The web client ID (passed as `serverClientId`) and the iOS client ID are
the only two the app names; both Android client IDs appear nowhere in `lib/`,
only in `client_id` in `[auth.external.google]`. The web client *secret* is not
committed and is not in either place -- it reaches GoTrue solely through
`SUPABASE_AUTH_EXTERNAL_GOOGLE_SECRET` at `make config-push` time.

**Why.** This is the first real carve-out from D95's "env files carry only what
differs between local and hosted", and it earns it on both halves of that
sentence. Nothing here is secret: an OAuth client ID is public by construction,
shipped inside every APK and readable with `unzip`, and what actually protects
the Android clients is the package name plus the registered signing SHA-1 (D97),
not the secrecy of the string. Nothing here differs by environment either: one
Google Cloud project serves the local stack and the hosted one, so unlike
`SUPABASE_URL` there is nothing for an env file to vary. Putting them in
`env/*.json` would mean two gitignored files that must be kept byte-identical --
a drift hazard bought with no secrecy at all, and one that would bite on a fresh
clone where neither file exists yet.

**Rejected.** Adding them to `env/local.json` / `env/hosted.json` for uniformity
with `SUPABASE_URL` and the anon key. Uniformity is the whole argument for it,
and D95's rule is about what *differs*, not about where configuration lives in
general -- applying it to values that are identical everywhere turns one
committed fact into two uncommitted copies of it.

**Consequences.** Rotating a client ID is now a code change and a rebuild, not
an env-file edit -- correct, since the ID is compiled into the binary either
way. Registering the Android clients turned out to need **two** of them, not one
with two fingerprints: a Google Cloud Android OAuth client binds to one package
name plus exactly one SHA-1, so D97's upload and debug keystores are two
separate clients, and `client_id` is a four-entry list (web, Android-debug,
Android-upload, iOS). Dropping either Android entry breaks a specific build --
debug-only breaks `make install-hosted`, upload-only breaks `make run-android`.
The iOS client is registered and committed ahead of the iOS slice so that
appending it later does not mean a second `config push` and another
magic-link comment-out dance (D95).

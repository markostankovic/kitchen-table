# State — 2026-09-18

**Branch:** `main`
**Last shipped:** Phase 4 part 3 (`e10a66b`) — Google sign-in, proven
on the physical Galaxy S25 against hosted. Native `google_sign_in` v7 feeding
`signInWithIdToken` (no browser redirect, so no deep link on either platform
and `site_url` untouched); a Google button below the email form behind an
"ili" divider. An existing email-OTP user signing in with Google lands in
their **existing** household — the check that rested entirely on GoTrue
linking a provider-verified email, since `enable_manual_linking = false`.
Both Android OAuth clients work: release (upload key) and debug (debug key),
which is what actually proves D97's fallback. The bare `idToken` is accepted
without `authorizeScopes`, so there is no second consent sheet. Client IDs
are committed constants, not `env/*.json` keys (D98).
**In flight:** none
**Next:** Phase 4 Part 4 — remove email OTP, now that Part 3 is proven on
hosted. Then Part 5 (Apple sign-in); the shape D96 gave Phase 4 during part 1.
**Latest decision:** D98

**Sign-in works on hosted, both ways.** Google is live on the hosted project
(`[auth.external.google]`, pushed with `make config-push`). Email OTP still
has no working mail round trip and never will — a free tier project cannot
send a custom email template, so the message carries no code to type (D95) —
but `make otp EMAIL=...` still mints one with
`POST /auth/v1/admin/generate_link`, and that path is deliberately kept alive
until Part 4 deletes it (D96). Local sign-in is unaffected and works through
Mailpit.

**`make config-push` still needs the comment-out dance.** Comment
`[auth.email.template.magic_link]` out (`supabase/config.toml`) for the
duration of the push or the entire `[auth]` payload is rejected, then restore
it immediately — it is byte-identical in git, and leaving it commented kills
local email OTP. Part 4 is what retires this, by deleting the block and
`supabase/templates/magic_link.html` together.

**The emulator cannot verify Google sign-in.** An API 37 / Android 17 Play
image refuses to add a Google account at all ("Something went wrong",
`Accounts: 0`), with clock, network and Play Services versions all ruled out
— Google's device-integrity gating, not a configuration fault. Everything
short of the token exchange does work there, so it stays useful for UI work.
Sign-in itself needs the physical device.

**Known issue, not from this slice:** `make check` fails at `seed-check` and
has since `c8be2bc`. That commit edited one *comment* line in
`supabase/seeds/ingredients.csv`, and `catalogFingerprint()` hashes raw bytes,
so the guard fires on a byte-identical catalog (200 ingredients, 618 names).
Everything else in `make check` is green. Deliberately left for its own slice
— the candidate fix is fingerprinting the parsed rows rather than reverting a
correct comment or emitting a catalog migration for a typo.

**Not yet watched, from part 3:** a brand-new Google user landing on
`CreateHouseholdRoute` through `on_auth_user_created`. The trigger is
unchanged and fires on `auth.users` regardless of provider, but nobody has
seen it do so for a Google-created user. `display_name` will be the email
local-part when someone checks — `handle_new_user()` does
`split_part(new.email, '@', 1)` and ignores Google's `full_name`.

Update this file as the last step of closing a slice (`/close-slice`), not
mid-task. If it disagrees with `git log`, trust `git log` and fix this file.

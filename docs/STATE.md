# State — 2026-09-18

**Branch:** `main`
**Last shipped:** Phase 4 part 4 (`37a837f`) — email OTP removed, Google is
the only sign-in path. `requestOtp` / `verifyOtp`, the verify-code screen and
route, the email form and "ili" divider, the OTP ARB strings, and
`supabase/templates/magic_link.html` (with its `config.toml` block) are gone.
`FailureCode.codeNotAccepted` survives — both D96 and the old ROADMAP entry
were wrong to name it for deletion; it's still what invite redemption maps
three Edge Function slugs onto (D99). `[auth.email]` stays enabled
server-side, untouched. Verified on the physical Galaxy S25 against hosted: a
fresh release install, one Google button on the sign-in screen, and a tap
through the native account chooser landing straight in the existing
household — no verify-code screen anywhere in the flow.
**In flight:** none
**Next:** Phase 4 Part 5 — Apple sign-in, gated on App Store distribution
(Guideline 4.8). Needs a Sign in with Apple package — new third-party
dependency, ask first.
**Latest decision:** D99

**`make config-push` no longer needs the comment-out dance.** That was this
slice's whole operational point: with `[auth.email.template.magic_link]`
deleted, `supabase config push` carries the entire `[auth]` block in one
shot. D95's free-tier template limitation is now historical background in
`docs/ARCHITECTURE.md`, not a live constraint to route around.

**Local sign-in requires a device that can hold a Google account** (part 3's
finding, unchanged by part 4). The Android emulator cannot add a Google
account at all — Google's device-integrity gating, not a configuration
fault — so it stays useful for UI work and useless for exercising sign-in
itself. Local development lost Mailpit's frictionless email sign-in when OTP
went; there is no replacement UI, by design (D96) — a dev-only sign-in button
would have meant not actually deleting the code.

**Not yet watched:** a brand-new Google user landing on
`CreateHouseholdRoute` through `on_auth_user_created`, flagged since part 3.
The trigger is unchanged and fires on `auth.users` regardless of provider,
but no slice has watched it fire for a Google-created user yet.
`display_name` will be the email local-part when someone checks —
`handle_new_user()` does `split_part(new.email, '@', 1)` and ignores
Google's `full_name`.

**Known issue, not from this slice:** `make check` fails at `seed-check` and
has since `c8be2bc`. That commit edited one *comment* line in
`supabase/seeds/ingredients.csv`, and `catalogFingerprint()` hashes raw bytes,
so the guard fires on a byte-identical catalog (200 ingredients, 618 names).
Everything else in `make check` is green. Deliberately left for its own slice
— the candidate fix is fingerprinting the parsed rows rather than reverting a
correct comment or emitting a catalog migration for a typo.

Update this file as the last step of closing a slice (`/close-slice`), not
mid-task. If it disagrees with `git log`, trust `git log` and fix this file.

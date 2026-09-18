# State — 2026-09-18

**Branch:** `main`
**Last shipped:** Phase 4 part 2 (`cab2ee0`) — a signed release build,
walked end to end on a physical Galaxy S25 against the hosted project.
`android/key.properties` (gitignored, falls back to the debug keystore when
absent — D97) + `make install-hosted` build and install a release APK;
`make otp EMAIL=...` mints a hosted sign-in code. Real airplane mode on the
device confirmed the global offline banner, the shopping list's per-screen
"saved copy" line, and a write surfacing "Nema veze sa internetom." from a
genuine `SocketException` — closing the D92 on-device gap in
`docs/decisions/OPEN.md`. A Wi-Fi→cellular transition and an AI round trip
over cellular were also confirmed. Import-photo from a real camera was not
run (no physical recipe card on hand).
**In flight:** none
**Next:** Phase 4 Part 3 — Google sign-in. Then Part 4 (remove email OTP),
Part 5 (Apple sign-in); the shape D96 gave Phase 4 during part 1.
**Latest decision:** D97

**Known issue, not from this slice:** `make check` fails at `seed-check` and
has since `c8be2bc`. That commit edited one *comment* line in
`supabase/seeds/ingredients.csv`, and `catalogFingerprint()` hashes raw bytes,
so the guard fires on a byte-identical catalog (200 ingredients, 618 names).
Everything else in `make check` is green. Deliberately left for its own slice
— the candidate fix is fingerprinting the parsed rows rather than reverting a
correct comment or emitting a catalog migration for a typo.

**Hosted sign-in has no working email round trip and none is planned.** A
free tier project cannot send a custom email template, so the mail carries
no code to type (D95). Email OTP is being retired rather than repaired
(D96). Until Google sign-in (Part 3) lands, `make otp EMAIL=...` is how to
sign in — it mints a token with `POST /auth/v1/admin/generate_link` and
prints the `email_otp`. Local sign-in is unaffected and works through
Mailpit.

Update this file as the last step of closing a slice (`/close-slice`), not
mid-task. If it disagrees with `git log`, trust `git log` and fix this file.

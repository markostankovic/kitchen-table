# State — 2026-09-18

**Branch:** `main`
**Last shipped:** Phase 4 part 1 (`69c94ea`) — a real Supabase project. Hosted project
`cbajkezfhssrvbdbedqt` (West EU) carries all 18 migrations, the ingredient
catalog, `ANTHROPIC_API_KEY` and all seven Edge Functions; `env/hosted.json`
+ `make run-hosted` / `db-push` / `config-push`; `## Environments` in
`docs/ARCHITECTURE.md`. Verified end to end against the live project —
profile trigger, `create_household`, `create-invite`, and a real
`translate-recipe` call recorded in `ai_usage`.
**In flight:** none
**Next:** Phase 4 Part 2 — run on a real device against the hosted project.
Then Part 3 (Google sign-in), Part 4 (remove email OTP), Part 5 (Apple
sign-in); the last three are the shape D96 gave Phase 4 during part 1.
**Latest decision:** D96

**Known issue, not from this slice:** `make check` fails at `seed-check` and
has since `c8be2bc`. That commit edited one *comment* line in
`supabase/seeds/ingredients.csv`, and `catalogFingerprint()` hashes raw bytes,
so the guard fires on a byte-identical catalog (200 ingredients, 618 names).
Everything else in `make check` is green. Deliberately left for its own slice
— the candidate fix is fingerprinting the parsed rows rather than reverting a
correct comment or emitting a catalog migration for a typo.

**Hosted sign-in does not work and will not be fixed.** A free tier project
cannot send a custom email template, so the mail carries no code to type
(D95). Email OTP is being retired rather than repaired (D96). To exercise
hosted auth before Google lands, mint a token with
`POST /auth/v1/admin/generate_link` and feed its `email_otp` to
`/auth/v1/verify`. Local sign-in is unaffected and works through Mailpit.

Update this file as the last step of closing a slice (`/close-slice`), not
mid-task. If it disagrees with `git log`, trust `git log` and fix this file.

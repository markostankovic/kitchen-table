# Journal — Phase 4

Verbatim build history for Phase 4 — Going real: a real backend, a real phone, a real sign-in, moved out of `docs/ROADMAP.md` so the roadmap stays a forward-looking index. Nothing here is authoritative going forward -- see `docs/decisions/` for standing rules, `docs/STATE.md` for current status.

---

## Phase 4 — Going real: a real backend, a real phone, a real sign-in

### Part 1 — A real Supabase project

**Status: complete.** Decisions taken during it: D95–D96. The part shipped
narrower than planned and ended by cancelling a chunk of Phase 4 -- see
"What the plan got wrong" below.

A hosted Supabase project now exists and carries the whole backend. The org
`markostankovic's Org` was at the free tier's two-project ceiling, so the
project lives in a second free org, `Kitchen Table`
(`gsxjaghlqkqpvkjpadcm`); free-tier limits are per-org, and nothing in the
original org was touched.

- Project `kitchen-table`, ref `cbajkezfhssrvbdbedqt`, West EU (Ireland),
  matching the two existing projects. DB password generated at creation,
  shown once, and saved only to the user's password manager -- the CLI
  stores it nowhere (`supabase/.temp/` holds version metadata and the
  project ref; the `Supabase CLI` keychain item is the access token). If it
  is ever lost the dashboard resets it; nothing in the repo depends on it.
- All 18 migrations applied with `supabase db push`, `20260904210716_init`
  through `20260913220000_review_recipe_translation`, verified as 18/18 on
  both sides by `supabase migration list --linked`. The ingredient catalog
  arrived with them -- 200 keyed ingredients, 618 curated names, seeded by
  migration rather than `seed.sql` exactly as D29 argued it would have to
  be. No extension surprises (D19's hand-rolled `normalize_text` needs
  none).
- `ANTHROPIC_API_KEY` set as the only Edge Function secret; `supabase
  secrets list` shows one digest. The `SUPABASE_*` prefix is reserved and
  injected by the platform, so nothing else needed setting.
- All seven Edge Functions deployed.
- `env/hosted.json` (gitignored, anon key only) + `env/hosted.example.json`
  (committed, placeholders), mirroring `env/android.example.json`'s shape
  including the leading `_comment`.
- `Makefile`: `run-hosted`, `db-push`, `config-push`, each with the `## `
  help text `make help` greps for and the explanatory `#` comment
  `run-android` set the precedent for.
- `supabase/templates/magic_link.html` + `[auth.email.template.magic_link]`
  -- a `{{ .Token }}` email, Serbian above English, inline styles. It works
  locally and cannot be pushed; see below.
- `[remotes.hosted]` in `config.toml`. CLI 2.84.2 does support remote
  overrides -- established rather than assumed, by appending a bogus block
  and confirming the parser is strict (`'config.config' has invalid keys`)
  before trusting that `[remotes.hosted]` parsed because it is real. It
  holds `max_frequency` at `1m0s` on hosted while local keeps `1s`:
  `[auth.rate_limit] email_sent` is 2 per hour, so a double-tapped "Send a
  new code" at a 1-second window burns the hour's budget in two seconds.
- `docs/ARCHITECTURE.md` gains `## Environments (Phase 4)`; `core/env/
  env.dart`'s doc comment and `assertConfigured()` message both name
  `env/hosted.json` and cite D95.

**What the plan got wrong.** Two of the slice plan's stated facts were
false, and both were load-bearing.

The plan's "one real technical risk" was that hosted's stock magic-link
template carries only `{{ .ConfirmationURL }}`, which is true -- but it
assumed the fix was to ship a template in git and push it. A free tier
project on the built-in email sender rejects *any* email template, and the
CLI sends `[auth]` as one payload, so a single template block fails the
whole push:

    Email template modification is not available for free tier projects
    using the default email provider

Nothing lands -- not `otp_length`, not `site_url`, not an external provider.
Confirmed atomically: after the rejection, hosted still minted 8-character
codes. With the block commented out the identical push succeeded and hosted
began minting 6. So the template is the *only* thing that cannot cross to
hosted, and it blocks everything else from crossing with it.

The plan also stated that local GoTrue's default template includes the
token, "which is why Mailpit has always shown a code". It does not. With
the block commented out, the local mail is the same stock "Your sign-in
link" with no code anywhere, and local sign-in is dead. The template is
what makes local development possible, not a nicety -- so it stays on
locally and is commented out for the duration of a `config push`.

**How it was verified.** Hosted email sign-in cannot work, so the mail was
taken out of the loop: `POST /auth/v1/admin/generate_link` mints a token
directly, and its `email_otp` feeds `/auth/v1/verify` -- the same call
`auth_repository.dart` makes. Against the live project, in order:

- `verifyOTP` returned a session
- `on_auth_user_created` had created the profile row, `locale: "sr"`
- `create_household` RPC created a household that read back through RLS
  with `deleted_at: null` (a direct `INSERT` into `households` correctly
  fails RLS -- the RPC exists because neither table has an insert policy)
- `create-invite` returned a real invite with a 7-day expiry, proving JWT
  verification plus service-role access with no AI cost
- `translate-recipe` translated "Palačinke" → "Pancakes" and "Tanke
  palačinke sa džemom." → "Thin pancakes with jam.", with `ai_usage`
  recording `claude-opus-5`, 965 input / 319 output tokens -- proof the
  deployed function reached `ANTHROPIC_API_KEY`

The first `translate-recipe` attempt failed its step-alignment guard
because the test data used 1-based step positions; `save_imported_recipe`
assigns `(ord - 1)`, so `recipe_steps.position` is 0-based. Test data, not
a bug, but worth the note -- the guard's message names neither convention.

Local was confirmed unbroken at each stage: `supabase stop && start && db
reset` clean with the new template block, all 18 migrations replaying, and
a Mailpit message showing a readable 6-digit code in both language halves
with diacritics intact.

**Done when:** the plan said "prove email OTP sign-in works end-to-end
against a real inbox". -- **Not met, and withdrawn rather than deferred.**
Meeting it needs custom SMTP (a new third-party service, CLAUDE.md rule 8)
or a paid plan. Presented with that, the decision was to stop paying for
email at all: **email OTP is retired in favour of Google sign-in** (D96).
The real-inbox criterion therefore describes a feature that will not exist,
so Part 1 is recorded as complete on what it did deliver -- the hosted
backend, verified end to end by every path that does not go through the
mail -- rather than left open against a goal that was cancelled.

`make check` is clean apart from `seed-check`, which has been red on `main`
since `c8be2bc` for reasons unrelated to this part: that commit edited one
*comment* line in `supabase/seeds/ingredients.csv` ("Phase 4" → "Phase 5"),
and `catalogFingerprint()` hashes raw bytes, comments included, so the
drift guard fires on a byte-identical catalog. Confirmed by restoring the
pre-`c8be2bc` CSV and watching the check pass. Deliberately left for its
own slice rather than fixed here by reverting a correct comment, emitting
an ~800-line catalog migration for a typo, or changing the guard's
semantics mid-slice.

**Left on hosted:** smoke-test rows from the verification above -- two
`@kitchen-table.test` users, a "Hosted smoke test" household, a Palačinke
recipe and one invite. Household-scoped, so invisible to a real account.

---

### Part 2 — Run on a real device

**Status: complete.** Decisions taken during it: D97. Closes the D92
on-device gap named in `docs/decisions/OPEN.md`.

The app now runs as a signed release build on a physical Galaxy S25
(`RFCY61SRQ3B`, Android 16 / API 36) against the hosted project from part 1,
survives the USB cable coming out, and was walked through a real
airplane-mode cycle -- the thing an emulator cannot do at all.

- **Two unmodified Flutter-template leftovers, both release-only.**
  `INTERNET` was declared in the debug and profile manifests -- for the
  Flutter tool's own hot-reload use -- but never in
  `android/app/src/main/AndroidManifest.xml`, the one a release APK actually
  merges. A release build ran and looked healthy, with every Supabase call
  silently failing behind an offline banner stuck up over full signal bars.
  Fixed by declaring the permission in the main manifest.
  `android/app/build.gradle.kts` still carried both stock template TODOs;
  the `applicationId` TODO comment is gone (the value is unchanged -- it is
  load-bearing elsewhere), and release signing is D97.
- **`make otp EMAIL=...`** mints a 6-digit sign-in code via
  `POST /auth/v1/admin/generate_link`, reading `SUPABASE_SERVICE_ROLE_KEY`
  from the environment and never writing it to a file -- the only way to
  sign into the app on a device now that hosted email OTP delivers no code
  (D96). The slice plan assumed the response nests `email_otp` under
  `properties`; the live response carries it at the top level instead,
  caught and fixed during the walk (the Makefile checks both shapes).
- **`make install-hosted`** builds a release APK against `env/hosted.json`
  and installs it on whatever device `adb` sees attached.

**How it was verified.** The full walk ran on the S25 over its own Wi-Fi and
carrier radio, cable unplugged for the offline steps:

- Release install launches, no crash.
- Signed in with a `make otp` code; a fresh household was created through
  `on_auth_user_created` / `create_household`, confirming the device and the
  build rather than re-proving the backend, which part 1 already verified.
- Online baseline: recipe list loads from hosted, no banner.
- Real airplane mode (both radios actually down, not a Settings toggle
  alone -- see D92's `OPEN.md` entry for the exact commands): the global
  banner and the shopping list's narrower "saved copy" line both appeared,
  and saving a new recipe surfaced **"Nema veze sa internetom."** -- a real
  `SocketException` reaching the screen as the written failure sentence.
- Reconnected: the banner cleared on the next successful read, not on the
  radio event itself, exactly as `network_status.dart`'s header comment
  says it should.
- A genuine Wi-Fi→cellular transition (Wi-Fi off, data left on) -- the case
  an emulator cannot produce -- worked with no visible seam.
- One AI round trip over cellular: a short ingredient line pasted through
  "Nalepi recept" was parsed by `import-text` and matched to "brašno" by
  `match-ingredients`, then saved to hosted.
- The device's own language toggle (`Podešavanja` → `Jezik`), not system
  locale, is what the app follows; it was already on Srpski and rendered
  diacritics correctly throughout -- the slice plan's step assumed the app
  follows system locale, which it deliberately does not.
- Sharing a Chrome page via Android's `SEND` intent landed on the
  "Uvezi sa linka" screen with the URL pre-filled, confirming the
  `singleTop` share path on a real share sheet.

**What the plan got wrong, caught during the walk.** Two things, neither
blocking: `generate_link`'s real response shape (above), and Supabase's
built-in email validator rejecting `.test`-TLD addresses on `signInWithOtp`
even though `generate_link` itself bypasses that check -- worked around by
signing in with a real-domain address for the walk, with no change to
`lib/`.

**Not run:** import-photo from a real camera (step 8) -- no physical recipe
card was on hand. Handwritten-card OCR quality stays an open question in
`docs/decisions/OPEN.md`.

`make check` is clean apart from `seed-check`, unchanged from part 1 and
still tracked as its own slice.

---

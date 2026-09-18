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

### Part 3 — Google sign-in

**Status: complete.** Decisions taken during it: D98. Google lands alongside
email OTP, not instead of it -- part 4 is what removes the old path (D96).

`AuthRepository.signInWithGoogle()` runs the native `google_sign_in` v7 flow
and feeds the resulting ID token to `signInWithIdToken`, so nothing registers
a deep link on either platform and `site_url` was never touched -- most of
why the native flow was chosen over a browser redirect. The sign-in screen
grows a Google button below the existing email form behind an "ili" divider.
`google_sign_in` is a new dependency under rule 8, asked for and approved,
and `tool/check_layers.dart` now holds it inside `data/` the same way it
holds `supabase_flutter`, with `GoogleSignInException` added to the banned
cross-layer types.

- **v7 is a hard break from v6**, and Supabase's own Flutter snippet is
  wrong for a button press twice over. It calls
  `attemptLightweightAuthentication()`, which is the *silent* restore path
  and returns null when there is no session to restore; `authenticate()` is
  what a tap wants. It also calls `authorizeScopes(['email', 'profile'])`
  purely to obtain an `accessToken` -- which is optional on
  `signInWithIdToken`, since GoTrue validates the `idToken` by itself. The
  slice flagged that as its one genuine uncertainty. **Settled on device:
  the bare `idToken` is accepted, and the account chooser is a single sheet
  with no second consent prompt.** The `authorizeScopes` call stays out.
- **A cancelled account chooser returns null, not an `AppFailure`.** Backing
  out of the picker is neither an error nor a result, and D92's vocabulary
  has no sentence for it that would not be a lie on screen. One new
  `FailureCode.googleSignInFailed` covers every other
  `GoogleSignInExceptionCode`; `failure_l10n.dart`'s `default`-less switch
  refused to compile until it had a sentence in both ARBs, which is the
  guard working exactly as designed.
- **Two departures from the slice's own sketch.** The `idToken == null`
  throw now carries `code: FailureCode.googleSignInFailed` -- the sketch left
  it uncoded, which under D92 would have put an English log line on screen
  verbatim. And the lazy `initialize()` guard is a **static** bool rather
  than an instance field, because `GoogleSignIn.instance` is a process-wide
  singleton and a flag tied to the provider's lifetime would let a rebuilt
  `authRepositoryProvider` re-initialize an already-initialized SDK.
  `AuthRepository` stays `const` as a result.
- **The plan was wrong about the Android OAuth clients** and the walk proved
  it. It called for one client registered with both SHA-1s; a Google Cloud
  Android client binds to one package name plus exactly *one* fingerprint,
  so D97's two keystores are two separate clients and `client_id` is a
  four-entry list -- web, Android-debug, Android-upload, iOS. Neither
  Android ID appears in `lib/` at all: Android authenticates by package plus
  signature and asks for a token audienced at the web client. Where the IDs
  live, and why they are committed rather than in `env/*.json`, is D98.
- **`minSdk` needed no change**, verified rather than assumed: Flutter's
  default is 24 (`FlutterExtension.kt`) and `google_sign_in_android` requires
  exactly 24.

**How it was verified.** `make config-push` landed the
`[auth.external.google]` block on the hosted project with
`[auth.email.template.magic_link]` commented out for the duration and
restored immediately after (D95's dance, still ugly, still temporary). Then
on the same physical Galaxy S25 as part 2, against hosted:

- **An existing email-OTP user signing in with Google lands in their
  existing household**, not as a fresh user -- the check that would have hurt
  most if it were wrong, since `enable_manual_linking = false` means it rests
  entirely on GoTrue linking a provider-verified email. Confirmed twice, on
  both builds. The evidence is stronger than the recipe list looking right:
  the profile's locale was still English, which a newly created row could not
  be (D77 makes a fresh profile Serbian-first), and the install was fresh
  both times, so the Drift cache was empty and the recipes came over the wire
  on the new session rather than off disk.
- **Both Android clients are proven**, which is what a release-only walk
  would have missed. The release APK signs with the upload key
  (`A8:CA:F7:B0:…:ED:61:D8:89`, matched against the keystore with
  `apksigner`) and the debug APK with the debug key
  (`21:20:FB:60:…:DE:2B:2E:95`); both signed in against hosted. A wrong
  fingerprint on the debug client would have broken every future
  `make run-android` and surfaced at the worst possible moment.
- Cancelling the chooser returns the button to idle with no error text --
  the null-return path, confirmed by the absence of the sentence that any
  non-`canceled` code would have rendered.
- The signed-out screen renders in Serbian, as D77 says it must: nobody is
  signed in, so there is no `profiles.locale` and the device locale is never
  consulted.

**Not run.** A brand-new Google user landing on `CreateHouseholdRoute`
through `on_auth_user_created` -- the trigger is unchanged from part 1 and
fires on `auth.users` regardless of provider, but this slice did not watch it
do so, and the ROADMAP asked for it explicitly. Expect `display_name` to come
out as the email local-part when someone does: `handle_new_user()` does
`split_part(new.email, '@', 1)` and ignores Google's `full_name`, which is
worth noticing and not worth fixing here. Airplane mode against the Google
button, and a `make otp` regression check, were also skipped -- the first
because the emulator could not reach the network stage at all, the second
because it needs the service-role key.

**The emulator cannot do this walk**, and that is worth recording so the next
session does not spend the time. An API 37 / Android 17 Play image refuses to
add a Google account at all ("Something went wrong", `Accounts: 0`), with the
usual causes ruled out -- clock in sync, network up, Play Services and Play
Store both current. It is Google's device-integrity gating, not a
configuration fault. Everything short of the token exchange did work there
(screen renders, plugin initializes, Credential Manager opens, cancel returns
to idle), so it is useful for UI work and useless for sign-in itself.

`make check` is clean apart from `seed-check`, unchanged since part 1 and
still tracked as its own slice.

---

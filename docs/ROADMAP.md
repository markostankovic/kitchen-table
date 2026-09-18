# Roadmap

Build in this order. Finish and verify a phase before starting the next. Within
a phase, build vertical slices — schema, repository, provider, screen — one
feature at a time, not all schema then all UI.

---

## Phase 0 — Foundations

**Status: complete** (`392ab96`). Decisions taken during it: D19–D24. See `docs/journal/phase-0.md`.

---

## Phase 1 — Recipes, households, import

### 1a. Auth + households

**Status: complete** (`7fe319a`, then the invites slice). Decisions taken
during it: D25–D26. See `docs/journal/phase-1.md`.

---

### 1b. Ingredient catalog

**Status: complete.** Decisions taken during it: D27–D32. See `docs/journal/phase-1.md`.

---

### 1c. Manual recipe entry

**Status: complete.** Decisions taken during it: D33-D37. See `docs/journal/phase-1.md`.

---

### 1d. Import

**Status: complete** (parts 1–6). Decisions taken during it: D38–D46. See `docs/journal/phase-1.md`.

---

## Phase 2 — Meal plan, shopping list, offline cache

### Part 1 — Recipe photo upload

**Status: complete.** Decisions taken during it: D48. See `docs/journal/phase-2.md`.

---

### Part 2 — The meal plan

**Status: complete.** Decisions taken during it: D49–D54. See `docs/journal/phase-2.md`.

---

### Part 3 — Leftovers, variety and order

**Status: complete.** Decisions taken during it: D55–D58. See `docs/journal/phase-2.md`.

---

### Part 4 — The shopping list

**Status: complete.** Decisions taken during it: D59–D63. See `docs/journal/phase-2.md`.

---

### Part 5 — The Drift read cache, proven on the shopping list

**Status: complete.** Decisions taken during it: D64–D71. See `docs/journal/phase-2.md`.

---

### Part 6a — The delta fetch, and recipes and the ingredient catalog offline

**Status: complete.** Decisions taken during it: D72–D74. See `docs/journal/phase-2.md`.

---

### Part 6b — Meal plan weeks offline, and the global offline signal

**Status: complete.** Decisions taken during it: D75–D76. See `docs/journal/phase-2.md`.

---

### Part 7 — The household cache, and a bounded household read

**Status: complete.** Decisions taken during it: D87 (the finding), D88–D90
(the fix). Built during Phase 3, filed here because the gap it closes was
never on Phase 2's own offline list to begin with -- a reader looking for why
Part 6b's claim above needed correcting finds it at the end of Phase 2, not
in the middle of the localization phase. See `docs/journal/phase-2.md`.

---

## Phase 3 — Serbian / English

### Part 1 — The locale toggle, and the app chrome in two languages

**Status: complete.** Decisions taken during it: D77. See `docs/journal/phase-3.md`.

---

### Part 2 — `recipe_translations`, `translate-recipe`, and the recipe read in the reader's language

**Status: complete.** Decisions taken during it: D78–D81. See `docs/journal/phase-3.md`.

---

### Part 3 — The translation review flow

**Status: complete.** Decisions taken during it: D82–D86 (plus D87, a
finding rather than a build decision — see below). See `docs/journal/phase-3.md`.

---

### Still to build

- Review flow: **done** (part 3)
- D87's own fix: **done**, Phase 2 part 7 (D88-D90)
- The remaining screens' bodies: recipes **done** (part 4); households and
  import **done** (part 5, `1f770de`); meal plan and shopping list, plus the
  date-label layer `plan_week.dart` deferred, **done** (part 6) -- Phase 3
  is now complete

---

### Part 4 — The failure vocabulary, the script fix, and the recipes feature

**Status: complete.** Decisions taken during it: D91-D92. See `docs/journal/phase-3.md`.

---

### Part 5 — Households and import in two languages

**Status: complete** (`1f770de`). Journal entry backfilled during part 6's
close-out, after the fact -- this part originally shipped without a docs
update, which is the exact drift this restructuring exists to catch.
Touched: `households/presentation/`, `import/presentation/`, the ARB files,
`test/core/l10n/arb_parity_test.dart`. See `docs/journal/phase-3.md`.

---

### Part 6 — Meal plan and shopping list in two languages, and the date-label layer

**Status: complete.** Decisions taken during it: D93-D94. See
`docs/journal/phase-3.md`. This closes Phase 3 -- every screen now reads in
the reader's own locale, Serbian rendering Latin script throughout.

---

## Phase 4 — Going real: a real backend, a real phone, a real sign-in

### Part 1 — A real Supabase project

**Status: complete** (`69c94ea`). Decisions taken during it: D95–D96. See
`docs/journal/phase-4.md`.

Shipped narrower than planned. The hosted project (`cbajkezfhssrvbdbedqt`,
West EU) carries all 18 migrations, the catalog, the function secret and all
seven Edge Functions, with `env/hosted.json`, `make run-hosted` / `db-push` /
`config-push`, and a new `## Environments` section in `docs/ARCHITECTURE.md`.
The one criterion not met — "verify email OTP end-to-end against a real
inbox" — was **withdrawn, not deferred**: a free tier project cannot send a
custom email template, so that criterion describes a feature being deleted
(D96). Verified instead through every path that does not go through the mail.

---

### Part 2 — Run on a real device

**Status: complete** (`cab2ee0`). Decisions taken during it: D97. See
`docs/journal/phase-4.md`.

Android only (iOS is its own slice — no `ios/Podfile` has ever been
generated in this repo). Verified end to end on a physical Galaxy S25
against the hosted project from Part 1: release install, sign-in via
`make otp`, a real airplane-mode cycle closing the D92 on-device gap in
`docs/decisions/OPEN.md`, a genuine Wi-Fi→cellular transition, and an AI
round trip over cellular. Release signing reads `android/key.properties`
locally, falling back to the debug keystore when absent (D97). Import-photo
from a real camera (step 8) was not run — no physical recipe card on hand.

---

### Part 3 — Google sign-in

**Status: complete** (`e10a66b`). Decisions taken during it: D98. See
`docs/journal/phase-4.md`.

Native `google_sign_in` v7 feeding `signInWithIdToken`, not a browser
redirect — so no deep link is registered on either platform and `site_url`
is untouched. Google lands **alongside** OTP, as D96 planned; Part 4 is what
removes the old path. Verified on the physical Galaxy S25 against hosted:
an existing email-OTP user signing in with Google lands in their **existing**
household, and both Android OAuth clients work — release (upload key) and
debug (debug key), which is what proves D97's fallback path. The bare
`idToken` is accepted without `authorizeScopes`, so there is no second
consent sheet. Client IDs are committed constants (D98); the Android side
needed two clients, not one with two fingerprints.

**Not run:** a brand-new Google user landing on `CreateHouseholdRoute`
through `on_auth_user_created`. The trigger is unchanged and fires on
`auth.users` regardless of provider, but this slice did not watch it do so.
Note for whoever does: `display_name` will be the email local-part, since
`handle_new_user()` does `split_part(new.email, '@', 1)` and ignores
Google's `full_name`.

---

### Part 4 — Remove email OTP

**Status: complete** (`37a837f`). Decisions taken during it: D99. See
`docs/journal/phase-4.md`.

Google is now the only way in. Removed `requestOtp` / `verifyOtp` from
`AuthRepository`, the verify-OTP screen and its route, the email form and
"ili" divider on the sign-in screen, the OTP ARB strings on both sides,
`supabase/templates/magic_link.html` and its `config.toml` block. With the
template gone, `make config-push` sends the whole `[auth]` payload in one
shot -- no more commenting the block out, pushing, and restoring it (D95's
dance, retired).

This list originally named `FailureCode.codeNotAccepted` for deletion too;
that was wrong (D99) -- household invite redemption maps three Edge Function
slugs onto the same code, so it stays, and only its OTP-specific references
were trimmed. Household invite codes remain a different system, otherwise
untouched. Verified end to end on the physical Galaxy S25 against hosted:
fresh install, sign-in screen shows one Google button, and tapping it lands
straight in the existing household with no verify-code screen anywhere.

---

### Part 5 — Apple sign-in

**Status: not started.** Required before any App Store submission, not
optional polish: Guideline 4.8 requires an equivalent privacy-preserving
option wherever a third-party login is offered, so Google-only ships for
personal signing and TestFlight but not to the store (D96). Needs a Sign in
with Apple package — new third-party dependency, ask first.

---

## Phase 5 — Everything deferred

Not before Phase 3 ships.

- `suggest-meals` Edge Function (from existing recipes + what's in the fridge)
- Novel recipe generation (lowest value; always `status = 'draft'`)
- Cross-family unit conversion via densities on the top ~50 ingredients
- Handwritten recipe card OCR (same path as cookbook photos, worse accuracy)
- Thin web layer — leaning Next.js on Vercel, same Supabase project, for invite
  links and read-only recipe pages. Decide properly when you get here.
- Aisle grouping on the shopping list via `ingredients.category`

---

## Standing rules across phases

- Anything AI-produced is `status = 'draft'` until a human marks it tested.
- `source_url` / `source_attribution` stored and displayed for every import.
- Imported cookbook and web content stays household-visible only.
- New table → `updated_at` trigger, `deleted_at`, RLS policies, in the same
  migration. Never a follow-up.

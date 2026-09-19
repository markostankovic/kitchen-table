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

## Phase 5 — Everyday use: finding a recipe, planning from it, taking the list

Phase 4 made the app real on a real phone. This phase is about the six small
frictions that show up once a household actually cooks from it: you can't mark
what you love, you can't narrow a growing list, you can't get from a recipe to
the plan, the plan always opens on a whole week, the shopping list can't leave
the app, and translating is hidden behind a condition.

Promoted from `docs/IDEAS.md`. Parts 1 and 2 are ordered — the filter is built
once, over both tags and favorites, so favorites has to exist first. Parts 3–6
are independent of each other and of 1–2; reorder them freely.

---

### Part 1 — Favorites and a five-star rating

**Status: complete** (`d80bf74`). Decisions taken during it: D100–D101. See
`docs/journal/phase-5.md`.

Two columns on `recipes`: `is_favorite boolean not null default false` and
`rating smallint check (rating between 1 and 5)`, nullable — unrated is not
zero stars. Both are **household facts, not personal ones**: the rule in
CLAUDE.md is household-scoped data, and `profiles` is the only table in the
app with `auth.uid()`-based RLS. The trade is real and deliberate — one
member's tap changes the rating for everyone.

No RLS change: the existing `recipes` policies already covered the new
columns. Migration 19 is the **first `alter table ... add column` migration
in the repo** — every migration before it creates its tables whole — and
D100 records the house style that sets for extending an applied table.

Both columns joined `recipeColumns` in `recipe_dto.dart`, which changed what
the Drift `data` blob holds, so **`schemaVersion` bumped 5 → 6** in
`lib/core/db/app_database.dart` (drop-and-refetch, D71 — no per-version
migration code). Narrow writers (`setFavorite`/`setRating`), not
`RecipeDraft`/`RecipeEditor` setters — this list's original sketch was wrong
about that; the editor deliberately never touches either column. UI: an AppBar
star and a five-star row on the detail screen (local echo, not invalidate —
D101), a filled star plus `★ N` on the list tile.

This list's own open question — does the list tile favorite in place, or
only display? — resolved to **display-only**; no in-place toggle from the
list.

---

### Part 2 — Filtering the recipe list

**Status: complete** (`6c5b207`). Decisions taken during it: D102. See
`docs/journal/phase-5.md`.

Filters the landing page by tag and by favorite. `recipes.tags` existed since
migration 8 and was already carried by every read — this part added no
schema. The tag vocabulary is the distinct tags across the household's
cached recipes, collapsed through the existing `TextNormalizer` so `Posno`
and `posno` render as one chip (`RecipeTag.vocabularyOf`).

Widened `recipeListProvider`'s family args from `query` alone to `query`,
`tag`, `favoritesOnly` (still two primitives, not a filter object — D102),
`RecipeRepository._filtered`, and added a filter row under the existing
search box: single-select tag chips plus one Favorites chip, AND-composed.
`plannableRecipeSourceProvider` in `lib/core/recipes/` passes neither new
arg, so the meal-plan picker is unchanged.

Filtered in Dart after decode, matching what search already does — D102
records why, and that promoting `tags` to a queryable Drift column remains
the escape hatch once a household's recipe count makes it worth doing.

One gap surfaced during the device walk, not fixed in this part: the filter
row — Favorites chip included — only renders once the tag vocabulary is
non-empty or a filter is already selected, so a household with zero tags
currently cannot reach the Favorites filter at all (D102's Consequences).

---

### Part 3 — Add to meal plan from a recipe

**Status: complete** (`e3245e0`). Decisions taken during it: D103. See
`docs/journal/phase-5.md`.

The recipe detail screen's overflow menu gains **Add to meal plan...**,
mirroring the plan's own `showRecipePicker`: a bottom sheet offers four slot
chips and the next 14 days, picking one writes a `meal_plan_entries` row and
confirms with a snackbar. The layering wall is the mirror image too — the
day+slot sheet and its write shim live in `core/meal_plan/`, the same escape
hatch `core/recipes/` already used in the other direction (D53/D43).

This part's own sketch called for reusing
`MealPlanEditor.addRecipe(...)` unchanged; planning caught two reasons that
doesn't work (the visible-week write funnel, and `mealPlanEditorProvider`
being `autoDispose`) before any code was written, so a small keepAlive
`MealPlanWriter` was built instead, deriving its destination week from the
chosen date (D56's rule, D103). No schema change, no migration.

---

### Part 4 — The meal plan's Today and This week views

**Status: not started.**

The plan screen is a vertical list of seven `_DaySection`s with a week bar on
top. Add a Today view beside the existing week view.

There is **no `TabBar`, `TabController` or `PageView` anywhere in `lib/`**. The
app's existing answer to "two views, one screen" is `SegmentedButton`
(settings, recipe edit) and `ExpansionTile` (the shopping list's pantry
section). Picking `TabBar` here is a real choice and gets a decision record;
picking the segmented control is the conservative one.

The sharp edge is `visibleWeekProvider`, which is a single notifier, not a
family: what does Today show after you have paged to a week three weeks out?
Recommended — Today pins to `DateTime.now()` and hides the week chevrons
entirely; This week keeps `_WeekBar` as it is. Also fold the inline y/m/d
comparison in `_DaySection._isToday` into a shared helper rather than writing
it a second time.

---

### Part 5 — Export the shopping list to the clipboard

**Status: not started.**

An app bar action beside the existing refresh button: format the list as plain
text, `Clipboard.setData`, SnackBar. The pattern already exists at
`lib/features/households/presentation/household_screen.dart` (invite code
copy) — copy it exactly, including the ARB key shape.

No new package. `flutter/services` carries `Clipboard`; `share_plus` is not a
dependency and adding one needs asking first (rule 8). Copy-to-clipboard is
the whole ask here — a share sheet is a different, later conversation.

The formatter is pure Dart in `features/shopping_list/domain/`, so it is
testable without a widget: reuse `formatItemQuantity` and mirror
`_ListBody._byCategory`'s grouping and its "uncategorised sorts last" rule.

One real decision: the screen renders two locales at once on purpose — the
snapshot in `list.locale`, the chrome in the reader's (D94). Exported text has
no chrome, so it should follow `list.locale` throughout. Say so explicitly in
the slice, or it will drift.

---

### Part 6 — Translating from the editor

**Status: not started.**

Translation is reachable today, but only from the detail screen's overflow
menu and only when `canTranslate` holds: you must be reading in the other
language *and* no translation may exist yet. Once one exists the menu offers
Review instead and Translate never returns. From the editor there is no path
at all.

The call path itself is done and needs nothing:
`RecipeRepository.translate(recipeId, targetLocale)` →
`RemoteRecipeDataSource.translate` → the `translate-recipe` Edge Function.
This part is entry point and gating only. The edit screen's app bar has no
actions at all today — its affordance lives in the bottom save bar — so this
adds the first one.

Two questions to settle before building, both capable of breaking something:

- **An unsaved draft cannot be translated.** The Edge Function reads the
  recipe from the database. So does the action save first, or is it disabled
  while the form is dirty? A new recipe has no id at all.
- **Do not break D85.** Re-translating a *reviewed* translation is
  deliberately not offered, and the UI is the only guard — there is no
  server-side check. A second entry point is a second place that guard has to
  hold. Re-translating a machine translation may be fine; overwriting a
  human's review is not.

---

## Standing rules across phases

- Anything AI-produced is `status = 'draft'` until a human marks it tested.
- `source_url` / `source_attribution` stored and displayed for every import.
- Imported cookbook and web content stays household-visible only.
- New table → `updated_at` trigger, `deleted_at`, RLS policies, in the same
  migration. Never a follow-up.

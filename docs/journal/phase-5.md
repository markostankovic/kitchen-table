# Journal — Phase 5

Verbatim build history for Phase 5 — Everyday use: finding a recipe, planning from it, taking the list, moved out of `docs/ROADMAP.md` so the roadmap stays a forward-looking index. Nothing here is authoritative going forward -- see `docs/decisions/` for standing rules, `docs/STATE.md` for current status.

---

## Phase 5 — Everyday use: finding a recipe, planning from it, taking the list

### Part 1 — Favorites and a five-star rating

**Status: complete** (`d80bf74`). Decisions taken during it: D100–D101.

Two columns on `recipes` -- `is_favorite boolean not null default false` and
`rating smallint check (rating between 1 and 5)`, nullable so unrated is
`null`, never `0`. Both are household facts, not personal ones (D24): any
member's tap changes the value for everyone, the same trade the slice plan
called out up front.

- **Migration 19** is the repo's first additive `alter table ... add column`
  against a table created whole by an earlier migration -- every migration
  through 18 creates its own tables. No RLS or trigger change: the existing
  `recipes` policies and `recipes_set_updated_at` are both column-agnostic
  and already cover the new columns (D100).
- **Narrow writers, not the existing `update`.** `RemoteRecipeDataSource`/
  `RecipeRepository` gained `setFavorite`/`setRating`, mirroring
  `softDelete`. `RecipeDraft`/`RecipeEditor` gained neither field --
  `docs/ROADMAP.md`'s Part 1 sketch calling for editor setters was wrong,
  corrected below. An editor save's twelve-arg `update` payload still never
  touches either column, so a stale editor can't clobber someone else's
  rating.
- **Local echo, not invalidate.** `recipeDetailProvider` is a plain `Future`
  provider whose body is `detail.when(loading: CircularProgressIndicator)`,
  so invalidating after every tap would flash a spinner over the whole
  recipe. The detail screen instead holds the pending value in its own
  `State`, renders it immediately, writes, and on success calls
  `recipesRevisionProvider.notifier.bump()` without invalidating the detail
  provider; on `AppFailure` it reverts the echo and shows a snackbar exactly
  as `_confirmDelete` does. First mutation in the app that doesn't end in an
  invalidate (D101).
- **Cache:** `AppDatabase.schemaVersion` 5 → 6, same reasoning as the bump to
  4 in Phase 3 part 2 -- `RecipeCache.data`'s blob shape changed while
  `updated_at` didn't move, so a pre-migration cached row would never be
  re-sent by the delta fetch without the bump.
- **UI:** an AppBar star (filled/outline, tooltip flips
  add/remove-favorites) and a five-star row under the detail screen's meta
  line, keyed `ratingStars` for widget tests. Re-tapping the star that
  already is the rating clears it back to `null` (user decision, not zero).
  The list tile is display-only, per the slice's own resolved open
  question: a filled star in `trailing` alongside the Draft chip, and
  `★ N` appended to the meta line when rated -- no in-place toggle from the
  list.
- **Localization:** four new keys in `app_sr.arb` (template) then
  `app_en.arb` -- `addToFavoritesTooltip`, `removeFromFavoritesTooltip`,
  `clearRatingTooltip`, and `ratingStarsTooltip`, this repo's second ICU
  plural after `recipeServingsCount`, Serbian's one/few/other against
  English's one/other.
- **One thing the slice plan didn't list:** `recipe_repository_offline_test.dart`'s
  hand-written `_FakeRemote implements RemoteRecipeDataSource` needed
  `setFavorite`/`setRating` overrides (throwing `UnimplementedError`, its
  existing pattern for untouched members) once the interface grew those
  methods, or `dart analyze` failed. Small and obvious, fixed inline rather
  than treated as a re-plan trigger.

**How it was verified.** `make lint` (analyze + `check_layers`), `make test`
(483 tests, including new rendering tests: the list tile's star + `★ 4`,
and three-filled/two-outlined vs. five-outlined stars on the detail screen
-- no tap test, since the handlers reach a concrete
`ref.read(recipeRepositoryProvider)` with no override seam and rule 8 rules
out a mocking package for one), `make db-reset` (migration 19 applies
clean), and `make test-sql` (every file green, including new
`rls_recipes_test.sql` assertions: a member can write both columns, and
`rating = 0` / `6` are rejected while `1` / `5` are accepted) all passed
locally. `make l10n-check`'s regeneration step also passed -- its
`git diff --exit-code` only showed the four new keys, purely additive,
before the implementation commit landed.

Then verified end-to-end on the physical Galaxy S25 (`RFCY61SRQ3B`), against
hosted:

- A release build against hosted (`env/hosted.json`) initially failed the
  recipe list with a generic "Nešto je pošlo naopako." -- migration 19 had
  only been applied locally via `db-reset`, and hosted was still on
  migration 18, so `recipeColumns`' new `is_favorite, rating` request 400'd.
  Confirmed by querying `information_schema.columns` against hosted
  directly, then fixed with `supabase db push`; the recipe list loaded
  cleanly afterward.
- The release build was installed by serial (`adb -s RFCY61SRQ3B install`)
  after uninstalling the prior debug build, whose signature didn't match --
  the same signature-mismatch pattern Phase 4 part 4 hit.
- From there, favorite toggle and rating star behaviour were confirmed
  manually on-device.

`make check` is clean apart from `seed-check`, unchanged since Phase 4 and
still tracked as its own slice (`c8be2bc`).

**Correction to the ROADMAP sketch.** Part 1's own sketch (written during
planning) listed "Domain: `Recipe`, `RecipeDraft`, `RecipeEditor` setters" --
the sketch was wrong. `RecipeDraft`/`RecipeEditor` deliberately gained
neither field; see the narrow-writer note above.

---

### Part 2 — Filtering the recipe list

**Status: complete** (`6c5b207`). Decisions taken during it: D102.

A filter row under the search box: one **Favorites** toggle and one chip
per tag in the household's vocabulary, single-select, AND-composed with
the search term and with each other. No schema change -- `recipes.tags`
and `is_favorite` (Part 1) already existed; this part is Dart-only.

- **`RecipeTag.vocabularyOf`** (new domain type, `recipe_tag.dart`) groups a
  recipe list's `tags` by `TextNormalizer.normalize`, so `Posno` and `posno`
  collapse to one chip, picks the alphabetically-first original spelling as
  the deterministic label, drops blank tags, and sorts by key so chip order
  never depends on recipe order.
- **`RecipeRepository._filtered`** widened from `(recipes, query)` to also
  take `tag` and `favoritesOnly`, AND-composed with the title match, applied
  to both the cached and the post-sync emission of `watchList` -- D67's
  shape, unchanged in kind, just wider.
- **The filter's family args are two primitives** (`tag`, `favoritesOnly`),
  not a freezed filter object -- Riverpod keys a family by value for
  primitives, but by identity for a `List`/object, which would mint a fresh
  provider entry on every rebuild. `tag` is the *normalized* key, not the
  display spelling, so `Posno` and `posno` select the same entry (D102).
- **`recipeTagsProvider`** is synchronous, deriving the vocabulary from
  `recipeListProvider()` at its default args (the unfiltered list) via
  `ref.watch(...).value` -- so chips never vanish as the list is narrowed,
  and the row is simply absent while the list is loading or errored.
- **The filter row hides itself** when the vocabulary is empty *and*
  nothing is selected -- a household with no tags at all currently has no
  way to reach the Favorites chip either, since it renders inside the same
  row. Discovered manually on-device (below), not called out in the slice
  plan; recorded as a consequence in D102 rather than reworked here.
- A **stale selected tag** (its last recipe was deleted, so it fell out of
  the vocabulary) still renders as a chip, labelled with its own key -- the
  filter is never a dead end.
- **One deviation from the slice plan:** `recipeTagsProvider` was specified
  against `AsyncValue.valueOrNull`, which this repo's pinned Riverpod
  (3.4.3) does not expose -- that version's equivalent nullable accessor is
  `.value`. Used `.value`; behaviour is identical.

**How it was verified.** `dart analyze`, `dart run tool/check_layers.dart`,
`deno check`/`lint`/`fmt`, `flutter test` (496 tests -- new:
`recipe_tag_test.dart`'s `vocabularyOf` cases, widened
`recipe_repository_offline_test.dart` `watchList` cases for tag/favorites/
compose/diacritic-insensitivity, and widget tests for the chip row,
tap-to-narrow, and Favorites+tag composing), `deno test` for the Edge
Functions, and `make test-sql` against the running local stack all passed.
`make check`'s `seed-check` step is red for the pre-existing, unrelated
reason tracked since `c8be2bc` (see `docs/STATE.md`) -- confirmed it is the
same failure, not something this slice caused.

Installed as a release build against hosted (`env/hosted.json`) on the
physical Galaxy S25 (`RFCY61SRQ3B`) and confirmed running -- no migration in
this slice, so no `make db-push` step was needed (unlike Part 1). The filter
row's actual on-device interaction (tapping a tag, tapping Favorites) was
**not** confirmed with real data in this pass: the test household's recipes
carried no tags, so the row -- Favorites included -- stayed hidden by the
design above, and the session ended with instructions for adding a tag
through the recipe editor rather than a confirmed manual walk. A future
session should close that loop before trusting the on-device behaviour
beyond what the widget tests already cover.

---

### Part 3 — Add to meal plan from a recipe

**Status: complete** (`e3245e0`). Decisions taken during it: D103.

The recipe detail screen's overflow menu gains **Add to meal plan...**,
opening a bottom sheet with four slot chips and the next 14 days; picking
one writes a `meal_plan_entries` row and confirms with a snackbar. The
snack variety warning (D58, advisory) fires here exactly as it does on the
Plan tab. No schema change, no migration.

- **Correction to the ROADMAP sketch.** Part 3's own sketch (written during
  planning) said this would reuse `MealPlanEditor.addRecipe(...)`
  unchanged. Planning caught two problems with that before any code was
  written: `MealPlanEditor._write` derives the destination week from
  `visibleWeekProvider`, which this screen has none of, and the
  `meal_plan_entries_before_write` trigger (migration 14) would refuse an
  `entry_date` outside whatever week that provider happened to hold; and
  `mealPlanEditorProvider` is `autoDispose`, so reading its `.notifier` from
  a screen that never watches it risks the notifier being torn down
  mid-`await`. A new keepAlive `MealPlanWriter` in `core/meal_plan/` was
  built instead, over its own `MealPlanRepository`, deriving the
  destination week from the chosen date the same way
  `MealPlanEditor.addLeftover` already does for a leftover (D56). D103
  records this.
- **The layering wall is the mirror image of `core/recipes/`.**
  `features/recipes/presentation/` may not import
  `features/meal_plan/application/`, so the day+slot sheet
  (`meal_slot_picker_sheet.dart`) and the write shim
  (`meal_plan_writer.dart`) live in `core/meal_plan/`, outside
  `tool/check_layers.dart`'s feature rule entirely — the same escape hatch
  D53/D43 already established for `core/recipes/recipe_picker_providers
  .dart`, one direction over.
  `features/meal_plan/domain/meal_slot.dart` and
  `features/meal_plan/domain/snack_variety.dart` are imported directly by
  the recipe screen, which is legal: cross-feature into `domain/` is the
  one permitted direction, and `meal_plan_screen.dart` already imports
  `features/recipes/domain/` the same way.
- **`mealSlotLabel`** moved out of `meal_plan_screen.dart`'s private
  `_slotLabel` into `core/l10n/meal_slot_labels.dart`, a sibling function
  taking `(MealSlot, AppLocalizations)` on `core/error/failure_l10n.dart`'s
  own precedent (D92) — needed because the picker sheet, living in `core/`,
  has no feature-local copy to reach for and may not import
  `features/meal_plan/presentation/`.
- **The sheet returns a decision, the caller writes** — `MealSlotPick(date,
  slot)`, one value rather than a sealed hierarchy like `RecipePick`, since
  there is only one kind of decision here. Fourteen days from today via
  `DateTime(y, m, d + n)` (never a `Duration` add — `plan_week.dart`'s DST
  rule applies here too), `ChoiceChip`s over `MealSlot.ordered` defaulting
  to dinner, and a `Chip` badge on today's row rather than replacing its
  date label outright.
- **A success snackbar is deliberate here**, unlike the silent favorite
  star and rating stars (Part 1): this screen shows no other visible change
  once the write lands, so `addedToPlanSnackbar` names the day and slot,
  on `shopping_list_screen.dart`'s `markedAsStapleSnackbar` precedent.
- One incidental fix, not part of this slice's own scope: `make gen`
  regenerated `recipe_providers.g.dart`'s doc comments (`valueOrNull` →
  `value`), which had gone stale since Part 2 actually shipped `.value`
  (Riverpod 3.4.3 has no `valueOrNull`) without a `.g.dart` rebuild to
  match. Left in rather than reverted — it only brings a generated file
  back in sync with its own already-committed source.

**How it was verified.** `dart analyze`, `dart run tool/check_layers.dart`,
and `flutter test` (full suite, including the new
`meal_slot_picker_sheet_test.dart` and the six new `recipe_screens_test.dart`
cases: menu item renders, a day+slot pick calls `addRecipe` with exactly
that date and slot, a snack slot over the repeat threshold warns and
Cancel/Add anyway behave, a non-snack slot never calls
`snackRepeatCount`, and an `AppFailure` renders a snackbar) all passed.
`make l10n-check` showed a diff only because the ARB/generated changes were
still uncommitted at the time it ran — confirmed with a second
`flutter gen-l10n` producing a byte-identical file, so the generated files
were already correctly in sync. `make test-sql` passed against the running
local stack (untouched by this slice, no migration). `make check`'s
`seed-check` step stayed red for the pre-existing, unrelated reason tracked
since `c8be2bc` (see `docs/STATE.md`).

Installed as a release build against hosted (`env/hosted.json`) on the
physical Galaxy S25 (`RFCY61SRQ3B`), reinstalled after Part 2. The on-device
walk itself — adding a recipe to a day in next week, confirming the entry
appears after paging the Plan tab forward, and triggering the snack-repeat
dialog from this screen — was **not** confirmed manually in this pass; only
the app's install and launch were. A future session should close that loop
before trusting the on-device behaviour beyond what the widget tests above
already cover.

---

### Part 4 — The meal plan's Today and This week views

**Status: complete** (`0e24704`). Decisions taken during it: D104.

`MealPlanScreen` gains a `SegmentedButton<_PlanView>` (Today / This week)
between the AppBar and the body, on `settings_screen.dart`'s existing
`SegmentedButton` shape and `recipe_list_screen.dart`'s existing pattern for
a screen's own ephemeral view state (`setState`, not a provider). Today is
the default, closing one of the six frictions Phase 5's own intro named:
"the plan always opens on a whole week."

- **Today pins, it doesn't own, the visible week.** Selecting Today calls
  `ref.read(visibleWeekProvider.notifier).today()` and then renders one
  `_DaySection` for `DateTime.now()` from the same `mealPlanEditorProvider`
  data the week view reads — no second week provider, on D54's precedent
  that `visibleWeekProvider` stays a single non-family notifier. D104
  records this and its consequence: switching to Today after paging the
  week view forward snaps back to the real today, discarding the page
  position, deliberately. The week view's own chevrons and the AppBar's
  `Icons.today_outlined` jump-to-today action are hidden entirely in
  Today — pinned to one day, neither means anything.
- **One definition of same-calendar-day.** `isSameDate(a, b)` is new in
  `plan_week.dart`; both `MealPlanWeek.entriesFor`'s inline three-field
  comparison and `_DaySection._isToday` now call it instead of each
  keeping their own copy (CLAUDE.md rule 6's instinct, even though this
  pair is same-language, not cross-boundary). `_DaySection` also gains
  `showFullDate` (default `false`): Today's header calls `shortDateLabel`
  instead of `weekdayAndDay`, since a lone day section has no week around
  it to disambiguate the month — `_showLeftoverDialog`'s own reason for
  the same choice on its 14-day list, applied here to a header instead of
  a dropdown.
- Two new ARB keys, `todayViewLabel` / `weekViewLabel`, kept apart from the
  existing `thisWeekTooltip` (AppBar icon) and the shopping list's
  `thisWeekButton` on the file's existing per-widget-key principle, even
  though the Serbian text is identical to `thisWeekTooltip`'s ("Ova
  nedelja"). No schema change, no migration, no new package.

**How it was verified.** `dart analyze`, `flutter test` (full suite,
including the extended `plan_week_test.dart` and the widened
`meal_plan_screen_test.dart` — every pre-existing grid/entry test now
reaches the week grid through a new `weekView: true` `_pump` parameter,
since Today is the default; new cases cover the Today default, the Today
header's `shortDateLabel`, switching to This week, the pin invariant after
paging, and a Today-view assertion added to the existing D91 srLatn
regression), `make lint`, `test-functions`, and `test-sql` all passed.
`make l10n-check` showed a diff only because the ARB/generated files were
still uncommitted when it ran — the diff was exactly the two new keys, no
drift. `make check`'s `seed-check` step stayed red for the pre-existing,
unrelated reason tracked since `c8be2bc` (see `docs/STATE.md`).

Installed as a release build against hosted on the physical Galaxy S25
(`RFCY61SRQ3B`) and walked by hand end to end, unlike Parts 2 and 3: Plan
opened on Today showing the real date with an existing dinner entry
visible; added a recipe to Today's breakfast slot and it landed correctly;
switched to This week and saw the full 7-day grid with chevrons and the
jump-to-today icon back, today's header still emphasised within the week;
paged forward a week, switched back to Today, and confirmed it rendered
the real today, not the paged-to week (the D104 invariant, confirmed on
device as well as in the widget test). Also closed both loops STATE.md was
carrying from Parts 2 and 3 while on the device: the tag filter (tapping
"doručak" correctly narrowed the recipe list to one match) and the
add-to-plan flow (recipe detail → overflow → "Add to meal plan…" → a day
next week → paging the Plan tab forward confirmed the entry). Neither loop
was this slice's own code; both simply worked.

---

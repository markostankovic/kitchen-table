# Journal — Phase 6

Verbatim build history for Phase 6 — Tags in two languages, findable by tag, and a household you can edit — moved out of `docs/ROADMAP.md` so the roadmap stays a forward-looking index. Nothing here is authoritative going forward -- see `docs/decisions/` for standing rules, `docs/STATE.md` for current status.

---

## Phase 6 — Tags in two languages, findable by tag, and a household you can edit

### Part 1a — Tags carry a sr/en pair

**Status: complete** (`b22a327`). Decisions taken during it: D107–D108.

Part 1 of the roadmap's own wording turned out to be two slices' worth of
work, split in the planning session on Phase 2 part 6a/6b's precedent: 1a
is the table, its RLS, the cache, the resolution rule and the rendering;
1b -- a dedicated `translate-tags` Edge Function -- is next. A tag typed in
one language now renders in the reader's own language on both the recipe
list's filter chips and the detail screen's chips; a tag with no pair
renders exactly as typed; the editor's tags field always shows exactly
what was typed, translated or not; filtering keeps matching across both
spellings unchanged. Nothing in this slice writes a translation -- pairs
are inserted by hand to verify the read path; minting them is 1b's job.

- **Migration 21, `recipe_tag_names`** -- `ingredient_names`' shape, not
  `recipe_translations`'s (D107): `tag_key` is the normalized *original*
  spelling, exactly `RecipeTag.key`, with a generated `normalized_name`
  column that nothing in 1a reads yet (Part 2's "typing a tag's name
  narrows the list" will need it, and migrations are append-only) and a
  total unique index on `(tag_key, locale, coalesce(household_id, ...))`.
  Three RLS policies land in this one migration -- select (global-or-
  member, `ingredient_names_select` verbatim), insert and update (member-
  owned rows only) -- so 1b's Edge Function costs no second migration for
  its write path.
- **`RecipeTagNameCache`** (Drift schema 6→7) departs from
  `IngredientNameCache`'s watermark-and-delta sync on purpose (D108): one
  household's tag vocabulary is a handful of rows, so
  `LocalRecipeDataSource.replaceTagNames` deletes and reinserts the whole
  cached set per household, `UnitCatalogCache`'s "a fetch replaces the row
  outright" reasoning scaled up from one row to a small set. Wiped on
  sign-out alongside `RecipeCache` and friends, since it is household-
  scoped.
- **`RecipeRepository.fetchTagLabels`** is network-first with a cache
  fallback on `NetworkFailure`, `fetchDetail`'s own shape (D74), not
  `watchList`'s two-emission stream -- this is a single lookup, not a
  sync. `RemoteRecipeDataSource.fetchTagNames` fetches every locale, not
  just the reader's, since the table is tiny and caching both means
  switching language offline still works.
- **`RecipeTag.relabelled`** is a pure static beside `vocabularyOf`, not a
  second signature on it, per the roadmap's own open question: `key` never
  changes, only `label`, so a translated chip still filters exactly like
  the as-typed one did and `RecipeRepository._filtered` needed no change
  at all. The list screen's `_FilterRow` relabels *before* the "selected
  tag fell out of the vocabulary" branch, so a synthesised chip for a
  still-selected but now-missing tag is translated too. The detail
  screen's chips render `recipe.tags` directly (original spellings), so
  the lookup there is per-tag rather than through `relabelled`. The
  editor's comma-joined field is untouched, deliberately -- round-tripping
  a cook's own words through translation would silently rewrite them.

**How it was verified.** `dart run build_runner build -d` then `dart
analyze` -- clean (one incidental fix: a hand-written fake
`RemoteRecipeDataSource` in `recipe_repository_offline_test.dart` needed
the new `fetchTagNames` method stubbed). `make db-reset` then `make
test-sql` -- all green, including the new
`rls_recipe_tag_names_test.sql` (member read/write, non-member denial,
global-row visibility, the unique-index rejection, the `updated_at`
trigger). `flutter test` -- 544 tests, including new pure-domain cases for
`RecipeTag.relabelled` and new widget cases across the list, detail and
edit screens (a translated chip, a tag with no pair falling back to as-
typed, a translated chip still narrowing the list by its unchanged key,
and the edit screen's tags field never relabelling). `make check` ran
green through `test`/`test-functions` before stopping at the pre-existing,
unrelated `seed-check` failure tracked since `c8be2bc` (`docs/STATE.md`);
`test-sql` and `l10n-check`, which that same chain never reached, were
already confirmed green independently above.

Hand-inserting a `Posno`/`Lenten` pair against local and walking the
language switch, and pushing migration 21 to hosted (`make db-push`) for a
device install on the Galaxy S25, were both handed to the user to run by
hand and had not been confirmed back as of this entry.

---

### Part 1b — `translate-tags`, the writer of the pair

**Status: complete** (`a247d1c`). Decisions taken during it: D109.

The writer 1a's read path was built for. Saving a recipe with a tag nobody
has translated yet now results in that tag carrying both spellings shortly
afterward, with no user action beyond the save; a tag already paired costs
no model call on a later save; a translation failure never blocks or rolls
back the save that triggered it. No migration -- migration 21 already
granted `recipe_tag_names` the insert/update RLS this needed, on purpose.

- **`translate-tags/index.ts`** resolves the household from the caller's
  own membership, `create-invite`'s own shape -- no household id in the
  body, so a client can never name a household it might not belong to. It
  reads the household's tag vocabulary through the **caller's** client
  (RLS decides, `translate-recipe`'s own reasoning), groups by
  `normalizeText()` the same way `RecipeTag.vocabularyOf` does in Dart, and
  diffs it against *every* existing `recipe_tag_names` row for the
  household -- deliberately unfiltered by `deleted_at`, since the unique
  index is total and a soft-deleted row still occupies its slot. Nothing to
  do returns before `checkQuota` and before any model call
  (`match-ingredients`'/`translate-recipe`'s own stated property).
- **`_shared/translate_tags.ts`** is `translate.ts`'s counterpart for
  vocabulary: `TRANSLATE_TAGS_SYSTEM_PROMPT`, a pure `alignTags` that
  refuses a reply whose key set isn't exactly the requested one
  (`alignSteps`'s own exact stance -- a plain `Error`, converted to a
  billed `AiFailure` by the caller), and `translateTags` wrapping
  `callStructured` with one call for the whole batch, capped at
  `MAX_TAGS_PER_CALL` (50) so the prompt stays bounded.
- **D109** (this slice): both locales are always requested together per
  tag, and an alive row -- `curated`, `user`, or an earlier `llm` pair --
  is never overwritten; only a missing slot is inserted and only a
  soft-deleted one is revived, as a plain insert or an update-by-id, never
  a PostgREST upsert -- `recipe_tag_names_unique` is an expression index
  (`coalesce(household_id, '000...')`) that no `onConflict` clause can
  match. `RecipeEditor.save()` is the only trigger (`ImportConfirm.
  saveImported` is deliberately left alone -- `features/import/` may not
  reach `RecipeRepository`, and the function diffs the household's whole
  vocabulary anyway, so the next editor save delivers the same pairs at no
  extra cost), and it fires `RecipeRepository.translateTagsBestEffort()`
  unawaited rather than awaited, on `_syncNamesBestEffort`'s
  never-throws/always-logged precedent -- `revision` and `repository` are
  captured into locals before the call so the callback never touches `ref`
  after the editor disposes, bumping `recipesRevisionProvider` only when a
  row was actually written.
- **`tagLabels`** now watches `recipesRevisionProvider` as its first line,
  `RecipeList.build`'s own precedent two providers up -- a pair minted
  after the save that triggered it has no other way to reach the chips
  already on screen.

**How it was verified.** `dart analyze` -- clean. `make lint-functions` --
clean (typecheck, lint, format). `make test-functions` -- 161 passed,
including the new `translate_tags_test.ts` (`alignTags`: exact match sorted
by key, a missing/extra/duplicated key each throw, the empty batch, and a
guard on the prompt's own key-echo and Latin-script sentences). `flutter
test` -- 546 tests, including two new `translateTagsBestEffort` cases (a
successful call returns `true`, a throwing remote returns `false` rather
than propagating). `make test-sql` -- all green (no migration in this
slice, so no schema drift to check). `make check` was not run directly --
it still stops at the pre-existing, unrelated `seed-check` failure tracked
since `c8be2bc` (`docs/STATE.md`); the four checks above were run
individually instead, matching the slice's own acceptance criteria.

Migration 21 was pushed to hosted (`make db-push`), `translate-tags` was
deployed (`supabase functions deploy translate-tags`), and a release build
against hosted was installed on the physical Galaxy S25 (targeted by serial
since the Android emulator was also attached). The manual walk itself --
saving a recipe with a brand-new Serbian tag, confirming the chip relabels
when switching the app's language to English, and confirming a second save
makes no second model call -- was handed to the user to run by hand and had
not been confirmed back as of this entry.

---

### Part 2 — Tags from the search box

**Status: complete** (`d73e34f`). Decisions taken during it: D110–D111.

Typing in the recipe list's search field now finds recipes by tag as well as
by title, case- and diacritic-insensitively, matching any known spelling of
the tag -- the spelling as typed on the recipe, plus every locale's row in
`recipe_tag_names`. Folded in D102's open consequence at the same time: the
Favorites chip is now reachable from a household with no tags at all. One
predicate changed, one visibility rule changed; no SQL, no migration, no new
package -- matching the slice's own scope exactly.

- **`RecipeFilter.apply`** (`lib/features/recipes/domain/recipe_filter.dart`,
  new) is `RecipeRepository._filtered`'s logic extracted to a pure-Dart file,
  `RecipeTag`'s own shape (static helpers over `List<Recipe>`, no Flutter or
  Supabase import). `query` now matches when the normalized title contains
  the term OR any tag does, under its own spelling or any spelling in
  `spellingsByKey` (D110); `tag` and `favoritesOnly` are unchanged --
  whole-token, AND-composed.
- **`RecipeRepository.watchList`** resolves the `tagKey -> {normalized
  spellings}` map once per call, only when `query` is non-empty, from
  `_local.readTagNames` -- local cache only, reusing `fetchTagLabels`'s
  existing `_tagLabelsByLocale` grouping helper via a new `_spellingsByKey`
  wrapper -- and reuses the same map for both the cached and post-sync
  emissions (D67's rule, unchanged: whatever the predicate becomes applies
  identically to both). A cold tag-name cache degrades silently to as-typed
  matching, since `readTagNames` already swallows its own errors.
- **`_FilterRow`** (`recipe_list_screen.dart`) now watches
  `recipeListProvider()` (the unfiltered list) instead of the tag vocabulary
  to decide whether to render, closing D102's own named gap (D111). The
  "filter already selected" clause keeps the row from disappearing under an
  in-flight reload.
- `recipeTagsProvider` was deliberately left untouched, per the slice's own
  settled answer: chips still reflect the unfiltered list, so widening back
  out from a narrowed query is always possible.

**How it was verified.** `dart analyze` -- clean. `flutter test` -- 558
tests (546 before this slice, plus 12 new: eight pure-Dart `RecipeFilter`
cases, two `RecipeRepository.watchList` offline cases against a real
in-memory `AppDatabase` -- a translated-spelling match and a cold-cache
degrade -- and two widget cases on the list screen -- typing a tag narrows
the list, and a tagless household still shows Favorites). One pre-existing
widget test (`a favorited, rated recipe shows a star and the rating`) needed
its finder scoped to the recipe's own `ListTile`, since the now-always-
visible Favorites chip carries a second star icon as its avatar. `make
check` stopped at the same pre-existing, unrelated `seed-check` failure
tracked since `c8be2bc` (`docs/STATE.md`); `dart analyze` and `flutter test`
ran green ahead of it, and nothing in this slice touches SQL or Edge
Functions, so `test-sql`/`test-functions` had nothing new to exercise.

A release build against hosted was installed and launched on the physical
Galaxy device (by serial, since the Android emulator was also attached) in
the same sitting, specifically so 1b's already-minted `posno`/`lenten` pair
would be on hand to demonstrate translated-spelling search. The manual walk
itself -- typing `posno` and `lent` and confirming both find the same
recipe in each app language, confirming a title match and a tag match both
appear together, confirming a chip tap still narrows by whole token, and
confirming the Favorites chip on a tagless household -- was handed to the
user to run by hand and had not been confirmed back as of this entry, so it
joins the other three open device-walk loops rather than closing any of
them.

---

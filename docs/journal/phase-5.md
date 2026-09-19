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

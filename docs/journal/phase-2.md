# Journal — Phase 2

Verbatim build history for Phase 2 — Meal plan, shopping list, offline cache, moved out of `docs/ROADMAP.md` so the roadmap stays a forward-looking index. Nothing here is authoritative going forward -- see `docs/decisions/` for standing rules, `docs/STATE.md` for current status.

---

## Phase 2 — Meal plan, shopping list, offline cache

### Part 1 — Recipe photo upload

**Status: complete.** Decisions taken during it: D48.

A Storage bucket, `storage.objects` policies scoped by household, a path
convention, and a picker package (rule 8 — no new package needed;
`image_picker` was already approved in 1d part 5). Moved here from 1c; the
`recipes.image_path` column had shipped empty since migration 8 (D35).

- `recipe-images` bucket: private, 5 MB, images only, at
  `{household_id}/{name}.jpg` — the same shape as `import-uploads` (D46),
  reusing `storage_path_household(text)` rather than a second copy of it
- `RecipeRepository.uploadImage` / `deleteImage`, and `_withImageUrls`
  resolving `Recipe.imageUrl` from `Recipe.imagePath` via
  `createSignedUrlsResult` — one round trip per list page, the same shape as
  `_withDisplayNames`
- `RecipeEditor.save({image})`: the upload happens first, inside the save,
  never at pick time — an abandoned editor writes nothing to Storage. Replacing
  or clearing a photo deletes the old object once the row no longer points at
  it, best-effort
- The photo card in the edit screen (Camera / Gallery / Remove, 1200px/85%),
  the hero image on the detail screen, and the list thumbnail

**Done when:** you can photograph a dish (or pick one from the gallery) while
editing a recipe, save, and see it on the recipe detail screen and as a
thumbnail in the list — on a second device in the same household, and not from
another household. — **Met**, verified end to end on the Android emulator
against the local stack: created a recipe with a photo (the `create()` path),
confirmed the object landed at `recipe-images/<household_id>/…` and the
thumbnail rendered in the list; replaced the photo and confirmed the old
object was gone; removed the photo and confirmed `image_path` went null and
the object was deleted; picked a photo and abandoned the editor without saving
and confirmed no object was ever written; and confirmed directly against
`is_household_member(storage_path_household(...))` that a second household's
member is refused the first household's object path.

### Part 2 — The meal plan

**Status: complete.** Decisions taken during it: D49–D54.

`meal_plans` + `meal_plan_entries` with RLS, a week grid replacing the
`PlaceholderScreen` the Plan tab has shown since Phase 0, and the ability to
add, move and remove a recipe or a note in any of a week's 28 slots.
**Leftover entries and the snack variety check are explicitly out** —
`leftover_of_entry_id` and `'leftover'` ship in the migration, unreachable,
the same way `recipes.image_path` shipped empty under D35.

- `meal_plans` (one row per household per week, created lazily on the first
  write — D50) and `meal_plan_entries` (a child table in the D24 sense: no
  lifecycle columns of its own, hard delete allowed — D49), plus
  `ensure_meal_plan()`, `meal_plan_entries_before_write()` (position
  assignment, the week-boundary guard, the leftover visibility guard) and
  `meal_plan_entries_touch_plan()` (keeps the plan's `updated_at` current for
  the Phase 2 delta fetch, however entries change)
- `MealPlanRepository`: `fetchWeek`, `addRecipeEntry`, `addNoteEntry`,
  `moveEntry`, `removeEntry` — every write lands immediately, no draft, no
  Save (D54)
- `VisibleWeek` (the one week on screen) and `MealPlanEditor`
  (`AsyncNotifier`, not a family) in `application/`; `plan_week.dart` in
  `domain/` is the one file in the feature that does date arithmetic
- The recipe picker moved to `core/recipes/`, alongside `core/ingredients/`
  (D43) — the second time a feature needed to reach `recipes/` read paths
  without importing its `application/` layer (D53)
- `currentHouseholdId` closed D33's open note: a derived provider in
  `core/household/`, not a third copy of the query (D52)

**Done when:** you can open the Plan tab, walk to any week, put recipes and
notes into that week's 28 slots, move them between slots, take them out, and
see the same week on a second device in the same household. — **Met**,
verified end to end on the Android emulator against the local stack, not
only in the 26-assertion SQL suite (`rls_meal_plans_test.sql`) and the 31
Dart tests it sits beside. Browsing several weeks back and forward wrote
`meal_plans`.count = **0** the whole time (D50). Adding a recipe created
exactly one plan row for the week regardless of how many entries later
landed in it; two recipes added to the same slot got `position` 0 and 1 from
the server, never the client. A note was added, then moved to a different
day via the entry's "Move to…" action — its `entry_date`/`slot` changed and
`position` was recomputed at the new slot's tail, and `meal_plans.updated_at`
moved on that write, live over the wire (not just inside the SQL suite's own
frozen-transaction workaround for it). Removing an entry was a real row
deletion, confirmed by a shrinking count, not a tombstone. Force-stopping and
relaunching the app showed the identical week untouched — nothing here is
client-only. Household isolation is covered by the SQL suite's own
non-member assertions rather than repeated with a second device, the same
call D48's verification note makes for the recipe-images bucket.

### Part 3 — Leftovers, variety and order

**Status: complete.** Decisions taken during it: D55–D58.

The three items D51 and D49 left named and unreachable in the meal plan:
leftover entries actually writable, the snack variety check, and within-slot
reordering.

- `meal_plan_entries_leftover_source`, a second `before insert or update`
  trigger alongside migration 14's own (never edited -- CLAUDE.md), derives
  `recipe_id` onto a leftover row from its source entry and refuses anything
  else -- a note as a source, another leftover as a source (no chains), or a
  leftover pointing at itself (D55). This is what closes D51's deliberately
  loose `'leftover'` check branch: the client never sends `recipe_id`, and a
  value nothing derives or checks is a value that could otherwise quietly
  drift from its source
- `reorder_meal_plan_entry(entry, new_position)`, the RPC D49 named --
  renumbers a whole `(meal_plan_id, entry_date, slot)` group in one
  statement rather than swapping two rows, because D49 already ruled out a
  unique index on `position`, so gaps are legal input and the renumber has to
  tolerate them (D57)
- `MealPlanRepository.addLeftoverEntry`, `.reorderEntry`,
  `.countRecipeInSlot` -- the last scoped to household and to visible plans
  through a `meal_plans!inner` embed, because RLS alone would also count a
  slot in any *other* household the caller belongs to
- `snack_variety.dart`: a centred +/- 7-day window around the candidate date,
  not the trailing "last 14 days" `docs/DATA_MODEL.md` originally sketched
  (D58) -- a meal plan is forward-looking, and a trailing window only warns
  when slots happen to be filled in calendar order
- Screen: *Plan leftovers...* on a recipe entry's action sheet (not offered
  on a note or another leftover), a 14-day destination picker starting the
  day after the source, *Move up* / *Move down* shown only where there is
  somewhere to go, and an advisory Cancel/Add-anyway dialog before a repeated
  snack is actually written -- the check never blocks the write itself, only
  asks first

**Done when:** a cook can put the same recipe's leftovers in a later slot,
get warned (not stopped) about a snack repeating within a fortnight either
side, and reorder entries sharing a slot. — **Met**, verified end to end on
the Android emulator against the local stack (UI Automator dumps to locate
elements precisely, not eyeballed coordinates), not only in the 20-plus new
SQL assertions (`meal_plan_leftovers_test.sql`) and the Dart tests beside it.
Planning Thursday dinner's leftovers defaulted the dialog to Friday, same
slot, exactly D56's "source date + 1, source's own slot"; retargeting it to
the following Monday's dinner produced a chip reading `Leftovers: <title>`
with the replay icon, opened the source recipe from it, and a direct query
confirmed the row's `recipe_id` matched the source's exactly — the client
never sends one, so this is the derivation working through the real app, not
just the SQL suite's separate check that a *wrong* client-sent value gets
overwritten. That Monday write landed in a second `meal_plans` row
(`meal_plans` count moved from 1 to 2) that did not exist a moment before,
invisible until the grid was paged forward into the following week — D56's
known consequence, not a bug. Removing the source entry took its leftover
down with it, confirmed by a zero count where the leftover row used to be.
Three entries added to one slot, the last moved up once from the action
sheet: a direct query showed the moved row's `position` change from 2 to 1
and its sibling shift from 1 to 2, with no gap or duplicate across the group,
and `meal_plans.updated_at` moved on that reorder alone — the one write that
changes no other column on the plan row, so the touch trigger is the only
thing that could have moved it. Adding the same recipe to a third snack slot
within a few days of two earlier ones surfaced the count in the warning text
verbatim (`Already in 2 snack slots this fortnight.`); Cancel left the row
count at zero, Add anyway wrote it, and three earlier additions of the same
recipe to a lunch slot never triggered the dialog at all.

One call made here for the next part rather than this one: the shopping
list's pantry staples (salt, oil, sugar, water, pepper) will be aggregated
and flagged like anything else, then rendered collapsed under a "Probably
have" heading rather than hidden -- `household_pantry_prefs` stays a
both-directions override on the flag, and nothing is ever missing from the
snapshot itself.

### Part 4 — The shopping list

**Status: complete.** Decisions taken during it: D59–D63.

The List tab has shown `PlaceholderScreen` since Phase 0. A week's plan now
aggregates into a saved, correct list.

- Migration 16: `shopping_lists` (household-scoped, so full rule 4 — D59's
  correction to the sketch, which omitted `updated_at`), `shopping_list_items`
  (a D24 child table, RLS through its parent) and `household_pantry_prefs`
  (a join table, hard delete, on the `household_members` precedent migration 6
  had already applied to it), plus `save_shopping_list` — the parent and its
  items in one transaction, `security invoker` (D61, the third outing of D36's
  argument)
- `Rational` and `aggregate_shopping_list` in `domain/`, pure Dart, no I/O:
  skip leftovers and notes, scale by servings, group by `ingredient_id` and
  fall back to `normalize_text(raw_text)`, convert to the family's base unit
  and sum within a family only (D9), flag staples with the household's
  override winning both ways
- **The sum is exact all the way through** (D60). `units.to_base` is read from
  the `numeric` as text rather than through its `double`, because every value
  in that column is an exact decimal; `quantities` stores an integer pair, not
  a rounded number. `Quantity`'s own doc comment predicted this slice by name
- `RecipeRepository.fetchLinesForRecipes` — one query for a whole week's lines
  however many recipes it names, embedding the catalog's `is_pantry_staple`
  and `category`, reusing the existing `_withDisplayNames`
- *Cooking for…* on the meal plan entry's action sheet (D62). This is what
  makes scaling real: `meal_plan_entries.servings` shipped in migration 14 and
  **nothing had ever written it**, so the documented "scale by servings" step
  was a no-op that only the real app could expose
- Screen: range bar (this week / next / date picker), items grouped by
  category with uncategorised last, two families side by side on one line,
  unmatched lines verbatim beneath their group, and staples collapsed under
  *Probably have* — collapsed, never hidden (D63). No checkboxes, and there
  never will be (D13)

**Done when:** a week's plan produces a correct list. — **Met**, verified end
to end on the Android emulator against the local stack, not only in the 51
Dart tests and the new SQL suite. A week holding two recipes that share an
ingredient, one of them also planned as leftovers, produced: *brašno* 400 g
from `250 g` + `150 g` across two recipes as a single line; *mleko* 280 ml
from `2 dl` + `⅓ šolje` — 200 + 80 exactly, which is the exact-rational path
doing the one thing a `double` gets wrong; *jaje* 2 kom; and **nothing at all
from the leftover**, which would otherwise have added another 250 g. Setting
that entry to 8 servings against the recipe's 4 and regenerating moved those
to 650 g, 480 ml and 4 kom — the fraction scaled exactly, not approximately.
`prstohvat soli` came back with no quantity and its raw text intact: the
`other` family is carried as a note and never summed, which is rule 3 and
migration 4's own comment agreeing. Regenerating soft-deleted each previous
list rather than removing it (1 live, 3 tombstones by the end). Toggling
*šećer* out of the cupboard wrote an `always_have = false` row, left the
on-screen snapshot untouched on purpose, and moved the item into the pantry
section on the next generation. A second household was confirmed to see
neither the list nor its items.

Two things the emulator caught that tests had not. An unmatched item rendered
its own name twice — once as the title and once as its "unmatched line",
because for an unmatched line those are the same string; the aggregator now
drops an unmatched line equal to the item's name. And `480 ml` first rendered
as `4.8 dl`: the display ladder had included decilitres, which is a recipe
unit, not a shopping one — nothing on a shelf is labelled 4.8 dl.

Still open, and named here so it is not rediscovered: **a generated list is
never compared against the plan it came from.** Changing the week after
generating leaves a list that is quietly stale, and the only signal is the
`Generated <date>` line. `CurrentShoppingList` already watches
`mealPlanRevisionProvider`, so the hook is there; what to *show* is a design
question, not a plumbing one. Unrelated to, and not resolved by, part 5's
offline signal below — that is about whether the phone can reach the server,
not whether the plan has moved on since the list was generated.

### Part 5 — The Drift read cache, proven on the shopping list

**Status: complete.** Decisions taken during it: D64–D71.

The airplane-mode half of part 4's "Done when" — a week's plan produces a
correct list, *and that list is readable in airplane mode*. Everything in the
tree had been arranged for this in advance and was sitting unused:
`tool/check_layers.dart` already refused `drift` outside `data/`, D23 already
kept tombstones visible so a delta fetch could see them, D59 already put
`updated_at` on `shopping_lists` naming this exact part, and
`IngredientRepository.fetchUnitCatalog`'s own doc comment already said "it
still works offline once Phase 2 caches it." Built on the shopping list and
the unit catalog only — the roadmap's own argument for going first: one row,
no write path, no tombstone churn, and the reason the cache exists at all
(D12). The unit catalog joined it out of necessity, not scope creep: without
it, an offline list renders `1200 g` and `3 clove` instead of `1.2 kg` and
`3 čen`, because `formatItemQuantity` finds no `kg`/`l` rung and
`UnitCatalog.displayName` falls back to a raw code on an empty catalog —
exactly what `shopping_list_screen.dart`'s old
`ref.watch(unitCatalogProvider).value ?? UnitCatalog.empty()` fallback
produced the moment the network failed.

- `drift`, `drift_flutter`, `path_provider` (rule 8, asked and approved);
  `sqlite3_flutter_libs` was the package actually approved, but its own
  pub.dev listing now reads "Not used anymore, update to version 3.x of
  package:sqlite3 instead" — `drift_flutter` is what drift's own setup guide
  replaced it with, and it also removes the hand-written platform opener.
  `connectivity_plus` was asked about and rejected: `NetworkFailure` already
  exists and `runGuarded` already produces it from a `SocketException`, a
  `TimeoutException`, or `FunctionException(status: 0)`
- `lib/core/db/app_database.dart`: one `AppDatabase`, two tables
  (`ShoppingListCache`, `UnitCatalogCache`), `schemaVersion = 1` with
  drop-and-recreate as the whole migration strategy (D71) — `core/db/`
  because a single SQLite file is inherently shared, on the same
  `tool/check_layers.dart` exemption `core/supabase/` already has (D64).
  `lib/core/db/cache_guard.dart`'s `cacheOrElse`/`cacheWrite` are what keep a
  corrupt cache file from ever reaching `runGuarded` and rendering as
  "Something went wrong" (D69)
- `RemoteShoppingListDataSource`/`LocalShoppingListDataSource`, the first
  actual instance of the Remote/Local split `docs/ARCHITECTURE.md` had only
  sketched, composed by a much smaller `ShoppingListRepository`; one shared
  wire decoder, `dto/shopping_list_dto.dart`, reads a PostgREST row and a
  cache blob identically (D65). `ShoppingList` gains `updatedAt`, populated
  truthfully from day one even with no delta fetch yet to read it (D71).
  `LocalShoppingListDataSource.upsertLatest` deletes the household's row
  before inserting the new one, found necessary by the first test written
  against it — a plain `insertOnConflictUpdate` only resolves against the
  primary key, so a regenerated list (a new id) would otherwise try to
  insert a second row (D66)
- `watchLatest()`: cache emission, then the network's answer, over a
  `CurrentShoppingList` that is now a `StreamNotifier` rather than an
  `AsyncNotifier` — the provider's value type is unchanged
  (`AsyncValue<ShoppingList?>`), so every existing screen and test kept its
  shape. A cache hit outlives a `NetworkFailure`; a cold cache does not, and
  says so in its own sentence rather than rendering an empty state that
  implies nothing was ever generated. Reachability is
  `lib/core/net/network_status.dart`'s `NetworkStatus`, reported through
  plain callbacks so the repository stays a `data/` file that has never heard
  of Riverpod (D67)
- `IngredientRepository.fetchUnitCatalog()`: network-first, the cache only as
  a `NetworkFailure` fallback — the opposite read order from the shopping
  list, because two dozen immutable reference rows have no `updated_at` to go
  stale between sessions, so there is nothing to gain from showing a cached
  answer before a fresh one a moment later (D70). Deliberately not split into
  a full Remote/Local pair: this is one cached method out of six, and the
  other five reach a live catalog by design
- Sign-out wipes the household-scoped cache and deliberately leaves the unit
  catalog alone — global reference data, readable by any authenticated user,
  and wiping it would put `3 clove` back on the very next person's first
  offline session (D70)
- `_ListBody` no longer treats "the catalog is still loading" as "the catalog
  is empty" — a real gap the old `?? UnitCatalog.empty()` fallback had online
  too, just imperceptibly; `_GeneratedAt` gains one line, "Showing your saved
  copy — no connection.", exactly where a cache hit is being shown. A global
  offline banner is still a later part's job

**Done when:** a week's plan produces a correct list, and that list is
readable in airplane mode. — **Met**, verified end to end on the Android
emulator against the local stack, not only in the 18 new Dart tests (a
round-trip test proving the cache preserves an exact `Rational` — 280 ml from
`2 dl` + `⅓ šolje`, 200 + 80 exactly — and `prstohvat soli`'s raw text with no
quantity; a repository-level test proving a warm cache survives a
`NetworkFailure` quietly while a cold one rethrows honestly; a unit-catalog
round-trip test proving `to_base` survives as the string `28.349523125`, not
a rounded double). Generated a list online for a week naming a mass total
over 1 kg and a `veza peršuna`; confirmed on screen as `1.2 kg` and `1 veza`.
Enabled airplane mode, force-stopped and relaunched cold: the full list
rendered from the cache with no network at all, quantities and count units
identical to the online render, with "Showing your saved copy — no
connection." under the generated line. Tapping *Regenerate* offline produced
a snackbar and left the on-screen list untouched — writes stayed online-only
(D12). Disabling airplane mode and pulling to refresh cleared the saved-copy
line and re-rendered from the network. Regenerating online, then going
offline again, served the *new* list, not the retired one — the D59 case this
cache exists to get right, and the case D66's delete-then-insert fix made
correct in the first place. Signing out and reading the on-device cache file
directly showed the household's `shopping_list_cache` row gone and the
`unit_catalog_cache` row untouched; signing back in and going straight to
airplane mode without generating anything rendered no list (correct) with
count units still in Serbian (correct, D70's argument holding).

### Part 6a — The delta fetch, and recipes and the ingredient catalog offline

**Status: complete.** Decisions taken during it: D72–D74.

D71's own deferral, closed: `last_sync_at`-style delta fetch, and the two
entities it needed a real multi-row fetch to be designed against.

- `SyncWatermarks` (`core/db/`) — one row per `(entity, scope)`, advanced
  from the max `updated_at` of the rows a fetch actually received, never
  `DateTime.now()` (D72). `AppDatabase.schemaVersion` moved to `2`
- `DisplayNameChain` (`features/ingredients/domain/`) — `ingredient_display_name()`'s
  fallback chain, ported to Dart against `test/fixtures/display_names.json`,
  asserted on both sides the same way `normalize_text()`/`TextNormalizer`
  already are (rule 6, D72). `tool/gen_display_name_sql.dart` generates the
  Postgres half exactly as `gen_normalization_sql.dart` does
- `RecipeCache` and `IngredientNameCache` (`core/db/`), and the Remote/Local
  split's second and third outings: `RemoteRecipeDataSource`/
  `LocalRecipeDataSource` compose into `RecipeRepository`, which now caches
  the household's recipes AND the global ingredient name catalog — the
  latter a deliberate ownership choice (D73) rather than an oversight:
  `ingredient_display_names` has exactly one caller, and the layer boundary
  (D33) forbids `recipes/data/` reaching `ingredients/data/` directly, so
  the cache and its sync stay where the one caller is until a second exists
- `watchList()` — cache-then-network for the whole recipe list, the same
  shape `ShoppingListRepository.watchLatest` established; local search
  matches the server's old `ilike` results exactly, since both compare the
  same `normalize_text()`-derived value (rule 6). `fetchDetail()` stays
  network-first with a cache fallback instead (D74) — closer to
  `fetchUnitCatalog()`'s shape than the list's, because a single recipe
  read on demand has little to gain from a stale-then-fresh emission
- `recipeListProvider` is now a `StreamNotifier` family; `recipeDetailProvider`
  is unchanged, a plain `Future` — D74's whole point, and the reason only
  the list's screen test needed a stub rewritten
- A recipe's own online detail read now also triggers a best-effort
  background sync of the *whole* global name catalog, not just the ids that
  recipe mentions — closing "every ingredient renders offline, including
  ones never viewed"

**Done when:** recipes and the ingredient catalog are readable offline, the
same way the shopping list and unit catalog were in part 5. — **Met in
tests and against the local Postgres stack, not verified on the emulator.**
18 new Dart tests: the watermark advancing to the max `updated_at` received
rather than `now()`; the recipe cache's household scoping and ordering; an
id cached without embedded lines reading back as an honest detail-cache
miss even though it is a list-cache hit; `DisplayNameChain` resolving a
real cached row set through every clause of the fallback order; and
`RecipeRepository.watchList`/`fetchDetail`'s cache-then-network and
network-first-with-fallback behaviour respectively, including a
soft-deleted row in a delta evicting its cached copy. Six
`display_names.json` fixture cases pass identically in
`display_name_chain_test.dart` and in `display_names_test.sql` run against
the real `ingredient_display_name()` function — `make test-sql` in full,
`make check` in full, `dart analyze` and `tool/check_layers.dart` both
clean. **Not yet exercised on the Android emulator** — the actual "open a
recipe online, go to airplane mode, force-stop, relaunch, see it render
with Serbian catalog names on matched lines and a photo placeholder" walk
every prior part in this phase closed with — is the one verification step
still open, named here rather than left to be assumed.

### Part 6b — Meal plan weeks offline, and the global offline signal

**Status: complete.** Decisions taken during it: D75–D76.

The last entity on Phase 2's offline list, plus the global banner the
Done-when has always asked for. `SyncWatermarks` and the delta-fetch shape
were already proven in part 6a; the correction here is the watermark's
scope (D75, replacing the per-`(household_id, week_start)` sketch this
section used to carry) and `meal_plan_entries_touch_plan()` (migration 14),
already in place, is what makes `meal_plans.updated_at` trustworthy for it.

- `MealPlanWeekCache` (`core/db/app_database.dart`), keyed by `id` on
  `RecipeCache`'s precedent (a plan's id never changes under
  `ensure_meal_plan`'s upsert) with a `(householdId, weekStart)` unique-key
  belt-and-suspenders on `ShoppingListCache`'s. `weekStart` is stored as
  text, not a `DateTimeColumn` -- `plan_week.dart` forbids `.toUtc()` on a
  plan week, and a `DateTimeColumn` round-trips through a local-time epoch
  conversion that would shift it. `schemaVersion` moved to `3`
- `dto/meal_plan_week_dto.dart` -- decoders only, on `recipe_dto.dart`'s
  precedent rather than `shopping_list_dto.dart`'s: a cached week is never
  built from a domain object, only read off the wire and stored as-is
- `RemoteMealPlanDataSource` / `LocalMealPlanDataSource` /
  `MealPlanRepository`, the fourth outing of the Remote/Local split. Every
  write from the old single-file repository moved to the Remote half
  unchanged; the read became `watchWeek()`, cache-then-network on
  `RecipeRepository.watchList`'s shape, widened from one week to a whole
  household's meal-plan history so paging stays instant offline (D75)
- `MealPlanEditor` became a `StreamNotifier<MealPlanWeek>` on `RecipeList`'s
  own precedent -- the value type consumers see
  (`AsyncValue<MealPlanWeek>`) is unchanged, and the only test cost was the
  same stub-rewrite `RecipeList`'s own conversion paid
- `OfflineBanner` (`core/net/offline_banner.dart`), rendered by `AppShell`
  above every tab's body, and the meal plan screen's own "Showing your saved
  copy -- no connection." line under the week bar, on the shopping list
  screen's `_GeneratedAt` precedent (D76)
- `Makefile`'s `test-sql` target now runs `gen_display_name_sql.dart` before
  the SQL suite, closing a gap part 6a left open: the generator's own header
  already claimed this, and `supabase/tests/display_names_test.sql` could
  silently drift from `test/fixtures/display_names.json` without it

**Done when:** every entity in `docs/ARCHITECTURE.md`'s offline list --
recipes, meal plans, the shopping list, the ingredient catalog -- is readable
offline, with a global signal saying so. -- **Met for a warm session.** All
366 Dart tests pass (18 new: `local_meal_plan_datasource_test.dart`'s cache
round-trip and `uniqueKeys` guard, and `meal_plan_repository_offline_test.dart`'s full
`watchWeek` matrix -- cold cache success and failure, warm cache surviving a
`NetworkFailure`, D75's authoritative-empty case under a live watermark, a
soft-deleted plan evicting its cache entry with its still-embedded entries
ignored, the watermark advancing to the max `updated_at` received rather
than `now()`, and `onReachable`/`onUnreachable` ordering), plus new
`app_shell_test.dart` and `meal_plan_screen_test.dart` cases for the banner
and the saved-copy line respectively. `make check` in full: `dart analyze`
and `tool/check_layers.dart` both clean, `make test-sql` (now regenerating
and passing `display_names_test.sql` too), `lint-functions` and
`test-functions` unaffected since no Edge Function changed.

**"Met for a warm session" is a correction, added in Part 7.** This
Done-when was written and verified with the household already resolved --
every walk in this project up to and including this one signed in, then
tested offline behavior within the same session. Part 7 (D87) found that a
genuinely cold, offline-from-first-frame start never reached any of the
caches this part built at all: `currentHouseholdIdProvider`, which every one
of them gates on, had no cache and no bound of its own. The caches
themselves were never wrong; nothing before Part 7 had reached them under
the one condition that mattered.

### Part 7 — The household cache, and a bounded household read

**Status: complete.** Decisions taken during it: D87 (the finding), D88–D90
(the fix). Built during Phase 3, filed here because the gap it closes was
never on Phase 2's own offline list to begin with -- a reader looking for why
Part 6b's claim above needed correcting finds it at the end of Phase 2, not
in the middle of the localization phase.

- `CurrentHouseholdCache` (`core/db/app_database.dart`) -- the first
  PER-USER table in a database that has so far only ever been per-household
  or global. Keyed on the signed-in user's id, storing the raw `households`
  wire row; `dto/household_dto.dart`'s `householdFromWire` decodes a fresh
  response and a cache hit identically (D65, D88). `schemaVersion` 4 -> 5.
  `clearHouseholdCache()` (the sign-out wipe) drops it too, belt-and-braces
  alongside the structural guarantee the per-user key already gives
- `features/households/data/` took the Remote/Local split -- the fourth,
  after shopping_list/recipes/meal_plan -- for a reason none of the first
  three needed: without `RemoteHouseholdDataSource.fetchMineRows()` as a
  fakeable seam, the read order this part depends on would have shipped
  untested, the exact gap that let D87 through in the first place (D90)
- `HouseholdRepository.fetchCurrent(userId:)` -- network-first with a cache
  fallback, `IngredientRepository.fetchUnitCatalog()`'s shape (D70): success
  writes the chosen row through (or clears it, if the caller genuinely has
  no household -- the branch keeping a miss unambiguous); a `NetworkFailure`
  reads the cache; a cold cache rethrows. Deliberately not cache-first --
  `CreateHouseholdScreen`/`JoinHouseholdScreen` both invalidate and re-await
  this provider expecting a fresh read (D88)
- `create()`/`redeemInvite()` clear the whole cache on success, closing a
  failure mode the fallback would otherwise introduce: switch households,
  then hit a network blip on the confirming re-fetch, and without this the
  old household would silently come back instead of the redirect correctly
  stalling in onboarding (D88)
- The bound that actually shortens the wait: `fetchMineRows()` chains
  `.retry(count: 1, requestTimeout: 5s)` on the one call. A global
  `Supabase.initialize(postgrestOptions:)` timeout was the first design and
  is NOT what shipped -- verified directly against the pinned package source
  that `SupabaseClient.from()` forwards only `schema` from
  `PostgrestClientOptions`, never `requestTimeout` or `retryCount`, so it
  would have changed nothing about the call that was actually hanging (D89)
- `currentHouseholdProvider` now reports into `NetworkStatus`
  (`onReachable`/`onUnreachable`), on the three screen providers' own
  precedent -- closing the reason the global offline banner could never
  appear on a cold start at all: every one of its producers sat behind this
  same gate

**Done when:** a cold start with no network shows cached content within
seconds rather than hanging for minutes, and the offline banner appears. --
**Met**, verified end to end on the Android emulator against the local
stack, not only the 18 new Dart tests (`household_cache_test.dart`'s
round trip and wrong-user isolation, `household_repository_offline_test.dart`'s
full network-first/cache-fallback/cold-cache-rethrows/wrong-household-eviction
matrix on `_FakeRemote implements RemoteHouseholdDataSource`, and
`app_shell_test.dart`'s new redirect case for the `AsyncError.hasValue ==
false` state). `make check` in full: `dart analyze` and
`tool/check_layers.dart` both clean, 417 Dart tests, `lint-functions` and
`test-functions` unaffected since no Edge Function changed.

This is the same walk that found D87: sign in, translate and review a
recipe so the caches are genuinely warm (not a fixture), pull the on-device
cache file directly to confirm `current_household_cache` holds one row keyed
by the signed-in user's id with a `household_id` matching the recipe's own,
then disable the emulator's network, force-stop and relaunch cold. Where the
pre-fix walk spun for several minutes before failing, this one showed the
cached recipe with its *Draft* chip **and** the global offline banner --
"You're offline -- showing saved copies. Changes won't save." -- within
about 30 seconds of a cold launch on this same slow emulator, the banner's
first appearance ever on a cold start. Re-enabling the network and
relaunching cleared the banner and rendered normally. Signing out and
reading the cache file directly showed `current_household_cache` and
`recipe_cache` both at zero rows, with `unit_catalog_cache` still holding
its one row -- the sign-out wipe and D70's split both holding under the new
table.

Not walked separately, because it is what the sign-out result above already
proves: a second user signing in on the same device cannot see a leftover
row, since sign-out left none to see. The wrong-user case itself --
a cached row present for one user id and never returned for another -- is
`household_cache_test.dart`'s own assertion, not left to the emulator alone.

---


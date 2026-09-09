# Roadmap

Build in this order. Finish and verify a phase before starting the next. Within
a phase, build vertical slices — schema, repository, provider, screen — one
feature at a time, not all schema then all UI.

---

## Phase 0 — Foundations

**Status: complete** (`392ab96`). Decisions taken during it: D19–D24.

No product features. This exists so nothing later has to be undone.

- `flutter create`, package structure per ARCHITECTURE.md, empty feature folders
- `analysis_options.yaml` strict, `riverpod_lint` wired via `plugins:` (D20)
- `tool/check_layers.dart` — fails if `presentation/` imports `data/`, or if
  `supabase_flutter` appears outside `data/` and `core/supabase/`
- `build_runner` working; one throwaway freezed model to prove it
- Supabase project + local `supabase start`; migration 1 = extensions,
  `normalize_text()`, `updated_at` trigger function
- `TextNormalizer` in Dart + `test/fixtures/normalization.json` + tests on both
  sides (Dart test, and a SQL test that asserts the same pairs)
- `go_router` shell with four empty tabs
- Makefile: `types`, `gen`, `lint`, `db-reset`

**Done when:** `dart analyze` is clean, layer check passes, normalization tests
pass in both Dart and Postgres, app runs and navigates between four blank tabs.

---

## Phase 1 — Recipes, households, import

### 1a. Auth + households

**Status: complete** (`7fe319a`, then the invites slice). Decisions taken
during it: D25–D26.

- Supabase Auth (email OTP is simplest; skip social for now)
- `profiles`, `households`, `household_members`, `household_invites` + RLS
- `is_household_member()` helper, applied to one table to prove the pattern
- Edge Functions: `create-invite`, `redeem-invite`
- Screens: sign in, create household, join by code, member list

**Done when:** two accounts on two devices are in one household, and each can
see a row the other created. — Met. There are no recipes until 1c, so the rows
shared are the household and the membership rows: the joiner sees the household
the inviter named, and both members by name. `supabase/tests/` covers the same
ground with the negative cases.

### 1b. Ingredient catalog

**Status: complete.** Decisions taken during it: D27–D32.

- `ingredients`, `ingredient_names`, `units`, `unit_names`, indexes
- Seed: 200 ingredients + 618 names from CSV (see INGREDIENTS.md), applied as a
  generated idempotent migration rather than `seed.sql` (D29)
- `merge_ingredients()` function
- Matching tiers 1–3 (parse, exact, fuzzy). **Tier 1 is a pure Dart parser and
  tiers 2–3 are one Postgres RPC + Dart wrapper** — this line originally said
  all three were the RPC, written before the client/edge split settled. Tier 1
  touches no data, and a round trip per line would break both the 1c line
  editor's responsiveness and Phase 2's offline entry. See D31. No LLM tier yet.

**Done when:** typing "cufte" or "sargarepa" in a search RPC returns the right
ingredient, and `merge_ingredients` correctly repoints rows. — Met, with one
correction. `sargarepa` is asserted literally, along with `šargarepa`,
`ШАРГАРЕПА` and `Šargarepa` all reaching the same row, plus the genitive
`sargarepe` through a seeded alias and `flour` reaching *brašno* and rendering
in Serbian. **`cufte` is not asserted**: ćufte is a dish, not an ingredient —
the string comes from the normalization fixture list in INGREDIENTS.md, which
is about `normalize_text` rather than about the catalog. The
diacritic-insensitive search it stood for is asserted directly instead.
`merge_ingredients` is covered by `supabase/tests/merge_ingredients_test.sql`
including both refusals, the grant, and an FK-coverage assertion that will fail
in 1c if `recipe_ingredients` is added without being handled.

### 1c. Manual recipe entry

**Status: complete.** Decisions taken during it: D33-D37.

- `recipes`, `recipe_ingredients`, `recipe_steps` + RLS, plus
  `replace_recipe_lines` and `ingredient_display_names`
- Recipe list (search by `title_normalized`), detail, create/edit, soft delete
- `create_ingredient` and `link_ingredient_alias` -- the narrow catalog write
  path D32 deferred to this phase
- Ingredient line editor: local parse on every keystroke, debounced
  `search_ingredients`, a chip showing quantity / unit / matched name,
  "create new" as the last option in the picker, and alias write-back on a
  human decision
- ~~Photo upload to Storage~~ -- moved to Phase 2 (D35). `recipes.image_path`
  ships in the 1c migration so that slice is a feature and not a migration
  against existing rows.

**Done when:** you can type in a recipe you know by heart, in Serbian, and
every ingredient line either matched or deliberately created a new ingredient.
-- Met. Fraction-aware quantity input is there but not as a separate field:
lines are raw-text-first, one field holding what the cook typed, and the
quantity is parsed out of it and shown back as an exact fraction on the chip
(`1½`, never `1.5`). That is rule 3 expressed as UI, and it is what lets an
unparsed line still save and still render.

The two things Phase 1b built and never exercised now have callers:
`search_ingredients` is the line editor's autocomplete, and
`merge_ingredients` has a real `recipe_ingredients` table to repoint.

Verified end to end on the emulator against the local stack, not only in
tests. Typing `200 g sargarepe` -- no diacritics, genitive -- auto-accepted to
*šargarepa* and saved `match_method = 'alias'` at confidence 1.0 with
`qty_num/qty_den = 200/1`; the detail page renders the catalog's word rather
than the one typed (D1). A line the seed answers only weakly showed as a
suggestion rather than being applied, and saved unmatched with its `raw_text`
intact and its unit still parsed -- structure without a match, which is rule 3
working rather than failing.

### 1d. Import

**Status: complete** (parts 1–6). Decisions taken during it: D38–D46.

Every bullet below is done, with one deliberate exception noted at the end:
share intents work on Android and not on iOS.

**Verified end to end, including the model.** All three importers were run
against the real provider once credits existed: a Serbian recipe through
`import-text`, a JSON-LD-less page through `import-url`'s fallback, and a
rendered two-column cookbook page with a sidebar ingredient list through
`import-photo`. Tier 4 was exercised on ingredients a 200-item Serbian catalog
cannot know. Seven calls, $0.14, and `ai_usage` recorded every one with real
token counts.

That run found a bug that had been present since part 2 and could not have been
found any other way — see D47.

Part 1 built `import_jobs`, `ai_usage` and `household_ai_limits` with their RLS
and SQL tests, all five remaining `_shared/` modules, and `make types` for
real — plus `make test-functions` and `make lint-functions`, which the Makefile
had been asking for since Phase 0 and which `make check` now runs.

It also added a seventh `AppFailure` variant, `QuotaFailure`, for the codes
that mean "not now" rather than "not ever" — an exhausted AI allowance or an
upstream rate limit. A `ValidationFailure` would have told the cook to change
what they sent, which is the opposite of the right advice.

Part 2 built the server half of text import: `_shared/match.ts` (tiers 1–4 over
a whole recipe), `_shared/jobs.ts` (the `import_jobs` lifecycle), and the
`import-text` and `match-ingredients` functions. `import-text` answers with a
job id in 202 and does the work on `EdgeRuntime.waitUntil`, which is what D14's
queue actually looks like in code.

**D42, taken here: no machine tier writes to the catalog.** `docs/INGREDIENTS.md`
says every resolution writes an alias back, and it is right about why — that is
what stops the LLM tier being paid for twice. The disagreement is only about
*when*. Writing back during import makes a machine guess global and permanent
(D28: one string, one ingredient, forever) before any human has seen it, and
D8 exists precisely because a human sees every import. Tier 5 is worse still:
`za posluživanje` is a real line in the fixture, and creating an ingredient for
it at import time would enter "for serving" into the catalog as food. So the
write-back moves one screen later, to the confirm screen, which accepts by
default and already calls `link_ingredient_alias` (D34) — a function that
already writes `source = 'user'` and already means a human agreed. The cost
curve still drops on the first import of a new string; it drops after somebody
nodded at it.

That also removed a smaller problem rather than solving it:
`link_ingredient_alias` hardcodes `source = 'user'` and needs a non-null
`auth.uid()`, so a machine tier calling it would have meant either lying about
provenance — the thing D7 exists to prevent — or a migration to widen it.

The bullets below are the whole phase; the ones part 1 finished are marked.

- `import_jobs` table — **done**, with `ai_usage` and `household_ai_limits`
  alongside it (D17 wanted them from day one, and they are the same migration)
- `_shared/schema.ts` — Zod `ParsedRecipe`; `make types` producing Dart —
  **done**. Two schemas, not one: `ModelRecipe` is what a model is asked for,
  `ParsedRecipe` is what the job stores (see D41)
- Edge Functions `import-url` (JSON-LD first, LLM fallback) — **done**;
  `import-text` — **done**; `import-photo` (vision model, structured output) —
  **done**
- `match-ingredients` Edge Function — the LLM tier, batched per recipe —
  **done**. One call per recipe, choosing from candidates the catalog produced,
  so the model cannot invent an ingredient id. Also a standalone re-matching
  entry point for a job whose unmatched lines the catalog has since learned
- `_shared/usage.ts` quota check + `ai_usage` recording — **done**, along with
  `ai.ts`, `normalize.ts` and `parse_line.ts`, which ARCHITECTURE.md listed for
  1d and this bullet list never did
- Client: create job, poll, **confirm screen** — **done**. Paste a recipe from
  the recipe list's FAB menu, watch it being read, review what came back and
  save it. The confirm screen reuses the 1c line editor unchanged, which is
  what D43 moved to `core/` to allow, and it is where D42's alias write-back
  now happens — the only place the catalog grows
- `receive_sharing_intent` on both platforms — **Android done**; iOS
  deferred, see below

**Done when:** you can share a recipe URL from a browser into the app, review
what it found, and save it; and photograph a cookbook page and get a usable
draft. — **Met on Android.** Sharing a link from Chrome opens the importer
prefilled; the JSON-LD path produces a reviewable draft with no model call at
all; and a photographed page produced a correct draft that saved as `ocr`,
household-scoped, with nine matched lines and six steps. The vision model read
the sidebar ingredient list, the two-column method in reading order, and treated
the headnote as a description rather than a first step — the three things D15
went straight to vision for.

Part 3 took two more decisions. **D43** put the ingredient catalog in `core/`,
closing D33: the confirm screen was the third caller D33 said should reopen it,
and the duplicated datasource is deleted rather than tripled. **D44** added
`save_imported_recipe`, which is D37's flagged revisit arriving exactly where
it said it would — manual entry can create-then-save-lines because the draft
keeps its id, but an import has a third step (marking the job done) and no such
anchor, so a retry would have made a second recipe from the same import.

Part 3 also added `core/refresh/data_revision.dart`. `ref.invalidate(recipeListProvider)`
worked while recipes was the only feature that wrote a recipe; the confirm
screen is the second, and it may not name that provider. A counter in `core/`
is the channel both writers share.

Sequencing settled during part 1: text and URL import come next, and photo
import is last. Photo needs a Storage bucket, `storage.objects` policies and a
picker package — the slice D35 moved to Phase 2 — so it gets its own decision
rather than being dragged in behind a column that already exists.

**D45, taken in part 4: the SSRF policy.** `import-url` is the only place in
the project that opens a connection to a host somebody else chose, and it does
so from inside Supabase's network holding the service role key. The ruling
lives in `supabase/functions/_shared/url_guard.ts`: http/https only, no
credentials in the URL, no non-standard port, a denylist covering every private
and reserved IPv4 and IPv6 range (including `169.254.169.254`), every
single-label hostname (which is what stops `http://kong:8000` without a list of
service names to maintain), a DNS resolution check on every hostname, redirects
followed by hand with each hop re-vetted, a 10-second timeout, a 2 MB ceiling
counted from the bytes that actually arrive, and a Content-Type check. What it
does NOT stop is DNS rebinding between the check and the connect; Deno's
`fetch` cannot pin a resolved address, and that is written down in the file
rather than left to be discovered.

Part 4 also made **tier 4 best-effort**. It used to be able to sink a whole
import: a recipe read perfectly from JSON-LD would fail because an optional
improvement to its ingredient matching was unavailable. Tiers 1–3 are
deterministic and already done by that point, so a tier 4 failure now logs,
records any tokens it spent, and returns the deterministic matches. The cook
gets a draft with more lines to confirm by hand, which is the confirm screen's
job anyway.

**D46, taken in part 5: the `import-uploads` bucket.** The first Storage bucket
and the first `storage.objects` policies in the project. Paths are
`import-uploads/{household_id}/{uuid}.jpg`, and that prefix is not a filing
convention — it is the access control, read by every policy. Private (D16: a
cookbook page is somebody else's copyrighted prose and there is no public path
to it), 10 MB, images only. Insert, select and delete are scoped by
`is_household_member`; there is deliberately no update, because a photographed
page is immutable and re-photographing writes a new object.

The policies delegate to `storage_path_household(text)`, which returns null
rather than raising on a path that does not start with a uuid. That is the
whole reason it exists: a bare `::uuid` cast inside a policy turns a denied
upload into a 500 instead of a refusal.

D35 still stands for the recipe's own picture. The photograph of a page is an
*input* to an import, not a picture of the dish, and `recipes.image_path`
remains untouched and Phase 2's business.

Part 5 also fixed a bug that would have been silent forever:
`ImportRepository.saveImported` derived `source_type` from whether a source URL
was present, so a photographed page — which has none — would have been recorded
as `manual`, a recipe the app believes somebody typed out by hand. D16's
household-only rule hangs off that column. The mapping moved to
`ImportKind.sourceTypeFor` in the domain, where it is unit-tested.

**Part 6 added share intents on Android.** Share a recipe page from Chrome and
the app opens the link importer with the URL already in it; share prose and it
opens the paste importer instead, keeping any link as attribution. Prefilled
rather than auto-submitted: sharing the wrong page should cost a tap, not a
model call.

A share can arrive before the app can act on it — the router's redirect sends
every location to `/sign-in` or `/create-household` and returns a bare path,
carrying no destination — so a received share is parked in a `keepAlive`
provider and delivered once the same two gates the redirect checks have passed.
Verified on the emulator by sharing while signed out, then signing in: the URL
survived and landed.

**The iOS half is not done**, and two things the next person needs rather than
has to discover. Swift Package Manager is already enabled here and there has
never been a Podfile, so the package (which is SPM-only) fits without changing
the build. And this project uses the *scene* lifecycle
(`UIApplicationSceneManifest` + `SceneDelegate.swift`), so any README telling
you to add an `AppDelegate` override describes a hook that will never fire.
What is missing is a Share Extension target, an app group and the entitlements —
Xcode work `flutter pub get` cannot do.

`receive_sharing_intent` compiles against Android SDK 37, which forced the app
to pin `compileSdk = 37` rather than inheriting Flutter's default of 36. That
only allows newer APIs; `targetSdk` is untouched.

Still open, and named here so it is not rediscovered: the iOS share extension,
and nothing yet prunes an import photo once its job is done or dismissed —
keeping it is deliberate so a failed job can be re-run, but the lifecycle
belongs with Phase 2's Storage work.

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

### Still to build

- Leftover entries actually pointing at their source entry (D51: the column
  and the `'leftover'` vocabulary already exist, unreachable)
- Variety check on the snack slot (client query, 14-day window, warn at 2+)
- Within-slot reordering (D49 names the RPC it would need)
- `shopping_lists`, `shopping_list_items`
- Client-side aggregation: group, scale by servings, sum within unit family,
  split across families, suppress pantry staples
- Drift read cache (cache-then-network) for recipes, meal plans, shopping lists,
  ingredients; delta fetch on `updated_at`, honour `deleted_at`
- Offline banner; writes fail loudly
- Small admin screen: unverified ingredient count, unmatched line count,
  match_method distribution

**Done when:** a week's plan produces a correct list, and that list is readable
in airplane mode.

---

## Phase 3 — Serbian / English

- `flutter_localizations` + ARB files for UI strings
- `recipe_translations` + RLS
- `translate-recipe` Edge Function, marked `is_machine_generated`
- Locale toggle; recipe detail shows translated title/description/steps,
  ingredient lines render from the catalog in the active locale
- Review flow: edit a machine translation, set `reviewed_by`

**Done when:** one recipe entered in Serbian reads correctly in English,
ingredient names included, without a second recipe row existing.

---

## Phase 4 — Everything deferred

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

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

**Status: parts 1 and 2 complete.** The server side works end to end; there is
no client yet. Decisions taken so far: D38–D42.

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
- Edge Functions `import-url` (JSON-LD first, LLM fallback), `import-text`
  (**done**), `import-photo` (vision model, structured output)
- `match-ingredients` Edge Function — the LLM tier, batched per recipe —
  **done**. One call per recipe, choosing from candidates the catalog produced,
  so the model cannot invent an ingredient id. Also a standalone re-matching
  entry point for a job whose unmatched lines the catalog has since learned
- `_shared/usage.ts` quota check + `ai_usage` recording — **done**, along with
  `ai.ts`, `normalize.ts` and `parse_line.ts`, which ARCHITECTURE.md listed for
  1d and this bullet list never did
- Client: create job, poll, **confirm screen** (this is the important one —
  fast accept-all, edit the odd line, writes `manual` aliases)
- `receive_sharing_intent` on both platforms

**Done when:** you can share a recipe URL from a browser into the app, review
what it found, and save it; and photograph a cookbook page and get a usable
draft.

Sequencing settled during part 1: text and URL import come next, and photo
import is last. Photo needs a Storage bucket, `storage.objects` policies and a
picker package — the slice D35 moved to Phase 2 — so it gets its own decision
rather than being dragged in behind a column that already exists.

Still open, and named here so they are not rediscovered: `import-url` fetches
attacker-supplied URLs while the handler holds the service role, and no
document has said anything about SSRF; `search_ingredients` is `security
invoker` (D31), so `match-ingredients` must call it as the caller and not on
the service client, or it will see every household's aliases; and
`features/import/` will be the third consumer of the ingredient catalog, which
`ingredient_catalog_datasource.dart` names as the trigger to reopen D33 rather
than write a third copy.

---

## Phase 2 — Meal plan, shopping list, offline cache

- Recipe photo upload: a Storage bucket, `storage.objects` policies scoped by
  household, a path convention, and a picker package (rule 8 — ask first).
  Moved here from 1c; the `recipes.image_path` column already exists (D35).
- `meal_plans`, `meal_plan_entries` + RLS
- Week grid, 7 days × 4 slots, drag recipes in
- Leftover entries pointing at their source entry
- Variety check on the snack slot (client query, 14-day window, warn at 2+)
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

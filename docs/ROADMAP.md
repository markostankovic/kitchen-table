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
- Supabase Auth (email OTP is simplest; skip social for now)
- `profiles`, `households`, `household_members`, `household_invites` + RLS
- `is_household_member()` helper, applied to one table to prove the pattern
- Edge Functions: `create-invite`, `redeem-invite`
- Screens: sign in, create household, join by code, member list

**Done when:** two accounts on two devices are in one household, and each can
see a row the other created.

### 1b. Ingredient catalog
- `ingredients`, `ingredient_names`, `units`, `unit_names`, indexes
- Seed script: ~200 ingredients + names from CSV (see INGREDIENTS.md)
- `merge_ingredients()` function
- Matching tiers 1–3 (parse, exact, fuzzy) as a Postgres RPC + Dart wrapper.
  No LLM tier yet.

**Done when:** typing "cufte" or "sargarepa" in a search RPC returns the right
ingredient, and `merge_ingredients` correctly repoints rows.

### 1c. Manual recipe entry
- `recipes`, `recipe_ingredients`, `recipe_steps` + RLS
- Recipe list (search by `title_normalized`), detail, create/edit
- Ingredient line editor with autocomplete over `ingredient_names`, "create new"
  as the last option, and fraction-aware quantity input
- Photo upload to Storage

**Done when:** you can type in a recipe you know by heart, in Serbian, and
every ingredient line either matched or deliberately created a new ingredient.

### 1d. Import
- `import_jobs` table
- `_shared/schema.ts` — Zod `ParsedRecipe`; `make types` producing Dart
- Edge Functions `import-url` (JSON-LD first, LLM fallback), `import-text`,
  `import-photo` (vision model, structured output)
- `match-ingredients` Edge Function — the LLM tier, batched per recipe
- `_shared/usage.ts` quota check + `ai_usage` recording
- Client: create job, poll, **confirm screen** (this is the important one —
  fast accept-all, edit the odd line, writes `manual` aliases)
- `receive_sharing_intent` on both platforms

**Done when:** you can share a recipe URL from a browser into the app, review
what it found, and save it; and photograph a cookbook page and get a usable
draft.

---

## Phase 2 — Meal plan, shopping list, offline cache

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

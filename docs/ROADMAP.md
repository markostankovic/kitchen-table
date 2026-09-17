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

# Decisions

Each entry: what was decided, why, and what was rejected. The rejected column
matters most — it stops a future session from "improving" things back to a shape
that was already ruled out.

---

## D1 — Canonical ingredient catalog, accreted not hand-curated

**Decided.** Ingredients are language-neutral concept rows. `ingredient_names`
holds aliases *and* translations. Matching happens in tiers: exact normalized →
trigram fuzzy → LLM → create new as unverified. Every resolution writes an alias
row back, so each unfamiliar string costs one model call ever, across all users.

**Why.** String matching cannot unify *brašno* and *flour*. Cross-language
shopping lists are the product's wedge, so the catalog is the feature, not
overhead. But hand-curating thousands of ingredients is not required: seed
~200 core items (heavily Serbian), let the long tail auto-create.

**Rejected.**
- Pure string matching — cannot bridge languages. Fails the core demo.
- Fully hand-curated catalog up front — weeks of work before anything ships.
- Third-party ingredient database — none cover Serbian items (kajmak, pavlaka,
  ajvar, suvo meso, vegeta, slatka/kisela pavlaka).

## D2 — Split identity from properties

**Decided.** Identity ("these strings mean the same thing") is cheap and applies
to every ingredient. Properties (density, piece weight, category, pantry-staple)
are expensive and only get filled in for the top ~200. Two separate backlogs.

**Why.** Cross-language shopping lists need only identity. Deferring properties
removes the expensive half of the catalog from the critical path.

## D3 — One level of ingredient hierarchy, used sparingly

**Decided.** `ingredients.parent_id`, nullable, one level deep. Shopping lists
do **not** roll up to parent by default.

**Why.** *Glatko* and *oštro brašno* are a real culinary distinction; collapsing
them makes recipes wrong. But deep taxonomies are a rabbit hole. Use only for
flours, sugars, dairy fat levels, paprika, meat cuts.

## D4 — Latin script only for storage and display; accept Cyrillic on input

**Decided.** Everything is stored and displayed in Serbian Latin. Cyrillic input
(OCR of an old cookbook, pasted text) is transliterated at the door and never
stored.

**Why.** User has no need for Cyrillic display. Cyrillic → Latin is
unambiguous; the reverse direction has digraph edge cases (*nadživeti*,
*injekcija*), so always normalize toward Latin.

**Rejected.** Storing both scripts, or a render-time transliterator with a user
preference. Not needed.

## D5 — One normalization function, two implementations, one fixture file

**Decided.** `normalize_text()` (Postgres, IMMUTABLE) and `TextNormalizer`
(Dart) implement identical logic: lowercase → Cyrillic to Latin → strip
diacritics (č/ć→c, š→s, ž→z, đ→dj) → collapse whitespace → trim. Both are
tested against `test/fixtures/normalization.json`.

**Why.** Diacritic-insensitive search ("cufte" finds "ćufte") and ingredient
matching both depend on this. Two implementations that silently disagree is the
worst failure mode, so a shared fixture makes disagreement a test failure.

**Rejected.** Postgres `unaccent` alone — it maps đ→d, not đ→dj, which splits
*đuveč* from a user typing *djuvec*.

## D6 — Serbian inflection handled by fuzzy tier, not by morphology

**Decided.** No stemmer. Trigram similarity threshold (start at 0.4) absorbs
*jaje/jaja/jajeta*, *šargarepa/šargarepe*, *brašno/brašna*. Curated core
ingredients get common inflected forms added as explicit aliases.

**Why.** Serbian morphology is heavy but a real stemmer is a research project.
Trigrams plus explicit aliases for the ~200 things that appear constantly is
the 90% solution. Revisit if match quality is bad in practice.

## D7 — Match provenance on every recipe_ingredient row

**Decided.** `match_method` (exact / alias / fuzzy / llm / manual),
`match_confidence`, `matched_at`.

**Why.** This is the genuinely expensive-to-retrofit thing. Without it you can
never re-run improved matching over old rows, because you can't distinguish a
human-confirmed link from an old machine guess. With it, backfill is a safe,
repeatable background job.

## D8 — Human confirm step on every import

**Decided.** Import never writes a recipe silently. The user reviews parsed
ingredients before save. Confirmed lines write alias rows with
`match_method = 'manual'`.

**Why.** This single screen is the quality mechanism for the whole catalog. It
turns catalog curation into a side effect of normal use. Design it for speed:
accept-all by default, edit the odd line out.

## D9 — Shopping list sums within unit families only (Option A)

**Decided.** Convert to a base unit within a family (mass→g, volume→ml,
count→pieces) and sum. Across families, show separate lines:
`brašno — 480 ml + 300 g`.

**Why.** Cross-family conversion needs a hand-typed density per ingredient
(1 cup flour ≈ 120 g, 1 cup sugar ≈ 200 g — no formula exists). Most Serbian
recipes are already metric, so within-family summing covers the large majority.
Add densities later for the handful of ingredients where it actually annoys.

**Note.** Conversion applies only to the shopping list. Recipe display always
shows the original quantity and unit — rounded conversions ruin baking.

## D10 — Riverpod with code generation

**Decided.** `riverpod` + `riverpod_generator` + `riverpod_lint`, plus
`go_router` (typed routes), `freezed`, `json_serializable`.

**Why.** The real constraint is drift across many AI-assisted sessions.
Codegen means a provider has exactly one legal shape, so a wrong one is a
compile error rather than a review comment. `AsyncValue` matches the app's
shape (nearly every screen is loading/error/data over a Supabase query).
Riverpod also has the most training data, so generated code matches existing
code.

**Rejected.**
- BLoC — comparably rigid, but boilerplate-to-logic ratio is too high for one
  person.
- setState / Provider / GetX — not enough structure to resist drift.

## D11 — Feature-first, three layers, Supabase confined to `data/`

**Decided.** See `docs/ARCHITECTURE.md`. Enforced by lint, not by documentation.

**Why.** This one boundary is what makes D12 (offline) a one-file change per
feature instead of a rewrite.

**Rejected.** Layer-first (`lib/models`, `lib/screens`, `lib/services`) — every
feature ends up smeared across the tree and sessions lose track of where things
belong.

## D12 — No local-first sync. Read cache only, and not until Phase 2

**Decided.** Supabase is the source of truth. Phase 1 is online-only. Phase 2
adds a Drift read cache (cache-then-network) for recipes, meal plans, and the
shopping list. No sync engine, no conflict resolution, no Realtime.

**Why.** Full local-first is justified when multiple people write concurrently
offline. Here there's one planner at a time, no real-time requirement, and
under a megabyte of household data. The one place offline genuinely matters is
reading a shopping list in a supermarket with bad signal, which a read cache
solves.

**Rejected.**
- Full local-first with bidirectional sync — tombstones, clock skew, per-table
  merge policy. Large cost, no matching need.
- Supabase Realtime subscriptions — user explicitly wants manual sync.
- Offline writes / outbox — was on the table when the shopping list had
  check-off state. It doesn't (D13), so there are no field writes at all.

## D13 — Shopping list is generate-and-view

**Decided.** Generating a list produces a snapshot. No per-item checked state,
no sync of shopping progress.

**Why.** User's call. Consequence: zero offline writes, which removes the
outbox, idempotency handling, and last-write-wins reasoning entirely.

## D14 — Every import is a background job

**Decided.** One `import_jobs` table. Client creates a job, polls for status.
URL/JSON-LD (~1 s) and cookbook photo through a vision model (~30 s) use the
same path.

**Why.** One code path instead of two. The user can photograph five cookbook
pages in a row without waiting on each, and a slow model call can't time out an
HTTP request.

## D15 — Cookbook pages go straight to a vision model, not OCR-then-parse

**Decided.** Send the page image and ask for structured output matching the Zod
schema in one call.

**Why.** The hard part of a printed cookbook page is layout, not character
recognition — two columns, sidebar ingredient lists, headnotes mixed with
method, recipes continuing to the next page. A vision model handles layout;
OCR-then-parse throws layout away and then tries to reconstruct it.

**Consequence.** Handwritten card OCR drops down the priority list — it isn't
in the initial corpus. Same code path when it arrives, just worse accuracy.

## D16 — Imported cookbook content is permanently household-scoped

**Decided.** Recipes with `source_type = 'ocr'` or `'url_import'` keep
`visibility = 'household'` with no path to a public shared corpus. `source_url`
or book attribution is stored and displayed.

**Why.** Cookbook prose is copyrighted and OCR is reproduction. Private
household use is defensible; republishing is not.

## D17 — AI usage limits from day one

**Decided.** `ai_usage` rows per call; a per-household monthly cap checked
before every model call in `_shared/usage.ts`.

**Why.** An OCR retry loop can burn real money even at family scale. Cheap now,
awkward to bolt on later.

## D18 — Zod on the server is the only schema definition; Dart models are generated

**Decided.** `zod-to-json-schema` → `quicktype` → freezed Dart models, wired as
`make types`.

**Why.** Hand-mirroring the AI parse contract in Dart drifts silently: rename a
field on the server, the Dart parser quietly reads null, and the bug surfaces
three screens later.

## Open / deferred

- **Client vs Edge Function split** — rule of thumb written in
  `docs/ARCHITECTURE.md`. Settled enough to build on.
- **Thin web layer** — deferred to Phase 4. Leaning Next.js App Router on
  Vercel against the same Supabase project, for public invite links and
  a shareable read-only recipe page. Not decided in detail. Do not build in
  Phase 1–3.
- **Cross-family unit conversion** — deferred, see D9.
- **Handwritten card OCR quality** — unknown until there's a real card to test.

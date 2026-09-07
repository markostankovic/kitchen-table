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

## D19 — `unaccent` is not installed; `normalize_text` is hand-rolled

**Decided.** The `unaccent` extension is not created. `normalize_text()` is
built from `lower` / `replace` / `translate` / `regexp_replace` only, which
keeps it `IMMUTABLE`. See `supabase/migrations/20260904210716_init.sql`.

**Why.** D5 already rejected `unaccent` on correctness grounds (it maps đ→d,
splitting *đuveč* from someone typing *djuvec*). There is a second, harder
reason that is easy to miss and worth writing down: `unaccent()` is `STABLE`,
not `IMMUTABLE`, because its behaviour depends on a mutable dictionary. Any
function that calls it is therefore also non-`IMMUTABLE` — and a
non-`IMMUTABLE` function **cannot back a generated column at all**. That kills
`ingredient_names.normalized_name` and `recipes.title_normalized` outright, not
just their accuracy.

**Rejected.** `unaccent` in any form, including "just for the ASCII fallback".
`docs/DATA_MODEL.md` originally listed it as a helper inside `normalize_text`;
that is not implementable.

## D20 — `riverpod_lint` 3.x replaces `custom_lint`

**Decided.** `custom_lint` is not a dependency. `riverpod_lint` is declared in
a `plugins:` block in `analysis_options.yaml` and its rules run under plain
`dart analyze`.

**Why.** riverpod_lint 3.x migrated off `custom_lint_builder` to Dart's native
`analysis_server_plugin`. Adding `custom_lint` alongside it forces the version
solver back to riverpod_lint 2.x, which transitively pins `freezed_annotation
^2.2.0` and blocks freezed 4. The enforcement intent of
`docs/ARCHITECTURE.md` is unchanged; there is simply one fewer command to run,
because `make lint` no longer needs a separate `dart run custom_lint` step.

## D21 — `fromJson` / `toJson` are exempt from the raw-map ban

**Decided.** `tool/check_layers.dart` does not flag `Map<String, dynamic>` on
lines declaring `fromJson` or `toJson`.

**Why.** CLAUDE.md rule 1 bans `Map<String, dynamic>` outside `data/`, but
CLAUDE.md also mandates `freezed` + `json_serializable` for *all* models, and a
generated `fromJson` necessarily takes a raw map. A literal reading of rule 1
would ban the exact pattern the stack requires. What rule 1 protects against is
untyped maps used as the currency *between* layers — not the one constructor
that turns a map into a typed model.

## D22 — Toolchain floor: Flutter 3.47.2 / Dart 3.13.2

**Decided.** The project requires Dart >= 3.13. `pubspec.yaml` pins
`sdk: ^3.13.2`.

**Why.** freezed 4.x, riverpod_lint 3.1.9 and riverpod_generator 4.0.9 all
require analyzer 13, which requires Dart 3.13. On Dart 3.12 no combination of
these resolves — pub's own diagnostic recommends upgrading the SDK.

**Consequence, and it will bite again.** `riverpod_lint` depends on `riverpod`
at an **exact** version (3.1.9 → `riverpod 3.4.3`). So `flutter_riverpod` and
`riverpod_annotation` cannot be bumped independently: all four move in
lockstep, or version solving fails with an error that misleadingly blames
`freezed_annotation`.

## D23 — RLS checks membership only; repositories filter `deleted_at`

**Decided.** Household-scoped SELECT policies check membership and nothing
else. Filtering out soft-deleted rows is done in `data/`, not in the policy.

**Why.** `docs/ARCHITECTURE.md` requires the Phase 2 delta fetch to *see*
`deleted_at` rows in order to evict them from the Drift cache. A policy of
`using (is_household_member(...) and deleted_at is null)` makes tombstones
invisible to the client, so the cache could never learn that a row was deleted.
The two requirements are mutually exclusive; access control belongs in RLS,
presentation belongs in the repository.

**Rejected.**
- `deleted_at is null` in the policy, with a separate tombstone RPC added in
  Phase 2 — a second read path built later to work around a choice made now.
- Deferring the question to Phase 2 — it would mean rewriting every
  household-scoped SELECT policy in a later migration.

## D24 — "Household-scoped" means "has a `household_id` column"

**Decided.** CLAUDE.md rule 4 (`deleted_at` + `updated_at` + trigger on every
household-scoped table) applies to tables carrying a `household_id` column.
Child rows — `recipe_ingredients`, `recipe_steps`, `shopping_list_items`,
`household_members` — cascade with their parent and carry neither column.

**Why.** The reference schema in `docs/DATA_MODEL.md` already works this way,
and putting `deleted_at` on every child means every child query needs a filter
that adds no safety: a soft-deleted recipe's ingredient rows are already
unreachable.

**Consequence.** Removing someone from a household is a **hard delete** of the
`household_members` row. Revisit if membership revocation ever needs to be
auditable — that is a real argument for making this one join table the
exception.

## D25 — `household_invites` carries neither `deleted_at` nor `updated_at`

**Decided.** A deliberate exception to CLAUDE.md rule 4, for a table that D24
would otherwise catch (it has a `household_id`). `used_at` is the lifecycle
column, and it is the only one.

**Why.** An invite is append-only: created once, stamped dead once. Rule 4's
intent — no row ever disappears — is already met without `deleted_at`. Adding
it would introduce a second lifecycle axis with no defined interaction with the
first ("soft-deleted but unused"?), and would force the partial unique index to
`where used_at is null and deleted_at is null` — which would let a soft-deleted
code be reissued to a *different* household while a row still claims it.
`deleted_at`'s other job, tombstones for the Phase 2 delta fetch (D23, D12),
does not apply: invites are not a cached entity and a code is meaningless
offline. `updated_at` would be written exactly twice in a row's life, and the
second write already records its own timestamp in `used_at`.

**Rejected.** Adding both columns and marking them vestigial. Rule-literal, but
it buys a wrong index predicate and two columns nothing reads.

**Consequence.** There is no way to revoke a live code; you wait out the 7-day
expiry or it gets used. Adding revocation later means a `revoked_at` column
*and* a rebuild of the partial index predicate, in one migration.

## D26 — Invite codes: six digits, single-use, seven days, service-role only

**Decided.** `create-invite` and `redeem-invite` are Edge Functions holding the
service role key, per ARCHITECTURE.md's "anything granting access to household
data is not client logic". The client never writes `household_invites` or
`household_members`; neither table has a write policy at all.

Codes are six digits from `crypto.getRandomValues` with rejection sampling
(a bare `% 1e6` favours low codes; `Math.random()` is seeded per-isolate).
Minting inserts and retries on `23505` rather than pre-checking, which would be
TOCTOU regardless. Any member may invite — `owner` and `adult` are both trusted
adults. Redemption is a conditional `UPDATE ... where used_at is null`, not
SELECT-then-UPDATE, which would let one code grant two memberships.

The `token uuid` column exists but is never read or returned. It is there so
Phase 4's public invite links do not need a migration.

**Redeeming into a second household is rejected** with 409. The schema permits
multiple memberships, but the app does not: `fetchCurrent()` returns
`mine.first`, so a second membership would silently decide which household you
see by creation order. Allowing it needs a household switcher, which is not on
the roadmap.

**Why no rate limiting yet.** A 10^6 space is sweepable in ~28 hours at 10
req/s, inside the 7-day window. What actually contains it is density: 1–5 codes
are live at any moment, so a sweep yields a hit only if it overlaps a live code,
and `verify_jwt` forces the attacker to hold a real session first. Single-use
means a successful guess burns the code, so the real invitee notices. That is
proportionate for a family app and no more. **Upgrade path if this ever leaves
the family:** an `invite_redemption_attempts (user_id, attempted_at)` table with
a ~10/hour cap checked in `redeem-invite`.

**Known limitation.** Claiming the invite and inserting the membership are two
PostgREST calls, not a transaction. The failure path releases the claim, but an
isolate killed between the two burns the code with no membership created;
recovery is to ask for a new one. The fix, if it ever matters, is a direct
postgres connection and a real transaction — not a `SECURITY DEFINER` RPC,
which would split the trust boundary across two places.

## D27 — `ingredients.key`, the stable seed key

**Decided.** `key text unique check (key is null or key ~ '^[a-z][a-z0-9_]*$')`.
Nullable, and null is the common case: only the curated core carries one, and
everything the matcher auto-creates has `key = null`.

**Why.** `docs/INGREDIENTS.md` seeds from a CSV keyed on `brasno_glatko` /
`parent_key`, and without a column to hold it the seed is not idempotent and
parent references cannot be resolved on a re-run. Nullable `UNIQUE` says
exactly the right thing, because Postgres treats NULLs as distinct: "unique
among the rows that have one".

**Rejected.**
- A partial unique index `where key is not null` — conflict inference would
  have to restate the predicate in every `on conflict`, for no benefit at 200
  keyed rows.
- Deriving ids from the key (uuid v5) instead of storing it — hides the key
  where nothing can query or debug it, and makes the CSV silently load-bearing
  for primary keys.
- Coupling `key` to `is_verified` — a curated row can be retired and a tail row
  verified by hand. Two independent facts.

## D28 — `ingredient_names` keeps `updated_at` and `deleted_at`

**Decided.** Unlike `household_invites` in D25, this table takes no exception
to CLAUDE.md rule 4. It gets both lifecycle columns, and its unique index
`(normalized_name, locale, coalesce(household_id, zero-uuid))` stays **total**
rather than partial on `deleted_at is null`.

**Why.** The append-only argument that carried D25 does not survive contact
with this table: `is_display_name` is mutable — a merge demotes it — so rows
here are written more than once. It has a `household_id`, so D24 catches it
literally. Phase 2 caches the catalog for offline autocomplete and a cache
needs tombstones to evict. And `docs/DATA_MODEL.md` words the merge's second
step as "drop the duplicate name row", which is a hard delete and a straight
violation of rule 4; `deleted_at` makes it soft and keeps the rule intact.

The total index is the interesting half. It means a given
`(normalized_name, locale, scope)` resolves to exactly **one** ingredient
globally, forever — so one string can never come to mean two things, and
re-seeding a retired alias resurrects and repoints the existing row rather
than adding a second one for the same string.

**Consequence worth knowing.** Because two ingredients cannot share an alias,
a merge can never produce a duplicate name row, so the "drop the duplicate"
step is unreachable and nothing is ever deleted. See D30.

**Rejected.**
- Append-only with no lifecycle columns, the D25 shape — see above.
- A partial unique index — would allow two live rows for one string as soon as
  one of them was soft-deleted and re-created, which is the failure this index
  exists to prevent.

## D29 — The catalog seed ships as generated migrations, not `seed.sql`

**Decided.** `supabase/seeds/*.csv` → `tool/gen_ingredient_seed.dart` → a new
timestamped migration. `[db.seed]` in `supabase/config.toml` is deliberately
empty. Editing the CSVs emits a **new** migration rather than rewriting an
applied one; every emitted file is a pure upsert, so applying v1 then v2
converges on v2.

**Why.** `[db.seed]` runs on a local `supabase db reset` and nowhere else. The
curated catalog is not fixture data — it is reference data the matcher depends
on in production — so it has to travel through the only thing `supabase db
push` executes. And CLAUDE.md forbids editing an applied migration, so the
generator cannot rewrite its output in place the way
`tool/gen_normalization_sql.dart` does.

Two guards make re-application safe, and both are load-bearing:

- **`is distinct from` on every upsert.** Without it each deploy touches
  `updated_at` on all 200 rows and Phase 2's `updated_at > last_sync_at` delta
  fetch re-downloads the whole catalog to every device for a no-op release. It
  reads like a micro-optimisation and is the difference between a working cache
  and a broken one. Verified: a full replay touches zero rows.
- **`deleted_at is null` on every join**, so a merged-away curated ingredient
  stays merged away instead of being resurrected by the next seed.

`make seed-check` is a separate target from `test-sql` because the two have
different guarantees: `test-sql` regenerates its output in place and therefore
cannot drift, whereas an edited CSV with no migration behind it is the default
failure mode here unless something explicitly checks.

**Deletions are not generated.** A key that leaves the CSV is left alone — the
generator cannot tell "retired" from "typo", and retiring a curated ingredient
means repointing every recipe that used it. That is `merge_ingredients()`, a
reviewed act, never a side effect of editing a spreadsheet.

**Rejected.**
- `supabase/seed.sql` — absent in production, which is the only place it
  matters.
- Both — two sources for one catalog, diverging the first time one is edited.
- Regenerating one migration in place — forbidden, and it would silently change
  a file already applied elsewhere.

## D30 — `merge_ingredients()` is written once, guarded by `to_regclass`

**Decided.** The function handles `recipe_ingredients` (Phase 1c),
`shopping_list_items` and `household_pantry_prefs` (Phase 2) behind
`to_regclass('public.…') is not null` and a dynamic `EXECUTE`. It is correct
today and needs no rewrite when those tables land.

**Why.** `docs/DATA_MODEL.md`'s step 1 repoints `recipe_ingredients`, which
does not exist yet. The alternative is a `create or replace` in 1c's migration
— but the 1c roadmap entry does not mention `merge_ingredients` at all, so
that rewrite is exactly what a future session would forget, and the symptom
would be a silent dangling reference to a retired ingredient.

The explicit table list is kept honest by an FK-coverage assertion in
`supabase/tests/merge_ingredients_test.sql`: it walks `pg_constraint` and fails
the moment a foreign key to `ingredients(id)` appears from a table the function
does not name. Same move as `tool/check_layers.dart` — encode the invariant in
a test rather than trust a future session to remember.

**Nothing is deleted.** Per D28's total unique index, two ingredients cannot
share an alias, so a merge cannot produce a duplicate name row. The repoint is
a plain `UPDATE`. What *can* collide is `one_display_name_per_locale`, since
both ingredients may have their own display name for a locale; those rows are
demoted, not deleted, so the string stays matchable and merely stops being the
one shown back.

**Two traps, both found by the test rather than by reading.**
- Parameters may not be named `source` / `target` as DATA_MODEL writes them:
  `source` is also a column of `ingredient_names`, and a plpgsql parameter that
  shares a name with a column in the same statement is an ambiguity error.
- **`revoke execute … from public` is not sufficient on Supabase.** The
  platform ships `alter default privileges in schema public grant all on
  functions to postgres, anon, authenticated, service_role`, so `anon` and
  `authenticated` hold EXECUTE in their own right and survive a PUBLIC revoke.
  The test called this `SECURITY DEFINER` function successfully as
  `authenticated` with the PUBLIC revoke already in place — a data-destruction
  endpoint that would have shipped looking correct. **Every future
  `SECURITY DEFINER` function not meant for clients needs the three-role revoke
  and a test that proves it.**

**Rejected.**
- Discovering referencing tables from `pg_constraint` at runtime — never goes
  stale, but has to guess a conflict strategy per table and would silently
  sweep in tables nobody considered.
- Writing a partial function now and extending it in 1c — see above.

## D31 — Where each matching tier lives, and where its constants live

**Decided.**
- **Tier 1 (line parse) is Dart**, `features/ingredients/domain/
  ingredient_line_parser.dart`, pure, with the unit lexicon injected. Its
  contract is `test/fixtures/ingredient_lines.json`, and Phase 1d's Deno mirror
  is asserted against the same file — the D5 pattern.
- **Tiers 2 and 3 are ONE Postgres RPC**, `search_ingredients`, not two.
- **All three thresholds live in SQL**: the four-character floor before fuzzy
  fires, the 0.4 similarity threshold, and the 0.75 auto-accept line.
  `search_ingredients` returns `auto_accept` already computed, so no client
  holds a copy of 0.75.

**Why.** `docs/ROADMAP.md` said "tiers 1–3 as a Postgres RPC", written before
the client/edge split settled. Tier 1 touches no data — it is string work over
a lexicon — so a round trip buys nothing and costs the responsiveness 1c's
line editor needs while somebody types; it would also break offline entry in
Phase 2. Tiers 2–3 are set-based candidate ranking over `pg_trgm` and belong
in the database. Splitting the RPC in two would put 0.4 on one side of a
boundary and 0.75 on the other.

**`exact` versus `alias` finally mean something** (D7 lists both):
`exact` is normalized equality against the ingredient's display name, `alias`
against any other spelling or translation. Both carry confidence 1.0. The split
is what lets a later quality dashboard show how much the alias table earns.

**Implementation notes that are decisions, not details.**
- `language sql`, not plpgsql: an output column named `ingredient_id` collides
  with `ingredient_names.ingredient_id` inside a plpgsql body.
- `security invoker`, so RLS does the household scoping and no `household_id`
  parameter is needed — a parameter would be a claim to verify, and the policy
  already knows.
- `similarity(a, b) > 0.4` rather than the `%` operator, which reads a session
  GUC set by the VOLATILE `set_limit()` and would make the function
  session-dependent and non-`STABLE`. The cost is that the GIN trigram index
  does not serve the fuzzy arm; at catalog scale that is irrelevant, and the
  index still serves the prefix arm.
- **A prefix arm exists** because `similarity('sargarepa', 'sarg')` is 0.36 —
  four letters of a nine-letter word would otherwise return nothing and
  autocomplete would not work. Prefix hits report their TRUE similarity rather
  than an invented high confidence, so they stay suggestions instead of
  auto-accepting, and `match_method` stays inside D7's vocabulary.
- Locale is a **tie-break, never a filter**. `flour` must reach *brašno* and
  come back rendered in Serbian; that hop is the product's wedge.

**Rejected.**
- A Postgres line parser — a round trip per line, and integer-fraction parsing
  (`1 1/2`, `2–3`, `½`, `pola`, `1,5`) is far easier to get right and to test
  exhaustively in Dart.
- Three implementations of the parser mirrored from day one — 1d adds the Deno
  one against the same fixture, when there is a caller for it.
- A separate `match_ingredient()` returning a single best row — the Dart
  wrapper takes the first result, and a second function would duplicate the
  ranking.

## D32 — No client write path into the catalog in Phase 1b

**Decided.** `ingredients`, `ingredient_names`, `units`, `unit_names` get a
SELECT policy and nothing else. `ingredient_merges` gets RLS with **no policy
at all**. The seed runs as `postgres` during migration; merges run as the
service role.

**Why.** Nothing in Phase 1b writes the catalog. The matcher's write-back tier
is an Edge Function that does not exist until 1d. Phase 1c's "create a new
ingredient" does need a path, and it gets a deliberate one then — a narrow
`SECURITY DEFINER` RPC on the `create_household` precedent, which can check for
an existing exact match first and so stop two people typing the same new
ingredient from creating two rows. What it must not do is inherit a broad
INSERT policy written a phase early by someone guessing at its shape.

Migration 3 already ruled on this exact question: a write policy nobody uses
"would be dead code that reads like a second, weaker way in".

`docs/DATA_MODEL.md` says household-scoped alias rows "follow the normal
membership policy", which reads like an INSERT policy. It is not one yet:
per `docs/INGREDIENTS.md` every write-back alias is **global** — "that string
now resolves at tier 2 forever, for every household" — so household-scoped rows
are for a later "we call it X in this house" feature. The SELECT policy still
has to handle `household_id`, because the column, its index and the RPC's
visibility rules all exist today.

**Rejected.**
- An INSERT policy for authenticated users — hands every client an unguarded
  write into a global, cross-household table.
- Shipping `create_ingredient()` now — builds 1c's feature a phase early,
  before there is a screen to tell us what it needs.

## Open / deferred

- **Client vs Edge Function split** — rule of thumb written in
  `docs/ARCHITECTURE.md`. Settled enough to build on.
- **Thin web layer** — deferred to Phase 4. Leaning Next.js App Router on
  Vercel against the same Supabase project, for public invite links and
  a shareable read-only recipe page. Not decided in detail. Do not build in
  Phase 1–3.
- **Cross-family unit conversion** — deferred, see D9.
- **Handwritten card OCR quality** — unknown until there's a real card to test.
- **`to_taste` is seeded as a unit but the parser never emits it** — see D31.
  Where recipes actually write `po ukusu`, at the end of a line, it is a note
  and an optional marker, which is what lets `so po ukusu` resolve to *so*.
  The unit code exists for imports that carry an explicit "to taste" field.
  Revisit if 1d's importers turn out to need it.
- **The GIN trigram index is not used by `search_ingredients`** — see D31.
  `similarity()` cannot use it; only the `%` operator can, and `%` was rejected.
  Irrelevant at a few hundred aliases. Revisit if the catalog reaches the tens
  of thousands, at which point the change is `set_limit()` plus dropping
  `STABLE`, not a new index.
- **Phase 2's admin screen needs two grants that do not exist** — a read policy
  on `ingredient_merges` (D32 gives it none) and, if merges are to be triggered
  from the app, `grant execute on merge_ingredients to authenticated` (D30
  revokes it from all three client roles). Both are deliberate omissions, not
  oversights.
- **Auditable membership revocation** — see D24. Only matters once members can
  be removed.
- **Invite revocation** — see D25. Needs a `revoked_at` column and a rebuilt
  partial index, in one migration. Not in Phase 1a.
- **Invite redemption rate limiting** — see D26. Deferred deliberately, with
  the upgrade path named there.

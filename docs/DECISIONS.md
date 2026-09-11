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

## D33 — Cross-feature access stays `domain`-only, and `recipes` pays for it

**Decided.** `tool/check_layers.dart` allows a cross-feature import only into
another feature's `domain/`, and that rule was kept when Phase 1c needed things
that live behind `features/ingredients/` and `features/households/`. `recipes`
therefore carries its own copy of catalog access
(`lib/features/recipes/data/ingredient_catalog_datasource.dart`) and its own
household lookup (`RecipeRepository._currentHouseholdId`).

**What it costs.** The `search_ingredients` RPC contract exists twice. So does
the unit-catalog fetch, the `numeric`-arrives-as-`String` handling, and the
`households` select that `HouseholdRepository.fetchCurrent` already does. Three
duplications, all small, all in `data/`.

**Why.** The alternative was to relax the checker so `recipes/data` could import
`ingredients/data`, and the checker is the only thing making the layering real
— `docs/ARCHITECTURE.md` says "enforced by lint, not by documentation". A rule
that gets an exception the first time it costs anything is not a rule. The
duplication is also honest about what it is: the copy lives in its own file with
a header saying so, rather than smeared through the repository.

**Revisit when** a third feature needs `search_ingredients`. Phase 2's shopping
list is the likely one. That is the signal to reopen this and pull the catalog
into a shared place — not to write a third copy.

## D34 — `create_ingredient` and `link_ingredient_alias` are RPCs, not policies

**Decided.** The narrow write path D32 promised, delivered in Phase 1c.
`create_ingredient(ingredient_name, loc, unit_family) returns uuid` and
`link_ingredient_alias(ingredient, alias_name, loc) returns boolean`, both
`security definer`, both granted to `authenticated` and `service_role` with
`anon` explicitly revoked. Rows they write get `is_verified = false` and
`key = null` — keys belong to the seed (D27).

**Why a function.** `create_ingredient` returns the id of the ingredient that
already answers to the string rather than making a second one, and that guard is
the entire reason this is not an INSERT policy. The guard mirrors
`ingredient_names_unique` exactly: narrower and it raises a constraint violation
instead of returning a row, wider and it refuses creations that would have been
fine.

**Why `boolean`, not `void`.** A string can already be a live global alias for a
different ingredient, and hijacking it would silently change what that word
means for every household. So `link_ingredient_alias` refuses — but it must not
raise, or one household's unusual wording would fail somebody's recipe save. It
returns false, the line still saves, and only the global write-back is declined.

**Known gap, deliberate.** Neither looks across locales. Widening them would
assert that a string naming an ingredient in one language names the same one in
the other, which is false often enough to matter — Serbian *pita* is a pie,
English *pita* is bread. Cross-locale duplicates are what `merge_ingredients` is
for, and `docs/INGREDIENTS.md` is explicit that merging is routine. The SQL test
asserts the gap, so closing it later is a visible change.

**Rejected.** An INSERT policy on `ingredient_names` — see D32, which rejected
the same thing a phase earlier for the same reason.

## D35 — Photo upload moves to Phase 2; `recipes.image_path` ships now

**Decided.** Phase 1c builds no Storage bucket, no policies on
`storage.objects`, and no picker. The `image_path` column ships in the recipes
migration anyway, and is written by nothing and displayed by nothing.

**Why.** Photo upload is a genuinely separate slice — a bucket, RLS on
`storage.objects` scoped by household, a path convention, and a new third-party
package (rule 8) — and none of it is needed for the sentence that defines the
phase: type in a recipe you know by heart and have every line match or
deliberately create an ingredient. Shipping the column now means that slice is a
feature later rather than a migration against existing rows.

`docs/ROADMAP.md` listed photo upload under 1c until this was written down.

## D36 — `replace_recipe_lines`, because PostgREST has no transaction

**Decided.** Saving a recipe's lines and steps goes through one
`security invoker` plpgsql function that deletes both child lists and reinserts
them, then touches the parent's `updated_at`.

**Why.** It is four statements, and PostgREST offers the client no way to run
them in one transaction. A failed save would otherwise leave a recipe with its
old lines deleted and its new ones missing, which is worse than a save that did
not happen. `security invoker` so RLS still decides who may write — the function
is atomicity, not authority.

`position` is derived from array order inside the function rather than read from
the JSON. The client already sends the lines in the order it displays them, so
deriving the column here makes a duplicated or missing position unexpressible.

The parameter is `recipe`, not `recipe_id`: `recipe_id` is a column of both
child tables, and a plpgsql parameter sharing a name with a column in the same
statement is an ambiguity error (D30, learned the hard way).

## D37 — A new recipe is `create()` then `saveLines()`, and the draft keeps the id

**Decided.** The first save of a recipe is two calls: a plain insert into
`recipes`, then `replace_recipe_lines`. There is no `create_recipe` RPC.
`RecipeRepository.create` returns the whole row rather than just the id, and
`RecipeEditor.save` writes it into the draft **between** the two calls.

**Why not one RPC.** `recipes` has an INSERT policy and the insert alone has
nothing to make atomic, so D36's argument does not extend to it. An RPC would be
a second recipe write path to keep in sync with the first, plus a migration and
a SQL test, bought against a failure window of one round trip.

**Why the assignment between them matters.** It is what makes the pair safe. If
`saveLines` fails, the draft is already pointing at the recipe that was created,
so pressing Save again updates that one instead of creating a second. The worst
case is a titled recipe with no lines, sitting in the list, editable — a retry,
not a duplicate. Returning the whole row is also what lets the second save issue
an update at all: `household_id` and `created_by` are not the editor's to
invent.

**Revisit if** import (1d) needs to write a recipe and its lines as one unit
from the server side, where the argument is different.

## D38 — `ai_usage` is an append-only ledger, with no lifecycle columns

**Decided.** `ai_usage` carries `household_id` and therefore falls under rule 4
as written, but gets neither `updated_at` nor `deleted_at`. A row is inserted
once by the service role immediately after a model call and never touched
again.

**Why.** The same shape of exception as D25, for a different reason. A ledger
whose rows can be updated is not a ledger, and a tombstoned cost row is a hole
in a cost audit that still bills. D17 put usage limits in from day one so that
an OCR retry loop cannot quietly burn money; a ledger that can be edited or
hidden would give that mechanism nothing solid to stand on.

**Consequence, stated so it is a choice rather than a surprise.** There is no
way to correct a mis-recorded row and no way to hide one. Both are correct for
money. If usage ever needs resetting per billing period, that is a column
recording the period, not a delete.

`household_ai_limits` does get `updated_at` — caps are meant to be tuned — and
no `deleted_at`, because its primary key *is* the household id and it cascades.

## D39 — Clients never write `import_jobs`

**Decided.** RLS on `import_jobs`, `ai_usage` and `household_ai_limits` grants
`SELECT` and nothing else. No INSERT policy, no UPDATE policy, no DELETE
policy. The job row is created by the import Edge Function on the service role,
and the client's entire write surface is two `security definer` functions,
`finish_import_job` and `dismiss_import_job`.

**Why.** RLS cannot restrict which *columns* an update touches. A policy
permissive enough to let the confirm screen set `recipe_id` is permissive enough
to let any client set `status = 'needs_review'` with a hand-written `result` —
which would turn the import queue into an arbitrary-JSON store that the confirm
screen renders and a human is then asked to trust.

Creating the row server-side also means the household is resolved from the
caller's membership rather than named by the client, which is the same argument
`create-invite` makes.

**Consequence.** Those two functions are `security definer` and therefore
bypass RLS, so each writes its membership check out by hand — the rule
`_shared/auth.ts` states for the service-role client, applied in SQL. Note this
is the opposite choice from D36's `replace_recipe_lines`, which could be
`security invoker` precisely because `recipe_ingredients` *has* write policies.

## D40 — Every household gets its AI limits row from a trigger

**Decided.** A trigger on `households` inserts a `household_ai_limits` row, and
the migration backfills existing households idempotently.

**Why.** So the column defaults are the only definition of what the caps start
at. The alternative was `coalesce(limits.cap, 500)` in `_shared/usage.ts`,
which is a second copy of a number that must agree with the first — and the
kind that disagrees silently, six months later, in the direction of spending
more.

A trigger rather than an edit to `create_household()`: that function is in an
applied migration and applied migrations are not edited, and a trigger also
catches the paths `create_household()` is not on.

## D41 — Two Zod schemas: `ModelRecipe` is asked for, `ParsedRecipe` is stored

**Decided.** `_shared/schema.ts` defines both. `ModelRecipe` is what a model is
asked to return — prose and raw ingredient lines. `ParsedRecipe` is
`ModelRecipe` enriched by `parse_line.ts` and `match-ingredients`, and is what
`import_jobs.result` holds and what `make types` generates Dart from.

**Why.** A model asked for quantities and `units.code` values will happily
invent both. It does not need to: `parse_line.ts` produces integer fractions
deterministically and is held to `test/fixtures/ingredient_lines.json`, and
`search_ingredients` produces matches and is held to the SQL tests. Asking a
model to redo exact work is how the exact work gets quietly replaced by a guess.

**Consequence.** `ParsedIngredientLine.matchMethod` has no `manual` value and
must not gain one — a machine pass cannot produce a human decision (D7), and
only the confirm screen promotes a line to `manual`.

Also recorded here because it has no better home: `import_jobs.kind` has three
values and `recipes.source_type` has four. `url` maps to `url_import`, `photo`
to `ocr`, and `text` to `url_import` when the paste carried a URL and `manual`
when it did not. That mapping lives in `ImportKind.sourceTypeFor`. It was wrong
for photos until Phase 1d part 5 — derived from whether a source URL was
present, which a photograph never has — and a photographed cookbook page was
being recorded as a recipe somebody typed out by hand. D16's household-only rule
hangs off that column.

## D42 — No machine tier writes to the catalog

**Decided.** Tiers 3, 4 and 5 write no `ingredient_names` rows and create no
ingredients during an import. The write-back happens on the confirm screen,
when a human accepts a line, through `link_ingredient_alias` (D34).

**Why.** `docs/INGREDIENTS.md` says every resolution writes back, and it is
right about why: ingredient strings are Zipf-distributed, so a few hundred
aliases cover most of what anyone will ever write, and that is what stops the
LLM tier being paid for twice. The disagreement is only about *when*.

Writing back during import makes a machine guess global and permanent (D28: one
string, one ingredient, forever) before any human has seen it — and D8 exists
precisely because a human sees every import. Tier 5 would be worse: `za
posluživanje` is a real line in the fixture, and creating an ingredient for it
at import time would enter "for serving" into the catalog as food.

Since the confirm screen accepts by default, the cost curve still drops on the
first import of a new string. It drops one tap later.

**Consequence.** The confirm screen is now the *only* thing that grows the
catalog, which raises the stakes on D8 rather than lowering them. It also
removed a smaller problem rather than solving it: `link_ingredient_alias`
hardcodes `source = 'user'` and needs a non-null `auth.uid()`, so a machine
tier calling it would have meant either lying about provenance — the thing D7
exists to prevent — or a migration to widen it.

**And tier 4 is best effort.** It could originally sink a whole import: a
recipe read perfectly from JSON-LD would fail because an optional improvement to
its ingredient matching was unavailable. Tiers 1–3 are deterministic and already
done by then, so a tier 4 failure now logs, records any tokens it spent, and
returns the deterministic matches. The cook gets a draft with more lines to
confirm by hand, which is the confirm screen's job anyway. Same shape as rule 3:
structure is an enhancement on `raw_text`, and the LLM tier is an enhancement on
the tiers below it.

## D43 — One ingredient catalog, in `core/` — closing D33

**Decided.** `features/ingredients/data/ingredient_repository.dart` is the only
catalog access in the codebase. Its providers and the ingredient line editor
live in `lib/core/ingredients/`. `features/recipes/data/ingredient_catalog_datasource.dart`
is deleted.

**Why.** D33 chose duplication over relaxing the layer rule when Phase 1c needed
`search_ingredients` from the recipes feature, and said what should happen next:
"If a third caller appears, that is the signal to reopen D33 rather than to
write a third copy." Phase 1d's confirm screen is that third caller, arriving
before the predicted one — it needs the line editor, and `features/import/` may
not import `features/recipes/presentation/`.

`core/` is outside the feature rule entirely: `tool/check_layers.dart` derives
layer and feature from `lib/features/<x>/<layer>/` and nothing else. That is not
a loophole being exploited — `core/supabase/` already holds
`currentUserIdProvider` for exactly this reason.

**Why the datasource itself did not move.** `supabase_flutter` is importable
only in `data/` or `core/supabase/` (rule 1). The providers construct the
repository from `supabaseClientProvider` without ever naming a Supabase type,
which is the same move `recipe_providers.dart` already made.

**Compromise worth naming.** `IngredientLineField` still operates on
`RecipeDraftLine`, so `core/` now depends on `features/recipes/domain/`. Legal,
and better than inventing a core-owned line type — that would be a second model
of the same thing to satisfy a naming instinct.

**Consequence.** A second cross-feature channel appeared for the same reason:
`ref.invalidate(recipeListProvider)` worked while recipes was the only feature
that wrote a recipe, and the confirm screen is the second. Both writers now bump
a counter in `core/refresh/data_revision.dart`.

## D44 — `save_imported_recipe`, the atomicity D37 said to revisit

**Decided.** One `security definer` function creates the recipe, writes its
lines and steps, and marks the job done — in one transaction. It composes
`replace_recipe_lines` (D36) and `finish_import_job` rather than reimplementing
either.

**Why, and why it does not contradict D37.** D37 ruled that a new recipe is
`create()` then `saveLines()` from the client, and ended: "Revisit if import
(1d) needs to write a recipe and its lines as one unit from the server side,
where the argument is different." It does, and it is. Manual entry is safe as
two steps because the draft keeps the id it was given, so a failed second step
is fixed by pressing Save again. An import has a **third** step — marking the
job done — and no such anchor: a failure between them leaves an orphan recipe
*and* a job still in `needs_review`, so pressing Save again creates a second
recipe from the same import.

**Consequence.** `household_id` comes from the job, never from the payload, and
`status` is forced to `draft` rather than read — anything AI-produced is draft
until a human marks it tested. The status guard runs *before* the insert, so a
job in the wrong state is refused rather than rolled back.

## D45 — The SSRF policy for `import-url`

**Decided.** `supabase/functions/_shared/url_guard.ts`. http/https only, no
credentials in the URL, no non-standard port, a denylist covering every private
and reserved IPv4 and IPv6 range, every single-label hostname, a DNS resolution
check on every hostname, redirects followed by hand with each hop re-vetted, a
10-second timeout, a 2 MB ceiling counted from bytes that actually arrive, and
a Content-Type check. The URL is vetted before a job row exists, so a refusal is
a synchronous 400.

**Why.** `import-url` is the only place in the project that opens a connection
to a host somebody else chose, and it does so from inside Supabase's network
holding the service role key. Unguarded it reaches `http://kong:8000`,
`http://db:5432` and, on a cloud host, `http://169.254.169.254/` — which is how
a recipe importer becomes a credential exfiltration tool.

**Why single-label hostnames as a class.** Inside Docker and inside Supabase's
network, services are reachable by bare name. Enumerating them would be a list
to maintain; refusing every name with no dot in it is the same protection with
nothing to keep up to date, and no real recipe site is reachable that way.

**Why the helper returns null rather than raising.** An exception inside a
policy or a guard is not a refusal. `storage_path_household` (D46) makes the
same choice for the same reason.

**What it does not stop.** DNS rebinding between the check and the connect.
Deno's `fetch` cannot pin a resolved address. Written in the file rather than
left to be discovered.

## D46 — The `import-uploads` bucket, where the path is the access control

**Decided.** One private bucket, 10 MB, images only. Paths are
`import-uploads/{household_id}/{uuid}.jpg`, and every `storage.objects` policy
reads that first segment through `storage_path_household(text)`. Insert, select
and delete are scoped by `is_household_member`. There is no update policy.

**Why private.** A photographed cookbook page is somebody else's copyrighted
prose, and D16 says there is no public path to it.

**Why no update.** An uploaded page is immutable; re-photographing writes a new
object. The same instinct as D38.

**Why a helper function.** `(storage.foldername(name))[1]::uuid` raises on
anything that is not a uuid, and an exception inside a policy is a 500 rather
than a denial — a client could turn a denied upload into a server error by
naming `hello/world.jpg`. The helper swallows the cast failure and returns null,
which `is_household_member` already treats as false.

**Consequence, and a limit on its test.** Supabase refuses direct INSERT and
DELETE on `storage.objects` even for `postgres`, so a SQL test cannot set up the
fixture. `supabase/tests/rls_storage_test.sql` asserts what SQL can see — the
bucket's configuration, the policy set, and every branch of the helper — and
says in its header that the policies themselves are exercised against the real
Storage API instead.

D35 still stands for the recipe's own picture: the photograph of a page is an
*input* to an import, not a picture of the dish, and `recipes.image_path`
remains Phase 2's business.

## D47 — Model options are per-model, in a table

**Decided.** `_shared/ai.ts` carries a `CAPABILITIES` table beside `MODELS` and
`PRICING`, and `callStructured` adds `thinking` and `fallbacks` only for models
that accept them. Opus 5 gets adaptive thinking and a server-side refusal
fallback; Haiku 4.5 gets neither.

**Why.** `callStructured` used to send `thinking: {type: "adaptive"}` for every
model. Haiku 4.5 predates adaptive thinking and answers it with a 400 —
`adaptive thinking is not supported on this model` — so **tier 4 never worked,
from the day it was written in part 2 until credits made it observable in
part 6.**

What kept it hidden is worth recording, because the mechanism was working as
designed. D42 made tier 4 best-effort: tiers 1-3 are deterministic and already
done, so a tier 4 failure logs, records any tokens spent, and returns the
deterministic matches rather than sinking the import. That is still the right
call — losing a read recipe because an optional improvement was unavailable
would be the wrong trade. But best-effort turns a hard failure into a silent
degradation, and a permanent bug then looks exactly like an occasional one. The
only symptom was that no `match-ingredients` row ever appeared in `ai_usage`,
and nothing was watching for its absence.

**Consequence.** `ai_test.ts` now asserts that every model in `MODELS` has a
`CAPABILITIES` entry, and names the Haiku/adaptive pairing explicitly — the
same shape as the existing "every model has a price" guard. Adding a model is a
row in two tables and a failing test if you forget either.

**The general lesson, since it will recur.** A best-effort path needs something
that notices it is always failing. The absence of a ledger row is a fact the
database already has; Phase 2's admin screen is the natural place to surface it.

## D48 — The recipe's own photo: a second private bucket, signed URLs, upload only on save

**Decided.** Phase 2 part 1 gives `recipes.image_path` (shipped empty since
migration 8, D35) a bucket: `recipe-images`, private, 5 MB, images only, at
`recipe-images/{household_id}/{name}.jpg` — the same shape as `import-uploads`
(D46), reading the household through the same `storage_path_household(text)`
rather than a second copy of it. Four things were decided together.

**A second bucket, not a reuse of `import-uploads`.** An import upload is an
*input* to a job that finishes; a dish photo is part of a recipe that
persists. D46 already said every policy should name its bucket precisely so a
later bucket could not inherit them by accident — this is that later bucket.

**Private, served through signed URLs, not public.** The bucket also holds
photos attached to `ocr` and `url_import` recipes, which D16 makes
permanently household-scoped. A public bucket would put those behind an
unauthenticated URL, exactly the path D16 says does not exist. There is no
public reader in the app regardless — `recipes.visibility` has one legal
value — so this costs one round trip (`createSignedUrlsResult`, batched per
list page) for a guarantee D16 already promised. Revisit only alongside
Phase 4's read-only web page.

**The upload happens inside `RecipeEditor.save()`, never at pick time.** The
edit screen holds a picked photo's bytes in memory (`RecipeImageUpload`) and
previews from them directly; nothing reaches Storage until `save()` is
called, and it uploads before touching the recipe row so the slow step
happens under the cook's finger. An abandoned editor therefore leaves no
orphan object — the same failure mode D46 already lists as open for import
photos is not repeated here by construction, rather than solved for both.

**No UPDATE policy; the old object is deleted after the row is overwritten.**
Same instinct as `import-uploads` and `ai_usage` (D38): replacing a photo
writes a new object under a new name, and the old one is removed once nothing
points at it. Deletion is best-effort — logged and swallowed, never surfaced —
because the recipe itself already saved, and a leftover blob is a smaller
problem than telling the cook their save failed when it didn't.

**Consequence.** `RecipeRepository.uploadImage`/`deleteImage` are the only new
Supabase calls; `_withImageUrls` mirrors `_withDisplayNames`'s one-round-trip
shape and uses `createSignedUrlsResult` rather than the deprecated
`createSignedUrls` specifically so one missing object degrades to no picture
(rule 3) instead of failing the whole list.

## D49 — `meal_plan_entries` is a child table in the D24 sense, and its invariants live in triggers

**Decided.** No `created_at`, no `updated_at`, no `deleted_at`; hard delete
allowed; four RLS policies scoped through `meal_plans`, the same shape as
`recipe_ingredients` / `recipe_steps`. An `after insert or update or delete`
trigger (`meal_plan_entries_touch_plan`) touches `meal_plans.updated_at`. A
`before insert or update` trigger (`meal_plan_entries_before_write`) derives
`position` at the tail of its `(meal_plan_id, entry_date, slot)` group,
refuses an `entry_date` outside its plan's week, and refuses a
`leftover_of_entry_id` the caller cannot see.

**Why.** `docs/DATA_MODEL.md`'s original sketch gave this table `created_at`
and `updated_at` but no `deleted_at` — the only child table in that document
shaped that way, and not rule-4-compliant on its own terms either. It was an
inconsistency in the sketch, not a considered exception, and D24 governs: no
`household_id`, it cascades with its plan, and a removed entry is genuinely
gone. What the Phase 2 delta fetch actually needs is a *week* whose
`updated_at` moves when anything inside it changes — `replace_recipe_lines`
already does this by hand for a recipe's lines; here it is a trigger because,
unlike a recipe save, there is no single funnel: add, move and remove are
three separate statements, and a later part adds a fourth (leftovers).
`position` is assigned server-side for the same reason D36 gave for
`recipe_ingredients.position` — a client-computed `max()+1` is a
read-then-write race and a second definition of ordering; deriving it here
means a duplicate or missing position is not expressible. `position` has no
column default deliberately: a default is applied *before* a `BEFORE`
trigger runs, so a default of `0` would make "the client didn't say" and "the
client said 0" indistinguishable, and the trigger needs to tell them apart.

**Rejected.** Transcribing `docs/DATA_MODEL.md` literally — it would have
bought two columns nothing reads on a table that is neither child-shaped nor
rule-4-shaped. A `move_meal_plan_entry` RPC per mutation, when one trigger
covers add, move, and (later) leftover creation uniformly. A unique index on
`(meal_plan_id, entry_date, slot, position)` — it would turn two people
adding to the same empty slot at once into a spurious "already exists".

**Consequence.** Within-slot reordering is not expressible by this trigger —
every insert and every move lands at the tail. An explicit reorder RPC is a
later part's problem, when the UI actually offers it.

## D50 — The week row is written on the first write, never on a view

**Decided.** `ensure_meal_plan(household uuid, week date) returns uuid`,
`security invoker`, guarded by `is_household_member(household)` raising
`42501` before anything else runs. `insert into meal_plans ... on conflict
(household_id, week_start) do update set deleted_at = null returning id`. The
unique index stays total (not partial on `deleted_at is null`). Called only
from `MealPlanRepository`'s write methods, never from `fetchWeek`.

**Why.** The grid must open on any week without writing a row for it —
browsing a year of weeks nobody planned must not insert 52 empty rows.
`do update` rather than `do nothing`: `on conflict do nothing returning id`
returns **no row** on conflict, which is the common case here (most writes
land in a week that already has a plan), so the RPC would return `NULL`
exactly when it matters most. `do update` guarantees a row every time, and as
a consequence also resurrects a soft-deleted week into its same row rather
than being blocked by it — a bonus, not the main reason. The membership guard
comes first so that a non-member is refused with `42501`, not with `23505`
from falling through to the unique constraint on a row they cannot see — the
wrong error code would read as "that already exists" instead of "you are not
allowed here". The `household` parameter is passed in rather than resolved
inside the function because no `current_household()` exists anywhere in this
schema; the only definition of "your household" is the client's own query
(`HouseholdRepository.fetchCurrent`, D52), and this function is not the place
to invent a second one.

**Rejected.** Creating the plan row on first *view* — a write hiding behind a
read, and a year of browsing would still write 52 rows. A partial unique
index `where deleted_at is null` — only usable as an `on conflict` arbiter if
every statement repeats the predicate, and it would let a live and a dead row
coexist for the same week, handing the Phase 2 delta fetch an ambiguous key
for the entity D23 exists to let it evict.

## D51 — `leftover_of_entry_id` and the `leftover` vocabulary ship now, unreachable

**Decided.** The column, its self-FK (`on delete cascade`), its index, and
`'leftover'` in the `entry_kind` check all ship in migration 14. No client
writes them until a later part builds the leftover feature. The `recipe` and
`note` branches of the check constraint are made mutually exclusive; the
`leftover` branch requires only its own pointer, deliberately looser.

**Why.** The same argument D35 made for `recipes.image_path`: shipping the
column now means the leftover feature is a feature, not a migration against
existing rows, when it arrives. The `leftover` branch stays permissive
because a later part may want `recipe_id` denormalised onto a leftover row so
the snack variety check can count it without a join, and this migration will
be unwritable by then (CLAUDE.md: never edit an applied migration). Being
loose on the one branch with no client yet is honest; being loose on the two
branches that already have one would just be sloppy.

**Rejected.** Deferring the column entirely to the part that needs it — the
migration-against-existing-rows problem D35 already named. Deciding the
leftover-to-source relationship rule now, with no client yet to check it
against.

## D52 — "The caller's current household id" becomes one derived provider in `core/`, closing D33's last copy

**Decided.** `lib/core/household/current_household.dart` exposes
`currentHouseholdIdProvider`, a `Future<String?>` derived from
`currentHouseholdProvider`. `RecipeRepository._currentHouseholdId` is
deleted; `RecipeRepository.create` and `.uploadImage` now take `householdId`
as a parameter, resolved once in `RecipeEditor.save()`. `MealPlanRepository`
takes it the same way.

**Why.** `_currentHouseholdId`'s own comment named this exact moment: "if a
third feature needs it, that is the signal to revisit D33 rather than to
write a third copy." `meal_plan` is that third feature. D43 already
established the shape for this situation — the thing moves to `core/`, which
`tool/check_layers.dart` exempts from the cross-feature rule entirely, and
the duplicate is deleted rather than relocated. Deriving from
`currentHouseholdProvider` rather than adding a second `households` query:
that provider is already `keepAlive` and is already the one definition of
"which household" (`HouseholdRepository.fetchCurrent` — oldest undeleted
household the caller belongs to); a repository-level helper would have been
a second definition of that tiebreak, and would have cost a round trip on
every write this id feeds. Riverpod's own caching makes deriving it free.

**Rejected.** Moving the *query* itself into `core/supabase/` rather than
deriving a provider — that would centralise the duplicate instead of
removing it, keep `HouseholdRepository.fetchCurrent` as a second definition
of the same tiebreak, and still pay a round trip per write. Exposing
`currentHouseholdProvider` itself from `core/` — the `Household` model (its
name, who created it) is the households feature's business; only the id is
cross-feature currency, the same split `core/ingredients/` keeps between the
catalog's providers and `Ingredient` itself.

## D53 — The meal plan reads recipes through `core/recipes/`, and an entry carries a title, not a `Recipe`

**Decided.** The slot picker watches `plannableRecipesProvider` in
`lib/core/recipes/recipe_picker_providers.dart`, built over a second
`RecipeRepository` instance rather than the recipes feature's own
`application/` provider. `MealPlanEntry` carries `recipeTitle` /
`recipeServings`, resolved from a PostgREST embed at read time and never
persisted.

**Why.** The alternative was a recipe search method on `MealPlanRepository`,
which would have duplicated `title_normalized ilike`, the `deleted_at`
filter, and the `TextNormalizer` hop — D33's mistake, repeated one phase
after D43 undid it for the ingredient catalog. `core/` is exempt from the
cross-feature rule for the same reason `core/ingredients/` is (D43): a second
feature needed a first feature's read path, and the sanctioned move is
`core/`, not a duplicate. A `Recipe` built from a two-column embed would need
placeholder values for `householdId`, `originalLocale`, `sourceType`,
`status` and `createdBy` — a lie the type system would carry forward exactly
the way `Recipe.imageUrl` and `RecipeIngredient.displayName` already show is
unnecessary: a resolved display field is the established pattern for "read
this from an embed, never write it back."

**Consequence.** The picker gets recipe thumbnails for free from
`_withImageUrls`; the week grid's own tiles deliberately do not carry one —
a second copy of the signed-URL logic is what moving `_withImageUrls` to
`core/` would be for, and no second caller needs it yet.

**Rejected.** Moving `recipeListProvider` itself to `core/` wholesale — a
bigger blast radius than one consumer justifies; if a third caller for the
*list* provider specifically ever appears, that is the signal to revisit,
the same way D33 named for the datasource.

## D54 — One visible week, a non-family provider, and every write lands immediately

**Decided.** `visibleWeekProvider` (`VisibleWeek`) holds the one week
currently on screen — not a family keyed on the week. `MealPlanEditor`
(`AsyncNotifier`, not a family either) watches it and `mealPlanRevisionProvider`,
resolves the household id, and fetches. There is no Save: `addRecipe`,
`addNote`, `moveEntry` and `removeEntry` all write immediately and then bump
`mealPlanRevisionProvider`, which is the only refresh — `build()` re-runs
because of the bump, so an extra `invalidateSelf()` would refetch twice.

**Why.** There is exactly one visible week at a time, the same way there is
exactly one signed-in user — a family would have modelled something that
does not exist, and a family keyed on `PlanWeek.of(DateTime.now())` would
have been clock-dependent to override in a test. `RecipeEditor` is
draft-then-save because a recipe is one document being composed and an
abandoned editor must write nothing (D37); a meal plan is not a document —
each entry is independent, and putting a recipe in Thursday lunch is
complete the moment it happens. D12 already rules out an offline draft
buying anything here. A failed write therefore has to be loud: the screen
catches `AppFailure` and shows it in a `SnackBar`, and because no action
mutates `state` directly, a failure never leaves a phantom entry behind —
the next successful bump is what the grid actually shows.

**Rejected.** A family provider keyed on the visible week (see above). An
offline-friendly draft for the week grid, mirroring `RecipeEditor` — nothing
here is composed as one unit the way a recipe's title-and-lines are, so the
draft would only add a way to lose changes to a back gesture.

## D55 — A leftover entry carries its source's `recipe_id`, derived by trigger and never sent by the client

**Decided.** `meal_plan_entries_leftover_source` (migration 15), a second
`before insert or update` trigger alongside migration 14's
`meal_plan_entries_before_write`, sets `new.recipe_id` from the source entry's
own `recipe_id` whenever `entry_kind = 'leftover'`, overwriting whatever the
client sent. It also refuses a source that is not itself an
`entry_kind = 'recipe'` row — no leftover-of-leftover chains — and refuses a
leftover pointing at itself.

**Why.** This is what D51's deliberately loose `'leftover'` check-constraint
branch was for: it required only `leftover_of_entry_id`, precisely so a later
migration could add `recipe_id` to the row without rewriting that constraint.
Deriving it, rather than trusting the client, is what makes the
denormalisation safe to build on — a leftover's `recipe_id` cannot disagree
with its source's, so the drift the loose branch permits is simply not
expressible, the same move `ensure_meal_plan` already makes for the plan id
and `meal_plan_entries_before_write` already makes for `position` (D49, D50).
The payoff is immediate: the snack variety check (D58) and `countRecipeInSlot`
can match `recipe_id` alone and count a leftover as an occurrence of its
source recipe, with no join back through `leftover_of_entry_id`. The shopping
list (Phase 2's next part) gets the same thing for free when it needs to skip
leftovers so nothing is bought twice.

A second, additively-named trigger rather than folding a fourth invariant
into `meal_plan_entries_before_write`: that function's own comment in
migration 14 describes exactly three invariants, and CLAUDE.md forbids
editing an applied migration to keep that description honest. Trigger
execution order is alphabetical by name, so `..._before_write` still runs
first, but the two turned out to be independent in practice — position
assignment and the week-boundary guard never read `recipe_id` or the leftover
source's row.

**Rejected.** Trusting a client-sent `recipe_id` on a leftover row (D42's
argument against a machine tier writing catalog data unsupervised applies here
in miniature: a value nothing derives or checks is a value that can quietly
drift). Chains of leftovers — a leftover of a leftover has a head nobody can
find, and the check would need to walk an arbitrary-depth chain to resolve one
`recipe_id`.

## D56 — A leftover's destination is a date, not a slot in the visible week

**Decided.** `MealPlanEditor.addLeftover` ignores the `week` its own `_write`
funnel would otherwise supply (the week on screen) and derives the
destination week from the leftover's `entryDate` instead:
`MealPlanRepository.addLeftoverEntry` calls `_ensurePlan` with
`PlanWeek.of(entryDate)`. The leftover dialog offers 14 consecutive dates
starting at the source entry's own date, crossing a week boundary freely.

**Why.** Sunday dinner's leftovers landing on Monday lunch is the single most
common leftover there is, and Monday sits in a different `meal_plans` row
than Sunday. Restricting the leftover dialog to the visible week's 7 days
(the same list `_showMoveDialog` already offers) cannot express that at all.
`ensure_meal_plan` already creates a week's row lazily on its first write
(D50); a leftover's write is just another caller of the same path, into
whichever week its date falls in.

**Consequence.** A leftover placed into next week is invisible on the grid
until the cook pages forward — the grid shows one week at a time by design
(D54), and this is not a bug, just a fact worth having named once rather than
rediscovered as a "missing" entry.

**Rejected.** Restricting the leftover dialog to the visible week's days —
cannot express the Sunday → Monday case, which is the main one.

## D57 — Within-slot order is an RPC that renumbers the whole group, not a two-row swap

**Decided.** `reorder_meal_plan_entry(entry uuid, new_position int)`
(migration 15), the RPC D49 named and left unbuilt. It looks up the entry's
`(meal_plan_id, entry_date, slot)`, clamps `new_position` into `[0, group_size
- 1]`, and renumbers every sibling in that group to `0..n-1` in one
statement — splicing the moving row in at the target index among the others,
ordered by their current `position` — rather than swapping the two rows at
the old and new positions.

**Why.** A two-row swap would preserve whatever gap or duplicate already
exists elsewhere in that group's `position` values. D49 rejected a unique
index on `position` specifically so two concurrent inserts into an empty slot
do not collide as a spurious "already exists" — which means gaps (and,
briefly, ties) are legal, and this RPC has to tolerate them on the way in
regardless of what produced them. Renumbering the whole group is also what
lets it leave the group gap-free on the way out, which a swap does not
guarantee. Clamping rather than raising on an out-of-range `new_position`: a
"move down" tapped on the last chip is a no-op, not a mistake worth
surfacing.

It does not fight `meal_plan_entries_before_write`: that trigger reassigns
`position` only on `INSERT`, or on `UPDATE` when `entry_date` or `slot`
actually changed (migration 14). A reorder changes neither, so its
tail-assignment branch never fires — the update this RPC issues is exactly
the "note text or servings changed" case that trigger was already written to
leave `position` alone for. This is the one fact that makes the RPC work at
all, and it is not obvious from reading either function in isolation, which
is why migration 15 writes it down explicitly rather than leaving it to be
rediscovered by whoever next touches either trigger.

**Rejected.** A two-row swap (preserves existing gaps/duplicates instead of
normalising them, and is not obviously simpler to reason about than a full
renumber). A unique index on `(meal_plan_id, entry_date, slot, position)` —
D49 already rejected this for a different reason (it would turn two
concurrent inserts into a spurious conflict), and it would make this RPC's
renumbering a multi-statement dance to avoid transiently violating it.

## D58 — The snack variety window is centred on the candidate date, not trailing, and the warning never blocks a write

**Decided.** `snack_variety.dart`'s `varietyWindowAround` returns a window
`kVarietyWindowDays` (7) either side of the date being considered — 15
calendar days inclusive, close to `docs/DATA_MODEL.md`'s original "last 14
days" figure but centred rather than trailing. `shouldWarnOnRepeat` fires at
`kVarietyWarnAtOrAbove` (2) or more existing occurrences in that window. The
screen's warning dialog (Cancel / Add anyway) is advisory only — declining to
proceed after seeing it is the only way the check stops a write; the check
itself never does.

**Why.** `docs/DATA_MODEL.md`'s original sketch worded this as a trailing
window ending on the candidate date, written before the meal plan existed to
plan against. A meal plan is a forward-looking document: most of what a
candidate snack should be compared against has not been cooked yet, only
planned, and a trailing window only warns when slots happen to be filled in
calendar order — planning Saturday's snack before Wednesday's would get no
warning from a trailing window even though the two sit five days apart. A
centred window catches the repeat regardless of the order slots are filled
in, which is how meal planning actually happens. Advisory rather than
blocking follows D54's instinct for every meal-plan failure already: a
cook's plan is not something the app second-guesses past a single "are you
sure".

**Rejected.** A trailing window matching `docs/DATA_MODEL.md`'s original
wording literally — would depart from the app's actual usage pattern for the
reason above. Blocking the write outright — a warning that cannot be
overridden would make "plan the same snack twice on purpose" impossible, and
there is nothing wrong with that on occasion.

## D59 — `shopping_lists` carries `updated_at`; `household_pantry_prefs` carries no lifecycle columns at all

**Decided.** `shopping_lists` gets the full rule 4 treatment — `updated_at`
with a `set_updated_at()` trigger, `deleted_at`, no DELETE policy — even
though `docs/DATA_MODEL.md`'s sketch gave it only `deleted_at`.
`shopping_list_items` is a D24 child table (no `household_id`, no lifecycle
columns, cascades, hard delete, RLS through its parent).
`household_pantry_prefs` carries a `household_id` and still gets no
`deleted_at` and no `updated_at`, and clearing a preference is a hard delete.

**Why.** Rule 4 is not a rule about which columns a table happens to need, it
is a rule about every table carrying a `household_id` — the same correction
D49 made to the `meal_plans` sketch. A snapshot is never edited after
generation, but regenerating soft-deletes the previous list, and that write
has to be visible to Phase 2's delta fetch or the Drift cache will keep
serving a retired list in a supermarket.

`household_pantry_prefs` is the exception, and this is not a fresh call:
migration 6 already wrote the reasoning down when it taught
`merge_ingredients` to reconcile the table — "a join table with no
`deleted_at`, on the `household_members` precedent in D24, so the delete is a
hard one". Clearing a preference is returning to the global default, not
recording that you once held an opinion. This entry records that ruling where
it can be found, rather than re-deciding it.

**Consequence.** Creating these three tables made two `merge_ingredients`
branches reachable for the first time since Phase 1b. They needed no changes —
the `to_regclass()` guards and the `known` array in
`merge_ingredients_test.sql` were written for this moment — but "the table is
named" is not "the naming works", so `rls_shopping_lists_test.sql` asserts
both branches positively rather than leaving the FK-coverage check to stand in
for them.

**Rejected.** Following the sketch literally and omitting `updated_at` — would
hand the delta fetch a retired list it cannot tell is retired.

## D60 — The sum is carried in exact rationals, and stored as an integer pair

**Decided.** `lib/features/shopping_list/domain/rational.dart` is an exact
rational type; the aggregation converts, scales and sums entirely in it, and
rounds only when rendering. `units.to_base` is read through
`Rational.parseDecimal` from `Unit.toBaseExact` — the `numeric` exactly as
Postgres sent it — not through `Unit.toBase`'s `double`.
`shopping_list_items.quantities` stores `amount_num` / `amount_den`, not
`docs/DATA_MODEL.md`'s sketched single `amount`.

**Why.** Rule 5, and `Quantity`'s own doc comment, which predicted this exact
moment: "A shopping list that sums halves and thirds across a week has to land
on exact numbers or it will quietly ask for 0.9999999 kg of flour." The thing
that makes it affordable is that **no `to_base` value is irrational** —
`28.349523125` is `28349523125 / 10^9` — so exactness costs a parse of a
string that was already on the wire, not a new unit table. `⅓ šolje` three
times is 240 ml, not 239.99998, and the emulator run confirmed the equivalent:
`2 dl` plus `⅓ šolje` summed to exactly 280 ml.

Storing the pair rather than a number keeps that guarantee across the wire. A
rounded column would put a float back in the one place rule 5 was written to
keep it out of, and a list that is regenerated or re-read would round twice.

**Consequence.** `Unit` gains `toBaseExact`, nullable, beside the existing
`toBase`. Two representations of one constant is a smell, but the alternative
was changing `toBase` to a rational and rewriting the parser and line editor,
which do not care about exactness and for which a `double` is the right type
— the field's own doc already said so.

**Rejected.** Summing in `double` and rounding at render — the rounding does
hide most of the drift, which is exactly what makes it a bad trade: the bug
would be invisible until a quantity was wrong in a shop. Making `Quantity` do
the arithmetic — it models what a cook wrote, carries ranges and renders as
`1½`; an intermediate sum is a different thing and does not want a range.

## D61 — Generating a list is one `security invoker` RPC

**Decided.** `save_shopping_list(household, plan, from_date, to_date, loc,
items jsonb) returns uuid` writes the parent and every item in one
transaction, assigning `position` from array order. `security invoker`, so RLS
still decides; the membership check inside it exists only so a caller who
cannot see the household gets a refusal instead of a successful no-op.

**Why.** The third time this argument has been made — D36 for
`replace_recipe_lines`, D44 for `save_imported_recipe`. An insert followed by
an insert can fail between the two, and a headless shopping list is
indistinguishable on screen from a week with nothing planned. `position` is
derived rather than read from the JSON for the reason
`replace_recipe_lines` gives: the client already sends items in display order,
and deriving it makes a duplicated or missing position inexpressible.

**Rejected.** Two inserts from the client — the failure mode is silent and
looks like correct behaviour. `security definer` — the tables have real
policies, so the function is atomicity, not authority (D36).

## D62 — A planned meal can carry its own serving count, and the scale factor is `entry.servings / recipe.servings`

**Decided.** The meal plan entry's action sheet gains *Cooking for…*, writing
`meal_plan_entries.servings` through
`MealPlanRepository.setEntryServings`. The aggregator scales each line by
`entry.servings / recipe.servings` as an exact ratio, and by **1** whenever
either side is null or non-positive. "As the recipe says" clears the override
rather than storing the recipe's own number.

**Why.** `meal_plan_entries.servings` shipped in migration 14 and nothing ever
wrote it, which made `docs/DATA_MODEL.md`'s "scale by servings" step a no-op
that no amount of unit testing would have caught — the column was readable,
the aggregation was correct, and the factor was always 1 in the real app.
Adding the writer is what makes the step reachable, and it is a few lines on
an action sheet that already exists.

Falling back to 1 rather than guessing matters: a recipe with no serving count
of its own has nothing to scale *from*, and inventing a denominator would
change quantities the cook never asked to change. Clearing rather than copying
matters for the same reason — a copied number freezes a value that should
follow the recipe if the recipe is later corrected.

**Rejected.** Scaling by `entry.servings` alone — meaningless without knowing
what the recipe's own count is. Storing the recipe's servings on the entry as
a default — freezes a value that should track its source.

## D63 — Pantry staples are collapsed under "Probably have", never hidden, and the override works both ways

**Decided.** A flagged item renders inside a collapsed *Probably have*
`ExpansionTile` with its quantity intact, never omitted from the snapshot.
`household_pantry_prefs.always_have` overrides `ingredients.is_pantry_staple`
in **both** directions. Long-pressing an item records the override and
deliberately does **not** rewrite the list on screen; it says the change takes
effect next time.

**Why.** The first half was pre-decided in Phase 2 part 3's closing note and
is written down here properly. Five ingredients are flagged globally by the
seed (*so, ulje, šećer, voda, biber*) and every household disagrees with that
list somewhere — a one-way override would make "we never actually have sugar
in this house" unsayable. Hiding rather than collapsing would mean a cook who
is out of salt has no way to see that this week needed any, and D13's snapshot
is supposed to be a complete record of what the plan requires.

Not rearranging the visible list is the same instinct: the list is a snapshot
(D13), and a document that reorders itself while somebody is reading it in a
shop is worse than one that is slightly out of date and says so.

**Rejected.** Suppressing staples entirely — loses information the cook
sometimes needs. Rewriting the on-screen list when an override is recorded —
turns a snapshot into a live document, which is the thing D13 ruled out.

## D64 — The Drift database lives in `core/db/`, and `check_layers.dart` gets a second `core/` exemption for it

**Decided.** `lib/core/db/app_database.dart` holds `AppDatabase`, its two
tables and the `appDatabaseProvider` that constructs it. `tool/check_layers.dart`'s
drift rule (`if (uri.startsWith('package:drift'))`) gains a `lib/core/db/`
arm, exactly parallel to the `lib/core/supabase/` arm `supabase_flutter`
already has.

**Why.** One SQLite file is inherently shared, and Phase 2's remaining parts
put three more features on it (recipes, meal plans, the ingredient name
catalog). D33's "duplicate until a second caller shows up, then move to
`core/`" rhythm assumes the intermediate shape — the thing living in one
feature's `data/` while a second feature needs it — is legal. It is not,
here: `features/recipes/data/local_recipe_datasource.dart` importing
`features/shopping_list/data/app_database.dart` is exactly the cross-feature
import `_checkImport` refuses. The second, third and fourth callers are
already known, so paying the `core/` move now is not shipping ahead of a
need — it is the same move D43 made for the ingredient catalog and D52 made
for `currentHouseholdIdProvider`, on the same schedule those were made.

**Rejected.**
- One SQLite file per feature — four openers, four `schemaVersion`s, four
  things to wipe on sign-out, for a library whose whole idiom is one database.
- Deferring the move to Phase 2's next part, on the D33 precedent — the
  precedent does not apply; see above.
- Constructing `AppDatabase` from `core/` without ever naming a drift type
  (the D43 move) as the *whole* answer — it is still used at the boundary
  (`ingredient_catalog_providers.dart` and `shopping_list_providers.dart` name
  `AppDatabase`/`LocalShoppingListDataSource`, never `package:drift`), but the
  `@DriftDatabase`-annotated class itself has to import `package:drift`
  somewhere, and that somewhere needs its own sanctioned home.

## D65 — The cache stores the server's own wire shape in one JSON column; `ShoppingList` gains `updatedAt`, not `deletedAt`

**Decided.** `ShoppingListCache.data` and `UnitCatalogCache.data` hold exactly
the map a network response would otherwise produce and discard —
`ShoppingListWire.toWire()` / `shoppingListFromWire()` in
`features/shopping_list/data/dto/shopping_list_dto.dart` serve a Supabase row
and a cache blob with the one decoder, and `unitCatalogRowsToWire()` /
`unitCatalogRowsFromWire()` do the same for the two raw row arrays
`fetchUnitCatalog()` used to build and discard. `ShoppingList` gains a
required `updatedAt` field (`shopping_list_repository.dart`'s old
`_listColumns` already selected `updated_at` and threw it away); it gains no
`deletedAt` — see D68.

**Why.** One definition of "what a shopping list looks like on the wire" is
rule 6's own argument (one definition per side, verified against a shared
fixture) applied to a wire shape instead of a normalization function. The
alternative — building `ShoppingList`/`UnitCatalog` and re-serializing the
built object — cannot even be done honestly for the unit catalog:
`UnitCatalog._byAlias` and `_displayNames` are private with no getters, so a
built catalog cannot be re-serialized without widening its API for a reason
that has nothing to do with what the catalog is for. Caching the raw rows
instead also keeps `units.to_base` as the exact string PostgREST sent, which
is the whole of D60's guarantee — a second encode/decode through
`UnitCatalog`'s own `toBase` `double` would round it twice.

`updatedAt` is added truthfully now, on no live consumer yet, because a
household-scoped cache row with a column that has always lied is worse than
not having the column — see D71 for why this is not the same shipping-ahead
argument D35/D51 made.

**Rejected.**
- A second, generated serialization of `ShoppingList`/`UnitCatalog` (freezed
  `toJson`/`fromJson`) — would need a `Rational` converter for one and cannot
  be written for the other at all (see above), and would be a second
  definition of the wire shape to keep in step with the first.
- A `deletedAt` field on `ShoppingList`, "for symmetry" with `updatedAt` — it
  would be null in every instance the app can ever hold; see D68.

## D66 — Writing the cached list is delete-then-insert, scoped to the household, not `insertOnConflictUpdate` alone

**Decided.** `LocalShoppingListDataSource.upsertLatest` deletes whatever row
the household already has, then inserts the new one, in one transaction.
`ShoppingListCache` also carries a `uniqueKeys` constraint on `householdId`,
as a defensive backstop.

**Why.** Found by the first test written against it, not by reading:
`insertOnConflictUpdate`'s conflict target is the PRIMARY KEY, which is the
list's own `id` — so writing a *regenerated* list (a new `id` for a household
that already has a cached row under the old one, the ordinary case
`ShoppingListRepository.watchLatest` writes through on every successful
network read once anything has ever been cached) is a plain INSERT against
that key, not an update of the existing row. Without the fix, that INSERT
either leaves two rows for one household or — once the `uniqueKeys`
constraint below is added — trips it and gets silently swallowed by
`cacheWrite`, leaving the stale row in place forever. Delete-then-insert
makes "one row per household" this method's own guarantee rather than a
discipline every caller (`watchLatest`'s write-through, `generate()`,
`discard()`) has to independently get right.

The `uniqueKeys` constraint stays even though `upsertLatest` alone now makes
it unreachable through any real code path: it is what turns "a household
only ever has one live list at a time" from a claim several doc comments make
into something the schema itself refuses to violate, and it is what keeps a
future bug that writes around `upsertLatest` from corrupting
`readLatest`'s `getSingleOrNull` instead of failing loudly (well, quietly —
see D69) at the point of the bad write.

**Rejected.** `insertOnConflictUpdate` alone, trusting every caller to evict
first — this is exactly the assumption the first test written against it
disproved.

## D67 — A cached read is a two-emission `Stream`; reachability is a side-channel, not folded into the provider's value

**Decided.** `ShoppingListRepository.watchLatest` returns `Stream<ShoppingList?>`
— a cache hit (if any), then the network's answer — and `CurrentShoppingList`
is a `StreamNotifier`, not an `AsyncNotifier`. The provider's value type is
unchanged (`ShoppingList?`), so `ShoppingListScreen`'s `AsyncValue<ShoppingList?>.when`
and its test are untouched in shape. Every completed network attempt —
including one whose `NetworkFailure` is swallowed because a cache hit already
went out — reports through `onReachable`/`onUnreachable` callback parameters
to `lib/core/net/network_status.dart`'s `NetworkStatus`, a `keepAlive`
`Reachability` notifier `ShoppingListScreen`'s `_GeneratedAt` reads to show
"Showing your saved copy — no connection."

**Why.** `docs/ARCHITECTURE.md`'s own shape is "emit cached immediately ->
fetch -> upsert cache -> emit fresh", and `StreamNotifier` is the one shape
where the second emission is part of the provider's own lifecycle —
cancelled on dispose, routed into `AsyncValue` with no hand-rolled
`state = ...` after `build()` returns, which an `AsyncNotifier` would need
and which `unawaited_futures` (an error here) would force through
`unawaited()` with no cancellation to show for it.

Reachability could have ridden along on the stream's own value — a record
`({ShoppingList? list, bool stale})` — but that changes the provider's public
type to carry one screen's one sentence, for every present and future
consumer of `currentShoppingListProvider`. A plain callback keeps
`ShoppingListRepository` a `data/` file that knows nothing about Riverpod (it
takes `void Function()?` parameters, not a `core/net/` import), and a
side-channel `keepAlive` notifier is the same shape `data_revision.dart`
already uses for "something changed, watch here" — except this is "something
about the network changed", which is D47's "a best-effort path needs
something that notices it is always failing" made concrete, and it is
exactly what a later offline banner needs, built once rather than per screen.

**Rejected.**
- An `AsyncNotifier` setting `state` a second time after `build()` returns —
  a detached, unawaited continuation.
- `({ShoppingList? list, bool stale})` as the provider's value — see above.
- `connectivity_plus` (asked about, rejected before this part started) — a
  radio that is on but cannot reach Supabase is offline for our purposes, and
  `NetworkFailure` is already the signal `runGuarded` produces from a
  `SocketException`, a `TimeoutException`, or `FunctionException(status: 0)`.
  A second, independent connectivity check would disagree with that signal
  exactly when it matters (a captive portal answers a radio check and nothing
  else).

## D68 — The cache carries no `deleted_at`; a server tombstone is a hard delete locally

**Decided.** `ShoppingListCache` has no lifecycle column of its own. A row is
either the household's current list, or it is gone.

**Why.** D23 keeps a soft-deleted `shopping_lists` row visible to the
*repository* so a later delta fetch can evict it — it is never visible to the
*screen*, because `RemoteShoppingListDataSource.fetchLatest` already filters
`deleted_at is null`. The cache's job is to answer "what would the server
show me right now", which never includes a tombstone, so the cache has
nothing to remember once a row is retired — only somewhere to stop having it.
`ShoppingListRepository.softDelete` evicts the local row in the same call
that soft-deletes it remotely; `watchLatest` evicts on the household's behalf
when a fresh network read comes back with nothing a cache hit had promised.

**Rejected.** A `deletedAt` column mirroring the server's, "for completeness"
— it would need a value nothing ever writes (an evicted row is deleted, not
marked), and it is the thing D65 explicitly declined to add to `ShoppingList`
for the same reason.

## D69 — A cache failure is never a read failure or a write failure

**Decided.** `lib/core/db/cache_guard.dart` holds `cacheOrElse` (reads: log
and return a fallback) and `cacheWrite` (writes: log and do nothing further).
Every method on `LocalShoppingListDataSource` and `LocalIngredientDataSource`
is wrapped in one of the two. Nothing from `package:drift` — a
`SqliteException` from a corrupt file, a `FormatException` from a blob an
older build wrote in a shape this one no longer decodes — is allowed to reach
`runGuarded`.

**Why.** `runGuarded`'s bare `catch` maps anything unrecognised to
`UnknownFailure` — "Something went wrong" — which is the worst possible
outcome for a cache failure: it reports a local, disposable problem as a
server problem. A failed cache read is a miss and falls through to the
network exactly as if nothing had ever been cached; a failed cache write
costs a round trip next time and nothing else. Per D47, this does not swallow
silently: both functions log under the `AppDatabase` name, the same
best-effort-and-log shape `RecipeEditor`'s orphaned-image cleanup already
uses. Nothing reads that log yet — naming a consumer for it is part of a
later part's admin screen, not this one.

**Consequence worth knowing.** `cacheOrElse`/`cacheWrite` also absorb the
`MissingPluginException` that `path_provider` throws under `flutter test`,
which is what lets every existing widget test go on not knowing the cache
exists: they see a permanent cache miss and behave exactly as they did before
this part.

**Rejected.** Letting a drift exception fall through to `runGuarded`'s bare
`catch` — the `UnknownFailure` mislabelling above.

## D70 — Two kinds of cached row, and only one of them reads cache-first or dies with the session

**Decided.** The shopping list cache is household-scoped
(`ShoppingListCache.householdId`), read cache-then-network, and wiped by
`AppDatabase.clearHouseholdCache()` on sign-out
(`SettingsScreen._signOut`, before `AuthRepository.signOut()`). The unit
catalog cache (`UnitCatalogCache`, always exactly one row, key
`unitCatalogCacheKey`) is global, read network-first with the cache only as a
fallback on `NetworkFailure`, and is never touched by the sign-out wipe.

**Why.** A shopping list left on a shared device after sign-out is a privacy
question; `units`/`unit_names` carry no `household_id` at all
(`docs/DATA_MODEL.md`: "two dozen immutable reference rows that only a
migration writes"), are readable by any authenticated caller, and wiping them
would put `3 clove` back on the very first offline session after the next
person signs in — the exact bug this part exists to fix
(`shopping_list_screen.dart`'s old `ref.watch(unitCatalogProvider).value ??
UnitCatalog.empty()` fallback, and `formatItemQuantity`'s `_scaled()` finding
no `kg`/`l` rung on an empty catalog).

The read order differs for the same reason. The shopping list is a
household's own data that changes on someone else's say-so (a second device
regenerating it) and is worth showing stale rather than not at all — the
whole of D12's argument. The unit catalog is reference data with no
`updated_at` of its own to go stale between one session and the next, so
there is nothing to gain from showing a cached answer before a fresh one a
moment later, and network-first means `fetchUnitCatalog()` stays one
emission, a plain `Future<UnitCatalog>`, for a value nothing here treats as a
stream.

**Rejected.** Wiping the whole cache indiscriminately on sign-out — see above.
Cache-then-network for the unit catalog, matching the shopping list "for
consistency" — the two entities do not share the property (staleness has a
size) that makes cache-then-network worth its extra emission.

## D71 — No `last_sync_at` / delta-fetch machinery yet, and D35/D51's "ship ahead of the consumer" precedent does not transfer

**Decided.** Neither cache table carries a sync watermark. `AppDatabase.schemaVersion`
is `1`, and `MigrationStrategy.onUpgrade` drops every table and calls
`createAll()` rather than writing an actual migration.

**Why.** D35 shipped `recipes.image_path` empty, and D51 shipped
`'leftover'` unreachable, because both live in a Postgres migration — and an
applied migration is never edited (CLAUDE.md), so the cost of adding either
column later would have been a second migration telling two stories about
one column's history. A Drift table is the opposite: it is a *cache*, and
Supabase remains the only truth (D12), so the honest migration strategy is
drop-and-refetch, not a migration history for data that is disposable by
construction. Adding a `last_sync_at` mechanism in a later part costs a
`schemaVersion` bump and nothing else — there is no irreversibility here for
"ship it now" to be an argument against.

The shopping list also gives a delta fetch nothing real to be right about:
its read is `.limit(1)` on one row, so there is no multi-row delta to
express yet. The decisions that matter for one — per-table or
per-household-per-table watermark, advancing it from the `max(updated_at)`
of rows actually received rather than a local clock (the only version that
does not silently drop rows under clock skew) — are only answerable with a
real multi-row fetch (recipes, meal plan weeks) in front of them. What does
carry forward from this part: every household-scoped cache column set
(`householdId`, `updatedAt`) is populated truthfully from day one (D65), so a
later watermark has something honest to compare against instead of a field
that has always lied.

**Rejected.** Adding a `last_sync_at` table now, on the D35/D51 precedent —
the precedent's premise (irreversibility) does not hold for local cache DDL;
see above.

## D72 — The delta-fetch watermark is per-(entity, scope), advanced from the max `updated_at` received, and the display-name chain is ported to Dart against a shared fixture

**Decided.** `SyncWatermarks` (`entity`, `scope`, `syncedAt`) is the
mechanism D71 deferred: one row per entity per scope (a household id, or
`globalSyncScope` for reference data with no household of its own), so that
syncing one household's recipes can never move the ingredient name
catalog's watermark or vice versa. `SyncWatermarkStore.advance` takes the
timestamp to advance to as a parameter — the caller computes it as the
max(`updated_at`) of the rows a fetch actually received — and nothing in
`core/db/` ever calls `DateTime.now()` for this. A missing watermark reads
as null and means "fetch everything," which costs one refetch and is never
wrong, the same tolerance D71 built the rest of the cache on.

Reading offline also needs `ingredient_display_name()`'s fallback chain,
and there is no RPC offline to ask. Migration 4's own comment rejected
reimplementing it in Dart, "out of reach of the SQL tests" — true when
there was no offline reader to serve. This narrows that call rather than
reversing it outright: `DisplayNameChain` in
`features/ingredients/domain/display_name_chain.dart` ports the chain's
four-clause `order by` line for line, and `test/fixtures/display_names.json`
is asserted on both sides — a Dart test over the fixture directly, and
`tool/gen_display_name_sql.dart` generating `supabase/tests/
display_names_test.sql` from the same file, on `normalize_text()`/
`TextNormalizer`'s exact precedent (rule 6, D5). Change one, change both,
regenerate the SQL, run `make test-sql`.

**Why.** D71 named the two things a delta fetch needs that a single-row
shopping list read could not exercise: a per-table (or per-household-per-
table) watermark, and an answer to "advance from what, when a local clock
and a server clock disagree." Recipes and the ingredient name catalog are
the first two entities that give the design something real to be right
about. Advancing from the max `updated_at` **received**, rather than the
local wall clock, is the part that actually matters: a clock advanced to
"now" on the phone would silently drop every row the server writes in the
gap between the fetch starting and the phone's own clock reading it — clock
skew is not paranoia here, it is the one bug a watermark exists to avoid.

The display-name chain's fixture is deliberately not the same file
`normalization.json` uses — it is a different contract (a fallback order
over locale/display-flag/recency, not a text transform) — but it is
governed by the identical rule: one definition per side, verified together,
because two independently-written implementations of "which name wins"
disagreeing is exactly the failure D1 exists to prevent, now duplicated
across a network boundary that can be down.

**Rejected.**
- A single global watermark — would make syncing one entity reset every
  other entity's progress, forcing a full refetch of everything whenever
  anything changed.
- Advancing the watermark to `DateTime.now()` at the end of a successful
  fetch — the clock-skew bug above, and the reason this decision names the
  computed-max requirement explicitly rather than leaving it to convention.
- Leaving `ingredient_display_name()`'s chain RPC-only and showing raw
  ingredient ids or bare `raw_text` offline for every matched line — passes
  no test, and defeats the entire reason the ingredient catalog is on
  Phase 2's offline list in `docs/ARCHITECTURE.md`.

## D73 — The ingredient-name cache and its sync live in `features/recipes/data/`, not `features/ingredients/data/`, until a second caller exists

**Decided.** `LocalRecipeDataSource` holds the read/write/resolve methods
for `IngredientNameCache`, and `RemoteRecipeDataSource`/`RecipeRepository`
hold the delta fetch of `ingredient_names` and the best-effort background
sync that keeps it warm. `IngredientRepository` and
`LocalIngredientDataSource` (`features/ingredients/data/`) are untouched by
this part.

**Why.** `ingredient_display_names` has exactly one caller in the whole
codebase: `RecipeRepository`. Putting the offline version in
`features/ingredients/data/` — the seemingly natural home — would need
`RecipeRepository` to call into it, and `tool/check_layers.dart` forbids
`features/recipes/data/` from importing `features/ingredients/data/`
directly (D33): that is the exact wall Phase 1c hit before D43 moved the
catalog to `core/ingredients/`. `core/` cannot absorb this instead: the
checker restricts `package:drift` to `data/` and `core/db/`, and
`package:supabase_flutter` to `data/` and `core/supabase/`, so a
cross-feature `core/` helper could hold the cache *read* (drift only) but
never the network *sync* (supabase_flutter) — splitting one round trip
across two files and two owners, for a boundary with no second caller to
justify it yet.

D43's own precedent is the better fit, read literally: Phase 1c's ingredient
catalog datasource was duplicated once, with a note that a third caller
should reopen the decision. There has never been a first duplication here —
only one caller has ever existed — so there is nothing to deduplicate yet.
The moment a second feature needs `ingredient_display_names` (Phase 3's
translated recipe view is the likely candidate), that is the signal to
extract this into `core/ingredients/`, exactly as D43 describes, and not a
moment before.

**Rejected.**
- Building the sync in `features/ingredients/data/` and having
  `RecipeRepository` call it directly — the forbidden cross-feature `data/`
  import D33 already ruled out.
- A `core/ingredients/` helper split across a drift-only read and a
  supabase-only write — legal per file, but two files and two owners for
  one round trip nobody but recipes has ever asked for.
- Waiting to build recipe-detail offline resolution until the ingredients
  feature "properly" owns it — blocks a Phase 2 Done-when item on an
  abstraction Phase 2 does not need yet.

## D74 — A single recipe's detail reads network-first with a cache fallback; the whole list reads cache-then-network

**Decided.** `RecipeRepository.fetchDetail` tries the network and falls
back to the cache only on a `NetworkFailure` — one emission, the same shape
`IngredientRepository.fetchUnitCatalog()` uses (D70). `RecipeRepository
.watchList` (the whole household's recipes) is a two-emission stream, cache
then network — the same shape `ShoppingListRepository.watchLatest` uses
(D67). The two reads of the same underlying cache disagree on purpose.

**Why.** D67's argument for cache-then-network is that a household's own
data "changes on someone else's say-so" and is worth showing stale rather
than not at all while a fresh answer is fetched in the background — true of
the whole list (another device may have added a recipe moments ago) in
exactly the way it is true of the shopping list. D70's argument for
network-first is that showing a stale answer before a fresh one buys
nothing when there is nothing to gain from the staleness. A single
recipe's detail sits closer to D70's case than D67's: it is fetched
on-demand exactly when the cook opens it, an edit to it while they are
mid-read is rare, and Phase 2's actual requirement — readable with no
network at all — is fully met by a fallback, not by an extra emission
nobody is likely to see update.

Network-first also keeps `recipeDetailProvider`'s public shape a plain
`Future<RecipeDetail>`, unchanged since before this part: every existing
override in `recipe_screens_test.dart` (`recipeDetailProvider('r1')
.overrideWith((Ref ref) async => detail)`) keeps working verbatim.
`recipeListProvider` becoming a `StreamNotifier` family did need a stub
rewritten (`_StubRecipeList`, on `shopping_list_screen_test.dart`'s
`_StubList` precedent) — a real, contained cost this decision avoids paying
twice.

**Rejected.**
- A two-emission stream for `fetchDetail` too, for symmetry with
  `watchList` — pays for a second emission and a provider-shape change with
  no case in the app that benefits from seeing a stale detail before a
  fresh one.
- Network-first for `watchList` as well — the whole list is exactly the
  entity D67 already argued should show stale data rather than none, and
  reversing that for consistency with `fetchDetail` would undo D67's own
  reasoning for no reason specific to recipes.

## Open / deferred

- **Client vs Edge Function split** — rule of thumb written in
  `docs/ARCHITECTURE.md`. Settled enough to build on.
- **Thin web layer** — deferred to Phase 4. Leaning Next.js App Router on
  Vercel against the same Supabase project, for public invite links and
  a shareable read-only recipe page. Not decided in detail. Do not build in
  Phase 1–3.
- **Cross-family unit conversion** — deferred, see D9. `ingredients.density_g_per_ml`
  and `piece_weight_g` still exist and are still never populated. Phase 2 part 4
  shipped the shopping list without them, as D9 said it could: an ingredient
  measured both by mass and by volume in one week renders as two entries on one
  line, which is the documented behaviour, not a gap.
- **Handwritten card OCR quality** — unknown until there's a real card to test.
- **No model call has ever run.** Phase 1d ships three importers, and tier 0
  (reading prose or a page) and tier 4 (batched matching) have never executed:
  the Anthropic account has no credit balance. Everything either side of them is
  verified against the running stack — the JSON-LD path, the SSRF guard, the
  storage policies, the job lifecycle, the confirm screen, the save. The prompts
  and the request shapes are not.
- **The iOS share extension** — see the 1d notes in `docs/ROADMAP.md`. Android
  shares work; iOS needs a Share Extension target, an app group and
  entitlements. SPM is already enabled and the project uses the scene lifecycle,
  both of which matter to whoever does it.
- **Import photos are never pruned.** A completed or dismissed job leaves its
  object in `import-uploads`. Keeping it is deliberate — a failed job can be
  re-run against the same photograph — but nothing collects them. Belongs with
  Phase 2's Storage work, which has to think about lifecycle anyway.
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
- **Nothing notices a permanently-failing best-effort path** — see D47. Tier 4
  failed silently for three parts because the only symptom was a row that never
  appeared in `ai_usage`. Phase 2's admin screen already plans to show
  `match_method` distribution; a tier that stops appearing in it is the signal.
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
- **Thumbnails on the week grid's own tiles, and copying or clearing a whole
  week** — see D53. The picker gets thumbnails for free from
  `_withImageUrls`; the grid's tiles deliberately do not, and no second
  caller needs it yet. Copying/clearing a week is where `meal_plans.deleted_at`
  gets its first human-triggered writer and D50's resurrection path gets
  exercised outside the SQL suite — still unbuilt after Phase 2 part 3, which
  closed the other three items this note used to list (leftover entries,
  the snack variety check, within-slot reordering — D55–D58).
- **The rest of the Drift cache** — see D64–D74. Phase 2 part 6a added the
  `last_sync_at`-style watermark D71 deferred (`SyncWatermarks`, D72) and
  used it to cache recipes and the global ingredient name catalog
  (D72–D74). **Meal plans are the one entity still uncached** — the same
  watermark mechanism applies, keyed per `(household_id, week_start)` rather
  than per household, since `meal_plan_entries_touch_plan()` already
  maintains `meal_plans.updated_at` for exactly this. The offline banner (a
  global "you're offline", distinct from the shopping list screen's own
  "showing your saved copy") and the admin screen's
  `match_method`/cache-health surfacing are both still unbuilt.
- **A generated list is never compared against the plan it came from** — see
  Phase 2 part 4's own closing note, unchanged by this part. Editing the week
  after generating still leaves a list that is quietly stale on the server
  side of the question; this part only made the *client* side of staleness
  (no connection, showing a saved copy) visible, which is a different
  question answered a different way.

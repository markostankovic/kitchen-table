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

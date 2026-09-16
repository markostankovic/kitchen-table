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

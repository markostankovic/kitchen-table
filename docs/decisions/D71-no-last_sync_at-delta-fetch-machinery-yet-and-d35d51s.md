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

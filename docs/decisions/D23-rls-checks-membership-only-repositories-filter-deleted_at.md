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

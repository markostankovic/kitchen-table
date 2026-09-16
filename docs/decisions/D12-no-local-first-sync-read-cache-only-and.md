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

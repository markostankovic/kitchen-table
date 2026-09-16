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

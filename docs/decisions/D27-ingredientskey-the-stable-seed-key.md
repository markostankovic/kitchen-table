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

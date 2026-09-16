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

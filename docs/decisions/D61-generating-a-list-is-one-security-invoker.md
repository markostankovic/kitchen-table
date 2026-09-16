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

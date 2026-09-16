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

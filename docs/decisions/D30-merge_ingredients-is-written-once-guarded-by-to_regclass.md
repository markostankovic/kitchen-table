## D30 — `merge_ingredients()` is written once, guarded by `to_regclass`

**Decided.** The function handles `recipe_ingredients` (Phase 1c),
`shopping_list_items` and `household_pantry_prefs` (Phase 2) behind
`to_regclass('public.…') is not null` and a dynamic `EXECUTE`. It is correct
today and needs no rewrite when those tables land.

**Why.** `docs/DATA_MODEL.md`'s step 1 repoints `recipe_ingredients`, which
does not exist yet. The alternative is a `create or replace` in 1c's migration
— but the 1c roadmap entry does not mention `merge_ingredients` at all, so
that rewrite is exactly what a future session would forget, and the symptom
would be a silent dangling reference to a retired ingredient.

The explicit table list is kept honest by an FK-coverage assertion in
`supabase/tests/merge_ingredients_test.sql`: it walks `pg_constraint` and fails
the moment a foreign key to `ingredients(id)` appears from a table the function
does not name. Same move as `tool/check_layers.dart` — encode the invariant in
a test rather than trust a future session to remember.

**Nothing is deleted.** Per D28's total unique index, two ingredients cannot
share an alias, so a merge cannot produce a duplicate name row. The repoint is
a plain `UPDATE`. What *can* collide is `one_display_name_per_locale`, since
both ingredients may have their own display name for a locale; those rows are
demoted, not deleted, so the string stays matchable and merely stops being the
one shown back.

**Two traps, both found by the test rather than by reading.**
- Parameters may not be named `source` / `target` as DATA_MODEL writes them:
  `source` is also a column of `ingredient_names`, and a plpgsql parameter that
  shares a name with a column in the same statement is an ambiguity error.
- **`revoke execute … from public` is not sufficient on Supabase.** The
  platform ships `alter default privileges in schema public grant all on
  functions to postgres, anon, authenticated, service_role`, so `anon` and
  `authenticated` hold EXECUTE in their own right and survive a PUBLIC revoke.
  The test called this `SECURITY DEFINER` function successfully as
  `authenticated` with the PUBLIC revoke already in place — a data-destruction
  endpoint that would have shipped looking correct. **Every future
  `SECURITY DEFINER` function not meant for clients needs the three-role revoke
  and a test that proves it.**

**Rejected.**
- Discovering referencing tables from `pg_constraint` at runtime — never goes
  stale, but has to guess a conflict strategy per table and would silently
  sweep in tables nobody considered.
- Writing a partial function now and extending it in 1c — see above.

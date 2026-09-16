## D59 — `shopping_lists` carries `updated_at`; `household_pantry_prefs` carries no lifecycle columns at all

**Decided.** `shopping_lists` gets the full rule 4 treatment — `updated_at`
with a `set_updated_at()` trigger, `deleted_at`, no DELETE policy — even
though `docs/DATA_MODEL.md`'s sketch gave it only `deleted_at`.
`shopping_list_items` is a D24 child table (no `household_id`, no lifecycle
columns, cascades, hard delete, RLS through its parent).
`household_pantry_prefs` carries a `household_id` and still gets no
`deleted_at` and no `updated_at`, and clearing a preference is a hard delete.

**Why.** Rule 4 is not a rule about which columns a table happens to need, it
is a rule about every table carrying a `household_id` — the same correction
D49 made to the `meal_plans` sketch. A snapshot is never edited after
generation, but regenerating soft-deletes the previous list, and that write
has to be visible to Phase 2's delta fetch or the Drift cache will keep
serving a retired list in a supermarket.

`household_pantry_prefs` is the exception, and this is not a fresh call:
migration 6 already wrote the reasoning down when it taught
`merge_ingredients` to reconcile the table — "a join table with no
`deleted_at`, on the `household_members` precedent in D24, so the delete is a
hard one". Clearing a preference is returning to the global default, not
recording that you once held an opinion. This entry records that ruling where
it can be found, rather than re-deciding it.

**Consequence.** Creating these three tables made two `merge_ingredients`
branches reachable for the first time since Phase 1b. They needed no changes —
the `to_regclass()` guards and the `known` array in
`merge_ingredients_test.sql` were written for this moment — but "the table is
named" is not "the naming works", so `rls_shopping_lists_test.sql` asserts
both branches positively rather than leaving the FK-coverage check to stand in
for them.

**Rejected.** Following the sketch literally and omitting `updated_at` — would
hand the delta fetch a retired list it cannot tell is retired.

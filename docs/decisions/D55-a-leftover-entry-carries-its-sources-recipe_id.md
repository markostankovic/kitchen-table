## D55 — A leftover entry carries its source's `recipe_id`, derived by trigger and never sent by the client

**Decided.** `meal_plan_entries_leftover_source` (migration 15), a second
`before insert or update` trigger alongside migration 14's
`meal_plan_entries_before_write`, sets `new.recipe_id` from the source entry's
own `recipe_id` whenever `entry_kind = 'leftover'`, overwriting whatever the
client sent. It also refuses a source that is not itself an
`entry_kind = 'recipe'` row — no leftover-of-leftover chains — and refuses a
leftover pointing at itself.

**Why.** This is what D51's deliberately loose `'leftover'` check-constraint
branch was for: it required only `leftover_of_entry_id`, precisely so a later
migration could add `recipe_id` to the row without rewriting that constraint.
Deriving it, rather than trusting the client, is what makes the
denormalisation safe to build on — a leftover's `recipe_id` cannot disagree
with its source's, so the drift the loose branch permits is simply not
expressible, the same move `ensure_meal_plan` already makes for the plan id
and `meal_plan_entries_before_write` already makes for `position` (D49, D50).
The payoff is immediate: the snack variety check (D58) and `countRecipeInSlot`
can match `recipe_id` alone and count a leftover as an occurrence of its
source recipe, with no join back through `leftover_of_entry_id`. The shopping
list (Phase 2's next part) gets the same thing for free when it needs to skip
leftovers so nothing is bought twice.

A second, additively-named trigger rather than folding a fourth invariant
into `meal_plan_entries_before_write`: that function's own comment in
migration 14 describes exactly three invariants, and CLAUDE.md forbids
editing an applied migration to keep that description honest. Trigger
execution order is alphabetical by name, so `..._before_write` still runs
first, but the two turned out to be independent in practice — position
assignment and the week-boundary guard never read `recipe_id` or the leftover
source's row.

**Rejected.** Trusting a client-sent `recipe_id` on a leftover row (D42's
argument against a machine tier writing catalog data unsupervised applies here
in miniature: a value nothing derives or checks is a value that can quietly
drift). Chains of leftovers — a leftover of a leftover has a head nobody can
find, and the check would need to walk an arbitrary-depth chain to resolve one
`recipe_id`.

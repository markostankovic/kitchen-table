## D49 — `meal_plan_entries` is a child table in the D24 sense, and its invariants live in triggers

**Decided.** No `created_at`, no `updated_at`, no `deleted_at`; hard delete
allowed; four RLS policies scoped through `meal_plans`, the same shape as
`recipe_ingredients` / `recipe_steps`. An `after insert or update or delete`
trigger (`meal_plan_entries_touch_plan`) touches `meal_plans.updated_at`. A
`before insert or update` trigger (`meal_plan_entries_before_write`) derives
`position` at the tail of its `(meal_plan_id, entry_date, slot)` group,
refuses an `entry_date` outside its plan's week, and refuses a
`leftover_of_entry_id` the caller cannot see.

**Why.** `docs/DATA_MODEL.md`'s original sketch gave this table `created_at`
and `updated_at` but no `deleted_at` — the only child table in that document
shaped that way, and not rule-4-compliant on its own terms either. It was an
inconsistency in the sketch, not a considered exception, and D24 governs: no
`household_id`, it cascades with its plan, and a removed entry is genuinely
gone. What the Phase 2 delta fetch actually needs is a *week* whose
`updated_at` moves when anything inside it changes — `replace_recipe_lines`
already does this by hand for a recipe's lines; here it is a trigger because,
unlike a recipe save, there is no single funnel: add, move and remove are
three separate statements, and a later part adds a fourth (leftovers).
`position` is assigned server-side for the same reason D36 gave for
`recipe_ingredients.position` — a client-computed `max()+1` is a
read-then-write race and a second definition of ordering; deriving it here
means a duplicate or missing position is not expressible. `position` has no
column default deliberately: a default is applied *before* a `BEFORE`
trigger runs, so a default of `0` would make "the client didn't say" and "the
client said 0" indistinguishable, and the trigger needs to tell them apart.

**Rejected.** Transcribing `docs/DATA_MODEL.md` literally — it would have
bought two columns nothing reads on a table that is neither child-shaped nor
rule-4-shaped. A `move_meal_plan_entry` RPC per mutation, when one trigger
covers add, move, and (later) leftover creation uniformly. A unique index on
`(meal_plan_id, entry_date, slot, position)` — it would turn two people
adding to the same empty slot at once into a spurious "already exists".

**Consequence.** Within-slot reordering is not expressible by this trigger —
every insert and every move lands at the tail. An explicit reorder RPC is a
later part's problem, when the UI actually offers it.

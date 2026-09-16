## D78 — `recipe_translations` is a child table that keeps its own lifecycle columns, and a touch trigger hands it to the existing delta fetch

**Decided.** Migration 17. No `household_id`, so D24 governs and rule 4's "no
hard deletes" does not reach this table: it cascades with its recipe, and a
soft-deleted recipe's translations are already unreachable. There is
deliberately no `deleted_at` — a translation is regenerable from the
original at any time, so removing one is a hard delete, the same call
`recipe_ingredients` and `recipe_steps` made, and it gets a DELETE policy for
the same reason. Unlike those two child tables, this one DOES keep
`created_at` and `updated_at`, with a `set_updated_at` trigger.
`recipe_translations_touch_recipe()`, on `meal_plan_entries_touch_plan()`'s
own shape, touches the parent recipe's `updated_at` on every insert, update
or delete.

**Why the lifecycle columns, when `recipe_steps` has none.** A step has no
life after it is written; a translation does. Part 3's review flow reads and
stamps it (`reviewed_by`, `reviewed_at`), and a re-translation overwrites the
same row in place rather than being deleted and re-inserted — `updated_at`
is the only signal that a review might now be stale against a newer
translation underneath it. `docs/DATA_MODEL.md`'s original sketch already
carried both columns without saying why; this is that reasoning, the same
correction D49 and D59 each had to write out in prose for their own tables
when a sketch's shape didn't match either "full rule 4" or "bare child table"
exactly.

**Why the touch trigger, and not `save_recipe_translation` touching the
parent by hand the way `replace_recipe_lines` does.** It would have worked,
but `recipe_translations` has three writers already named in this project —
`save_recipe_translation` now, part 3's review flow next, and a bare
`update`/`delete` under RLS is always legal since the four policies are
ordinary membership checks, not RPC-gated. A trigger is one definition that
covers all three; a hand-written touch inside one function covers only that
function. This is the load-bearing piece for offline: `RecipeCache.data`
stores the whole PostgREST row verbatim, `recipe_translations` rides along
embedded in it (no new cache table), and the delta fetch's
`updated_at > watermark` is the only thing that tells a device a translation
changed at all.

**Rejected.** Giving it no lifecycle columns at all, on `recipe_steps`'
precedent — would have left nothing for part 3's review flow to read a
staleness signal from, and nothing for the touch trigger to update. A
`deleted_at`, on the household-scoped tables' precedent — there is no
household_id here to make rule 4 apply in the first place, and a translation
that should go away is regenerated, not tombstoned.

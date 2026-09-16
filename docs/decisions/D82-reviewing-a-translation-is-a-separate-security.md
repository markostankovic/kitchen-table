## D82 — Reviewing a translation is a separate `security invoker` writer that updates in place and never creates a row

**Decided.** Migration 18. `review_recipe_translation(recipe, loc, new_title,
new_description, new_steps)` is a sibling of `save_recipe_translation`, not
a parameter added to it. It `update`s the existing row and refuses outright
if none exists for that locale — review edits prose that a machine (or a
prior review) already produced; there is no client-facing path that
hand-authors a translation from nothing, and this function is not it. No new
RLS policy: `recipe_translations_update` (migration 17) already carries both
`using` and `with check` over the same membership-through-parent predicate a
review write needs, so this function holds no privilege the caller does not
already have under RLS — it exists for validation and provenance, not
authority.

**Why a sibling, not a flag on `save_recipe_translation`.** Its own `on
conflict` deliberately resets `is_machine_generated`, `reviewed_by` and
`reviewed_at` to null on every re-translation (D78's own comment: the new
prose has not been seen by anyone yet). A review wants the opposite of that
on the same row. Two functions that want opposite defaults for the same
columns are not one function with a flag; they are two functions, and
`review_recipe_translation`'s own existence check plus update-only shape is
what keeps the "create" path solely `save_recipe_translation`'s.

**The position guard.** A reviewer may correct what a step says; they may
not add, drop or renumber one. `review_recipe_translation` reads the row's
own `steps` first (`select ... into old_steps`, which doubles as the
existence check) and refuses unless the incoming steps' positions are
exactly the row's own positions, as a sorted set. This checks against the
translation ROW, not `recipe_steps`: `alignSteps` (D80) already tied the row
to the recipe's own steps at write time, so the row is the nearer and
cheaper authority, and a review is by definition editing the document that
was opened. This is deliberately NOT rule 6's fourth cross-language pair —
`alignSteps` validates a model's answer against a source it was given; this
validates a human's edit against the row they opened. Same arithmetic,
different inputs, no fixture that could be meaningful for both, which is
why there is no `test/fixtures/step_positions.json` to go with it.

**Rejected.** A `reviewed boolean` parameter on `save_recipe_translation` —
would have needed a second conditional path inside a function whose whole
shape is "guard, then upsert", and would have let a re-translation and a
review race for the same row's meaning inside one function instead of two
functions with two clear jobs. Locking the row with `for update` before the
position check — nothing else in this project writes
`recipe_translations` concurrently for the same `(recipe_id, locale)`, and
no other function in the schema takes that lock, so adding it here would be
a precedent with no problem behind it.

## D44 — `save_imported_recipe`, the atomicity D37 said to revisit

**Decided.** One `security definer` function creates the recipe, writes its
lines and steps, and marks the job done — in one transaction. It composes
`replace_recipe_lines` (D36) and `finish_import_job` rather than reimplementing
either.

**Why, and why it does not contradict D37.** D37 ruled that a new recipe is
`create()` then `saveLines()` from the client, and ended: "Revisit if import
(1d) needs to write a recipe and its lines as one unit from the server side,
where the argument is different." It does, and it is. Manual entry is safe as
two steps because the draft keeps the id it was given, so a failed second step
is fixed by pressing Save again. An import has a **third** step — marking the
job done — and no such anchor: a failure between them leaves an orphan recipe
*and* a job still in `needs_review`, so pressing Save again creates a second
recipe from the same import.

**Consequence.** `household_id` comes from the job, never from the payload, and
`status` is forced to `draft` rather than read — anything AI-produced is draft
until a human marks it tested. The status guard runs *before* the insert, so a
job in the wrong state is refused rather than rolled back.

# D100 — The first additive `alter table ... add column`, and what it means for D35's precedent
**Status:** active
**Touches:** supabase/migrations/20260919061026_recipe_favorite_rating.sql

**Decided.** Extending an already-applied table gets a new timestamped
migration containing only `alter table ... add column` statements plus a
`comment on column` per column — nothing else. No RLS policy is restated and
no trigger is re-created, because both `recipes_select`/`recipes_insert`/
`recipes_update` (table-level predicates on `household_id`) and
`recipes_set_updated_at` (row-level, column-agnostic) already cover any new
column added this way. This is the house style for extending an applied
table going forward.

**Why.** Migration 19 (`is_favorite`, `rating` on `recipes`) is the first
migration in the repo that adds columns to a table created by an earlier
migration — every migration through 18 creates its own tables whole. D35,
D51 and D82 each avoided this by shipping a column ahead of its writer in
the *same* migration that created the table, specifically to dodge
retrofitting. This slice retrofits deliberately, because both columns ship
with a writer in the same slice, so there was no forward-reference to avoid
and no reason to wait for a table that does not exist yet.

**Rejected.** Restating the three `recipes` RLS policies or re-creating
`recipes_set_updated_at` in the new migration, "to be explicit" — migration
18 already set the precedent of declining to touch RLS for the same reason
(a column-agnostic policy needs no restatement), and doing it here would
imply the columns need special-casing they don't.

**Consequences.** The next migration that only adds columns to an existing
household-scoped table should look like this one: `alter table`, `comment
on column`, and a header paragraph explaining why RLS/trigger are silent
rather than omitted by oversight. D35/D51/D82's "ship the column ahead of
its writer" precedent still applies whenever a *new* table is involved; it
was never a rule against `alter table` on an old one, just a way to avoid
needing it.

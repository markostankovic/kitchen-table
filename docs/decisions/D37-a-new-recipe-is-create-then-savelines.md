## D37 — A new recipe is `create()` then `saveLines()`, and the draft keeps the id

**Decided.** The first save of a recipe is two calls: a plain insert into
`recipes`, then `replace_recipe_lines`. There is no `create_recipe` RPC.
`RecipeRepository.create` returns the whole row rather than just the id, and
`RecipeEditor.save` writes it into the draft **between** the two calls.

**Why not one RPC.** `recipes` has an INSERT policy and the insert alone has
nothing to make atomic, so D36's argument does not extend to it. An RPC would be
a second recipe write path to keep in sync with the first, plus a migration and
a SQL test, bought against a failure window of one round trip.

**Why the assignment between them matters.** It is what makes the pair safe. If
`saveLines` fails, the draft is already pointing at the recipe that was created,
so pressing Save again updates that one instead of creating a second. The worst
case is a titled recipe with no lines, sitting in the list, editable — a retry,
not a duplicate. Returning the whole row is also what lets the second save issue
an update at all: `household_id` and `created_by` are not the editor's to
invent.

**Revisit if** import (1d) needs to write a recipe and its lines as one unit
from the server side, where the argument is different.

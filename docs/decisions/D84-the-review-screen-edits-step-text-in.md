## D84 — The review screen edits step text in place, keyed by position, source stacked above each field -- no add, no delete, no reorder, no ingredients

**Decided.** `TranslationReviewDraft.setStepText` is keyed by
`RecipeStep.position`, not a synthetic `localId` the way `RecipeDraft`'s
line and step editors are. There is no `addStep`, `removeStep` or
`reorderSteps` on this draft at all. Every field on the review screen pairs
the recipe's own original text, read-only, directly above the editable
translation for it — stacked, not two columns side by side. No ingredient
editor appears anywhere on this screen.

**Why position is the identity here, and `RecipeDraft`'s local ids are
not.** `RecipeDraft`'s rows are added, deleted and dragged by a cook who is
composing a recipe, so identity has to survive all three and a value cannot
serve since two blank lines compare equal — hence a synthetic id.
`review_recipe_translation` (D82) refuses a step count or position that does
not already match the row, so the set of steps here is fixed for the whole
life of the screen; position already uniquely and stably identifies each
one, and adding a second id would be tracking two names for the same thing.

**Why stacked rather than side by side.** Phone width, and rule of legibility
— two columns of prose at 390dp is unreadable, and the reviewer's own eye
movement is "read the line above, fix the line below it," which is a
vertical motion, not a horizontal one.

**Why no ingredient editor.** Unchanged from D1 and D80: ingredient lines
are never translated per recipe, they render from the bilingual catalog at
read time, so there is nothing on this screen for an ingredient editor to
edit.

**Rejected.** Reusing `RecipeEditScreen`'s `ReorderableListView` step section
wholesale — it is drag-and-reorder by construction, and every affordance it
offers (add, remove, reorder) is exactly the thing `review_recipe_translation`
refuses server-side. Building the UI to allow what the database forbids
would only move the failure from "cannot happen" to "happens, then bounces
off a 22023."

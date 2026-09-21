# D106 — Translating from the editor saves first, and the translate gate has one definition
**Status:** active
**Touches:** lib/features/recipes/application/recipe_editor.dart, lib/features/recipes/domain/recipe_draft.dart, lib/features/recipes/domain/recipe_translation.dart, lib/features/recipes/domain/recipe_detail.dart, lib/features/recipes/presentation/recipe_edit_screen.dart

**Decided.** The editor's Translate action writes the recipe first
(`RecipeEditor.saveAndTranslate` calls `save()`, then
`RecipeRepository.translate` on the id it returns) rather than being
disabled while the draft is dirty. The target locale is
`draft.originalLocale`'s other language, not the reader's ambient locale --
`originalLocale` is a `SegmentedButton` the cook can flip mid-edit, and the
target follows it, the opposite of D86's read-side exception for
`RecipeDetail.readingLocale`. `canTranslateInto()`, a new pure function in
`recipe_translation.dart`, is now the one definition behind D85's "the UI
is the only guard" -- both `RecipeDetail.canTranslate` and
`RecipeDraft.canTranslate` call it rather than each restating `target !=
originalLocale && !existingLocales.contains(target)`.

**Why.** No dirty-tracking machinery exists on `RecipeDraft` and none
should be added for this alone -- and disabling the action while dirty
would leave a brand-new recipe with no way to reach Translate at all,
since `save()` is what mints its id in the first place. Saving first is
the only path that works for both a brand-new recipe and an edited one. A
single `canTranslateInto()` exists because D85's guard has no server-side
backstop (`translate-recipe` and `save_recipe_translation` will happily
reset a human's review) -- a second copy of the rule in `RecipeDraft`
could drift from `RecipeDetail`'s and silently reopen a translated recipe
to a second machine pass.

**Rejected.** `canRetranslate`, a narrower gate for re-running an
*unreviewed* machine pass -- D85 already declined to take this and nothing
about a second entry point changes that; left open again, for whenever it
becomes its own decision. Disabling Translate while the form is dirty --
rejected above, since it blocks the brand-new-recipe case entirely.

**Consequences.** A translate that succeeds at `save()` but fails at
`translate()` still leaves the recipe written -- the same partial-progress
stance D37 already takes for `save()` itself, so the cook's work is safe
and pressing Translate again picks up where it left off. A third entry
point to translation must call `canTranslateInto()` rather than restate
the rule a third time.

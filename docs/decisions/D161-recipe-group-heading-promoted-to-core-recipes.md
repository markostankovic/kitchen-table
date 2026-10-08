# D161 — The group heading is promoted to `core/recipes/widgets/` as `RecipeGroupHeading`
**Status:** active — amends D156 #4 (private `_GroupHeading`, and its expected home in `core/ingredients/`)
**Touches:** lib/core/recipes/widgets/recipe_group_heading.dart, lib/features/recipes/presentation/recipe_detail_screen.dart, lib/core/ingredients/widgets/ingredient_lines_editor.dart, docs/DESIGN_SYSTEM.md

**Decided.** Round `2026-10-06-round-2-recipe-structure`, 2026-10-07:
1. `_GroupHeading` becomes public `RecipeGroupHeading({text, top, bottom})`
   in **`lib/core/recipes/widgets/`**, with the body unchanged. Recipe
   detail's two call sites use it, and the private class is deleted.
2. `IngredientLinesEditor` uses it with D156's ingredient gaps (`xl`, or
   `xs` when it opens the list, above; `xs` below). In the editor it is
   indented past the grip (`grip + xs`), and in review by `md`, so it lines
   up with the row text. It has no grip and no tap action yet.

**Why.**
- The ingredient lines editor is the second user D156 was waiting for.
- Its home is `core/recipes/`, not `core/ingredients/`, because it also
  renders step headings. It is about a recipe's structure.

**Rejected.**
- Leaving it in `core/ingredients/`.
- Putting it in `lib/core/widgets/`: it knows its subject.

**Consequences.** A heading's grip, renaming and dragging belong to
`phase8-ingredient-sections-edit`. A 63-character heading was seen wrapping
cleanly in import review on 2026-10-08.

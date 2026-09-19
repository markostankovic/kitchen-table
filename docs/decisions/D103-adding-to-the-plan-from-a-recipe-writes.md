# D103 — Adding to the plan from a recipe writes through its own `core/meal_plan/` writer
**Status:** active
**Touches:** lib/core/meal_plan/meal_plan_writer.dart, lib/core/meal_plan/widgets/meal_slot_picker_sheet.dart, lib/features/recipes/presentation/recipe_detail_screen.dart

**Decided.** The recipe detail screen's "Add to meal plan..." writes a
`meal_plan_entries` row through a new keepAlive `MealPlanWriter` in
`core/meal_plan/`, not through `MealPlanEditor` (the Plan tab's own
notifier). `MealPlanWriter.addRecipe` derives its destination week from the
chosen `entryDate` (`PlanWeek.of(entryDate)`), the same rule
`MealPlanEditor.addLeftover` already carves out for a leftover's
destination (D56), rather than from any visible week.

**Why.** Two independent reasons, either alone enough to rule out reusing
`MealPlanEditor`. First, `MealPlanEditor._write` resolves the household and
then hands `ref.read(visibleWeekProvider)` to the repository call, and the
`meal_plan_entries_before_write` trigger (migration 14, D50) refuses an
`entry_date` outside that week — correct for the Plan tab's own week grid,
wrong from a screen with no visible week of its own. Second,
`mealPlanEditorProvider` is `autoDispose`: reading its `.notifier` from a
screen that never watches it risks the notifier being torn down mid-`await`,
and rebuilding it would fire a pointless `watchWeek` network fetch this
screen has no use for. `core/meal_plan/` is the sanctioned escape hatch for
this either way — `features/recipes/presentation/` may not import
`features/meal_plan/application/`, the same wall D53/D43 already crossed in
the other direction for `core/recipes/recipe_picker_providers.dart`.

**Rejected.** Widening `MealPlanEditor._write` to accept an explicit week
override — would touch the Plan tab's own write path for a caller that
isn't the Plan tab, and doesn't fix the `autoDispose` hazard. Making
`mealPlanEditorProvider` itself `keepAlive` — changes the Plan tab's own
lifecycle for every caller, not just this one, and the tab has no need to
outlive its screen.

**Consequences.** Two `MealPlanRepository`-backed providers now exist —
`mealPlanRepositoryProvider` (feature-local, keyed to the visible week) and
`mealPlanWriteSinkProvider` (`core/`, week-agnostic) — both `keepAlive`,
constructed identically. Cheap: `MealPlanRepository` is a stateless wrapper
over two datasources, the same trade `plannableRecipeSourceProvider` already
made for `RecipeRepository` (D53). A third caller needing to write a meal
plan entry from outside `features/meal_plan/` should reach for
`MealPlanWriter`, not mint a fourth copy.

## D54 — One visible week, a non-family provider, and every write lands immediately

**Decided.** `visibleWeekProvider` (`VisibleWeek`) holds the one week
currently on screen — not a family keyed on the week. `MealPlanEditor`
(`AsyncNotifier`, not a family either) watches it and `mealPlanRevisionProvider`,
resolves the household id, and fetches. There is no Save: `addRecipe`,
`addNote`, `moveEntry` and `removeEntry` all write immediately and then bump
`mealPlanRevisionProvider`, which is the only refresh — `build()` re-runs
because of the bump, so an extra `invalidateSelf()` would refetch twice.

**Why.** There is exactly one visible week at a time, the same way there is
exactly one signed-in user — a family would have modelled something that
does not exist, and a family keyed on `PlanWeek.of(DateTime.now())` would
have been clock-dependent to override in a test. `RecipeEditor` is
draft-then-save because a recipe is one document being composed and an
abandoned editor must write nothing (D37); a meal plan is not a document —
each entry is independent, and putting a recipe in Thursday lunch is
complete the moment it happens. D12 already rules out an offline draft
buying anything here. A failed write therefore has to be loud: the screen
catches `AppFailure` and shows it in a `SnackBar`, and because no action
mutates `state` directly, a failure never leaves a phantom entry behind —
the next successful bump is what the grid actually shows.

**Rejected.** A family provider keyed on the visible week (see above). An
offline-friendly draft for the week grid, mirroring `RecipeEditor` — nothing
here is composed as one unit the way a recipe's title-and-lines are, so the
draft would only add a way to lose changes to a back gesture.

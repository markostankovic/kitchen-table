## D62 — A planned meal can carry its own serving count, and the scale factor is `entry.servings / recipe.servings`

**Decided.** The meal plan entry's action sheet gains *Cooking for…*, writing
`meal_plan_entries.servings` through
`MealPlanRepository.setEntryServings`. The aggregator scales each line by
`entry.servings / recipe.servings` as an exact ratio, and by **1** whenever
either side is null or non-positive. "As the recipe says" clears the override
rather than storing the recipe's own number.

**Why.** `meal_plan_entries.servings` shipped in migration 14 and nothing ever
wrote it, which made `docs/DATA_MODEL.md`'s "scale by servings" step a no-op
that no amount of unit testing would have caught — the column was readable,
the aggregation was correct, and the factor was always 1 in the real app.
Adding the writer is what makes the step reachable, and it is a few lines on
an action sheet that already exists.

Falling back to 1 rather than guessing matters: a recipe with no serving count
of its own has nothing to scale *from*, and inventing a denominator would
change quantities the cook never asked to change. Clearing rather than copying
matters for the same reason — a copied number freezes a value that should
follow the recipe if the recipe is later corrected.

**Rejected.** Scaling by `entry.servings` alone — meaningless without knowing
what the recipe's own count is. Storing the recipe's servings on the entry as
a default — freezes a value that should track its source.

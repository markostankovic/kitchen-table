## D52 — "The caller's current household id" becomes one derived provider in `core/`, closing D33's last copy

**Decided.** `lib/core/household/current_household.dart` exposes
`currentHouseholdIdProvider`, a `Future<String?>` derived from
`currentHouseholdProvider`. `RecipeRepository._currentHouseholdId` is
deleted; `RecipeRepository.create` and `.uploadImage` now take `householdId`
as a parameter, resolved once in `RecipeEditor.save()`. `MealPlanRepository`
takes it the same way.

**Why.** `_currentHouseholdId`'s own comment named this exact moment: "if a
third feature needs it, that is the signal to revisit D33 rather than to
write a third copy." `meal_plan` is that third feature. D43 already
established the shape for this situation — the thing moves to `core/`, which
`tool/check_layers.dart` exempts from the cross-feature rule entirely, and
the duplicate is deleted rather than relocated. Deriving from
`currentHouseholdProvider` rather than adding a second `households` query:
that provider is already `keepAlive` and is already the one definition of
"which household" (`HouseholdRepository.fetchCurrent` — oldest undeleted
household the caller belongs to); a repository-level helper would have been
a second definition of that tiebreak, and would have cost a round trip on
every write this id feeds. Riverpod's own caching makes deriving it free.

**Rejected.** Moving the *query* itself into `core/supabase/` rather than
deriving a provider — that would centralise the duplicate instead of
removing it, keep `HouseholdRepository.fetchCurrent` as a second definition
of the same tiebreak, and still pay a round trip per write. Exposing
`currentHouseholdProvider` itself from `core/` — the `Household` model (its
name, who created it) is the households feature's business; only the id is
cross-feature currency, the same split `core/ingredients/` keeps between the
catalog's providers and `Ingredient` itself.

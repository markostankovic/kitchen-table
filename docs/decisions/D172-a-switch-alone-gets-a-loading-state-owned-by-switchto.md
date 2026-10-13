# D172 — Only a household switch gets the switch-loading state, and `switchTo` owns its signal
**Status:** active
**Touches:** lib/features/households/application/household_providers.dart, lib/core/household/current_household.dart, lib/core/household/widgets/household_switch_gate.dart, lib/core/household/widgets/household_switch_placeholder.dart, lib/core/household/widgets/household_tab_title.dart, lib/features/recipes/presentation/recipe_list_screen.dart, lib/features/meal_plan/presentation/meal_plan_screen.dart, lib/features/shopping_list/presentation/shopping_list_screen.dart

**Decided.** `phase9-household-switch-loading`, 2026-10-13. Builds on D169 and D171.
1. **Switch-only.** From a switch's start until a tab's provider has
   non-loading data, Recipes, Plan and List show the 4dp `primary` bar under
   the app bar, keep their frame, replace the content with one flat
   placeholder card, and disable write controls. Cold start, week paging,
   filters, regenerate and pull-to-refresh keep the spinner / 2dp bar, and
   one-household screens stay pixel-identical (Marko's call in planning).
2. **`CurrentHousehold.switchTo` owns the in-flight signal**
   (`HouseholdSwitchInFlight`, keepAlive, the target id), set before
   `select` and cleared in a `finally`. The header, its Undo and the
   Households list all get it by calling `switchTo`. Other features see it
   only as `core/household/current_household.dart`'s
   `householdSwitchPending` (bool) and `householdSwitchTargetName`.
3. **`HouseholdSwitchGate` and `HouseholdSwitchPlaceholder` /
   `HouseholdSwitchProgressBar` live in `core/household/widgets/`** (amends
   D171 #1's file list). The gate wraps each tab's whole `Scaffold`; it
   turns on when pending rises and off once pending is false **and** the
   tab's `dataLoading` is false, checked on both edges.
4. **The header holds the target name** until `householdSwitcherName`
   stops loading, because `myHouseholds` re-fetches after `switchTo`
   returns and its `.value` is the old name meanwhile. The block is inert
   while pending.

**Why.** It was more than cosmetic: List's `skipLoadingOnReload: true` kept
the **old household's list**, with Copy and Regenerate live, through the
switch's reload, and Recipes' tag chips leaked the same way via
`recipeListProvider().value`. A Riverpod dependency change is a reload and
keeps the previous value, so the tabs cannot tell a switch from a refresh
on their own. The signal has to sit in `switchTo`, since three callers switch.

**Rejected.**
- The loading state for every load: it breaks the round's constraint that
  one-household screens don't change.
- A flag in the header (the old `_switching`): it misses Undo's and the
  Households list's switches.
- Dropping `skipLoadingOnReload`: Phase 8 part 1 needs it for regenerate.
- `core/widgets/`: both widgets know what a household switch is.

**Consequences.**
- `householdSwitchPending` is a derived provider, so it is recomputed on the
  frame: a switch that starts and ends inside one frame is never seen as
  pending. A real switch is network-first with Drift writes and always spans
  frames. Widget tests hold `fetchCurrent` open with a `Completer`
  (`test/helpers/household_switch_harness.dart`).
- A tab first built mid-switch starts out awaiting.
- A switch clears Recipes' tag filter (a tag key is one household's
  vocabulary). Search text and Favorites carry over.

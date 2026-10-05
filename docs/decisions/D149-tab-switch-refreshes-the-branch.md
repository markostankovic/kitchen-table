# D149 — Switching tabs re-reads the selected tab; re-tapping does not
**Status:** active
**Touches:** lib/core/router/app_shell.dart, test/core/router/app_shell_test.dart

**Decided.** Phase 8 part 3, 2026-10-05:
1. **`AppShell` owns the refresh.** In `onDestinationSelected`, when the
   selected index differs from the current one, `_refreshBranch`
   `ref.invalidate`s that branch's top-level providers, then `goBranch`.
   `core/` may depend on features (D43). It imports `application/` only.
2. **What each tab refreshes:**
   - Recipes: the whole `recipeListProvider` family;
   - Plan: `mealPlanEditorProvider`;
   - List: `currentShoppingListProvider`;
   - Settings: `householdMembersProvider`.

   It leaves out `tagLabelsProvider` (network-only, so offline it would
   lose the labels), `recipeDetailProvider`, `visibleWeekProvider`,
   `currentHouseholdProvider` (keepAlive, the root of every household id),
   `ownProfileProvider` and `authStateProvider`.
3. **Re-tapping the current tab only pops to its root.** Pull already
   refreshes in place.
4. **Never a write.** No `generate()` / `regenerateCurrent()` on List (a
   pull there means generate, D147), and no `.bump()` of a
   `core/refresh/` revision.

**Why.**
- A household member's change made on another phone never showed up until
  you pulled. Each branch stays alive (`StatefulShellBranch`), so a switch
  used to re-read nothing.
- Every refreshed provider is a cached read (D67): the cache emits, then the
  server. Riverpod 3 keeps the previous value through a refresh, so the
  screen keeps its content and updates in place. Offline, the cache emits
  and the failure goes to `onUnreachable`, so there is no new offline path.
- A bump means "a write happened" and fans out (`MealPlanRevision` also
  reloads the shopping list, and `RecipesRevision` reloads tag labels). A
  tab switch is not a write.
- Re-signed photo URLs are cache hits since D148, so the recipe re-read is
  cheap.

**Rejected.**
- **A `core/refresh/` per-tab counter that each screen listens to.** It
  spreads the same wiring over four screens for no gain.
- **Refresh on re-tap.** That gesture already means "back to root", and pull
  covers refreshing in place.
- **Invalidating only the visible recipe-list instance.** The shell can't
  know the screen's query, tag or favourites arguments.

**Consequences.** The List tab's 2px `LinearProgressIndicator` flashes on
every switch onto it, which is acceptable feedback. A new tab, or a new
top-level provider on a tab, needs a line in `_refreshBranch`.

# D152 — The shopping long-press opens an "Always" menu with Undo; no one-off move
**Status:** active
**Touches:** lib/features/shopping_list/presentation/shopping_list_screen.dart, lib/core/l10n/arb/app_sr.arb, lib/core/l10n/arb/app_en.arb, test/features/shopping_list/shopping_list_screen_test.dart, docs/DESIGN_SYSTEM.md

**Decided.** Round `2026-10-06-round-2-recipe-structure`, canvas § B·2, 2026-10-06:
1. **A long-press opens a one-item menu at the press point** instead of
   changing anything. `Uvek u Verovatno imate` / `Always in Probably have`
   on a to-buy row, `Uvek na listi` / `Always on the list` on a
   Probably-have row. Text-only `MenuItemButton`, chrome (the reader's
   locale), theme-styled. The pressed row holds a `surfaceContainerHighest`
   fill (radius `sm`, bleeding `md` each side, behind the row) while it is
   open. Unmatched items still have no long-press.
2. **Picking runs D147's path unchanged:** `setPantryPref` then
   `regenerateCurrent()`, snackbar only if both succeed.
3. **The confirmation carries `Poništi` / `Undo`.** Undo writes
   `alwaysHave: !nowStaple` and regenerates again. Success shows no
   snackbar (the row moving back says it); failure shows the `AppFailure`.
   The snackbar passes `persist: false`, since in this Flutter an action
   otherwise keeps it up indefinitely.
4. **No one-off "Move to Probably have".** Marko's call, 2026-10-06.

**Why.**
- A one-off move would have to survive every rebuild (pull, Generate, the
  next long-press), so it needs storage on the list: per-item state on a
  snapshot. D13 rules that out, and D147 already rejected editing the
  snapshot in place. Only the permanent action fits.
- The menu step makes a permanent, household-wide change deliberate; Undo
  makes a slip cheap.
- Undo writes the opposite boolean rather than restoring "no override row"
  for a catalog-default staple: the household override beats the catalog in
  both directions (`aggregate_shopping_list.dart` step 5), so the list comes
  out the same, without a prefs read on every long-press.
- The menu item uses the pin tooltip's words, so the action and the marker it
  produces read the same.

**Rejected.**
- **The canvas's one-off item**, and any column, table or client-side
  override to carry it (above).
- **Leading icons.** The canvas's menu has no icon slot; only the recipe
  list's add menu keeps them (DESIGN_SYSTEM.md § Menu).
- **Reusing `clearFiltersChip` for `Poništi`.** Same Serbian word, different
  meaning; `undoSnackbarAction` is its own key.

**Consequences.** Amends D147's "long-press moves the item" (now a menu
pick); its regeneration rules stand. D151's pin no longer waits for a one-off
move: every Probably-have row is a staple, and the pin says so. Undo can
leave an explicit override where the catalog default used to decide. A
long-press on the pin itself shows its tooltip, not the menu. Open from the
walk: the menu is flush with the right edge near it (as the recipe list's add
menu), and in dark its `surfaceContainerHigh` equals the card fill, so over a
card it has almost no edge.

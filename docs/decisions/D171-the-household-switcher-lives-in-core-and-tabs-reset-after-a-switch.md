# D171 — The household switcher lives in `core/household/`; other tabs reset to root after a switch
**Status:** active
**Touches:** lib/core/household/widgets/household_tab_title.dart, lib/core/household/widgets/household_switch_sheet.dart, lib/core/household/widgets/household_row.dart, lib/core/household/household_role_label.dart, lib/core/household/current_household.dart, lib/core/router/app_shell.dart

**Decided.** `phase9-household-switcher`, 2026-10-13. Builds on D169 and D170.
1. **The header and the sheet live in `core/household/widgets/`**, the middle
   ground (D43, D53), because recipes, meal_plan and shopping_list all use
   them and must not import `features/households/`. `HouseholdRow` is
   promoted there unchanged (amends D170 #5), and the role label becomes
   `householdRoleLabel` beside it.
2. **The header's whole condition is `householdSwitcherName`**: the current
   name when `myHouseholds` has 2+, else null. That covers one household,
   unknown, and any `AppFailure` (offline: `myHouseholds` is network-only).
   Null renders the plain title in the same pixels as before. It reads no
   members, so the header never waits on a member count.
3. **After any household id change, every tab but the current one goes
   back to its root on its next visit.** `AppShell` marks them when
   `currentHouseholdIdProvider.value` moves between two non-null ids, and
   arriving on a marked tab uses `goBranch(initialLocation: true)`. The
   current tab is never reset: from the sheet it is already at its root,
   and from the Households list it stays on the list (D170).
4. **The sheet is the app's own sheet, not the canvas's.** It uses the theme
   fill (`surfaceContainerHigh`) and a `titleMedium` title, as Add meal
   does, over the mock's `surfaceContainerLow` / `titleLarge`. It writes
   nothing and returns a sealed `HouseholdSwitchPick`. Only the sheet's
   switch shows `Now in X.` with Undo (`persist: false`, D152); the list's
   does not (D170).

**Why.** A switch changes the data under every tab, so a pushed screen from
the old household must not survive it. go_router 18 has no public way to
reset a background branch, and calling `goBranch` over every branch at
switch time coalesces into one `go`. Resetting on arrival is the public
route. Matching the existing sheet keeps the app consistent where the web
mock is not.

**Rejected.**
- `core/widgets/`: the widgets know what a household is.
- Popping every branch at switch time: successive `router.go` calls in one
  frame coalesce.
- Resetting the current tab too: it would throw the Households list away
  under the user's finger.
- Gating the header on `currentHouseholdSummary`: it waits on the member
  query.

**Consequences.**
- A new tab root with a household-scoped title uses `HouseholdTabTitle` and
  sets `titleSpacing: AppSpacing.sm`.
- Anything inside `HouseholdTabTitle`'s `Material` must be given the bar's
  text style explicitly: a `Material` resets `DefaultTextStyle` to
  `bodyMedium`.
- A handler that needs the current id at tap time reads
  `currentHouseholdProvider`, not a possibly cold `currentHouseholdIdProvider`
  (as D170 found).

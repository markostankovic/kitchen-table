# Design round: multiple-households

Source: Claude Design handoff, 2026-10-13. Prompt: `PROMPT.md`. Bundle: `bundle/`.
Brief it answers: `docs/design/BRIEF_multiple_households.md`. This round is
Phase 9 slice C in `docs/ROADMAP.md` ("The multiple-households UI"). The
client side it sits on is slice B's `CurrentHousehold.switchTo` and
`myHouseholdsProvider` (D169).

The design is one canvas, `bundle/Kitchen Table Households.dc.html`, in six
sections D1–D6. Each phone mock is 360 wide, light and dark, sr and en
alternating, with "Porodica Stanković – vikendica" as the long-name case.
Direction **(b)** of D1 is accepted; (a) is shown only as the rejected
alternative.

The governing constraint, from the brief and repeated in the canvas: **with
one household none of this renders.** The only change a one-household user
sees is the "Another home?" section at the bottom of the Household screen
(D2·7). Every slice below must keep the one-household path pixel-identical
to today, and its walk must check it.

## Token delta

None. The bundle's `_ds/` (`_ds_bundle.js`, `styles.css`, every file in
`tokens/`) is byte-identical to round 2's. `tokens/fonts.css` is in this
bundle and was missing from round 2's copy, but it is web-only (§ Token map's
"no mapping" row). The canvas says so too: "no new tokens; everything uses
existing roles."

Every `var(--…)` the canvas uses is already in § Token map: `--card`,
`--elevation-3`, `--on-surface`, `--on-surface-variant`, `--outline`,
`--outline-variant`, `--primary`, `--scrim`, `--surface`,
`--surface-container-highest`, `--surface-container-low`, and the
`--type-*` / `--tracking-*` roles. Raw hex in the file (`#1F190F`, `#3A332A`,
`#E9E4DB`, …) is the canvas's own annotation chrome, not the phone mocks.

So there is **no tokens slice** in this round.

### Component-local numbers the planners will meet

Not tokens and not in § Token map, but literals in the mocks that a slice's
planner has to place: reuse an existing name, add an `AppSizes` entry in
that slice (with § Size and motion updated), or derive it. Listed so nobody
writes them raw into `presentation/`.

| Where | Value | Note |
|---|---|---|
| Tab header title block (D1·b, D3, D4) | 56 high, 8 horizontal padding, radius 12 | the tappable two-line block; title x stays at 16. Not `onboardingMark` (56), though the number matches |
| Its `expand_more` glyph | 18 | between `iconInMeta` (16) and `iconInButton` (20); no existing size |
| HouseholdRow gear divider (D2) | 1 × 32, `outlineVariant` | 32 is `AppSizes.tag`'s number, not its meaning |
| HouseholdRow divider inset (D2) | 56 from the left | radio column 24 + gutters |
| Switch loading bar (D3·2) | 4 high, `primary` on `surfaceContainerHighest` | M3 `LinearProgressIndicator` default height is 4 |
| Sheet's "Manage households" row (D3·1) | `500 16/24`, min height 56 | **not on the type scale**. Nearest roles: `bodyLarge` (400 18/28), `titleSmall` (600 14/20). Planner picks one; do not add a role |
| Sheet drag handle | 32 × 4, `outline`, radius 2 | M3's default bottom-sheet handle; the add-meal sheet already has one to match |

## Token map additions

None.

## Slices, in order

- [x] `phase9-household-list` (`31b685d`, D170) — Settings' household row and the new list of
      your households. Files: `lib/features/auth/presentation/settings_screen.dart`,
      `lib/features/households/presentation/household_screen.dart`, a new
      `lib/features/households/presentation/households_screen.dart` and a
      `HouseholdRow` widget (it is reused by the next slice's sheet, so the
      planner decides whether it sits in `households/presentation/widgets/`
      or `core/widgets/`), `lib/core/router/routes.dart`, the sr/en `.arb`
      files. Bundle: `Kitchen Table Households.dc.html` § D2 (`data-screen-label="D2 …"`).
      With 2+ households the Settings group label becomes "Households", the
      row shows the current name plus "2 members · 1 more household" and
      opens the list; the list's rows switch (radio, name, "N members ·
      Owner/Member", names wrap to two lines, fixed join order) and a gear
      behind a hairline opens that household's screen, current or not, so
      the Household screen becomes id-scoped here. *(Planning moved the
      list's Create/Join rows and the Household screen's "Another home?"
      section to slice 4: the create and join routes are onboarding-only
      until then, so they would be dead links. With one household this
      slice changes nothing.)*
- [x] `phase9-household-switcher` (`7dd0d1c`, D171) — the household line under the tab title,
      and the switch sheet. Files: `lib/features/recipes/presentation/recipe_list_screen.dart`,
      `lib/features/meal_plan/presentation/meal_plan_screen.dart`,
      `lib/features/shopping_list/presentation/shopping_list_screen.dart`
      (or one shared header widget they all use, planner's call),
      `lib/core/router/app_shell.dart` (popping to the tab root), the `.arb`
      files. Bundle: § D1 (b only) and § D3·1 and D3·3. With 2+ households the
      Recipes / Plan / List app bars get a `bodyMedium` second line with the
      name and ▾, one line, ellipsized; the 56 title block opens a sheet
      (`surfaceContainerLow`, radius 28, level 3, like Add meal) listing
      HouseholdRows without the gear, plus "Manage households" → the D2 list.
      Tapping a row switches, closes the sheet, pops to the current tab's
      root, and shows "Now in X." / „Sada ste u domaćinstvu „X“." with Undo
      (switches back).
- [x] `phase9-household-switch-loading` (`d95724b`, D172) — what a tab shows between the
      switch and its data. Files: the three tab screens above. Bundle:
      § D3·2. The header shows the new name at once; a 4dp primary linear
      progress bar sits under the header; content is flat placeholder bars in
      `surfaceContainerHighest` on cards, no shimmer; write controls disabled
      until loaded. Split from the switcher because it touches each tab's body
      rather than its header; if the planner finds the tabs already have a
      loading state this can collapse into a small slice or into the previous
      one.
- [x] `phase9-household-create-join-another` (`b955e3d`, D173) — in-app Create and Join.
      Files: `lib/features/households/presentation/create_household_screen.dart`,
      `join_household_screen.dart`, `onboarding_mark.dart` (it stops
      showing here), `lib/core/router/routes.dart`, the `.arb` files.
      Bundle: § D4, plus § D2's list-footer rows and § D2·7–8. Also adds,
      moved here from slice 1: "Create a new household" (`add`) and "Join
      with a code" (`key`) as rows below the list's card, and the Household
      screen's "Another home?" card ("Još jedan dom?", body, outlined
      `add_home` "Add a household" → the list), placed above the destructive
      hairline. That card is the one change one-household users see.
      Opened from the D2 list: an AppBar with ✕, no 56 mark,
      `headlineSmall` title 8 below the bar reading "Create another
      household" / "Napravite još jedno domaćinstvo" (wraps), body says the
      current household is untouched, the cross-link button is dropped.
      Landing: Recipes root in the new household, snackbar "Now in X." with
      Invite (after create) or Undo (after join). Join with a code for a
      household you're already in is a quiet card panel ("You're already a
      member of X."), not red; the button becomes "Switch to X" or "Done".
      **Planner checks** what `redeem-invite` returns for an existing member
      since slice B dropped `already_in_household`.
- [ ] `phase9-household-leave-switch` — leave and delete when you have
      others. Files: `lib/features/households/presentation/household_screen.dart`
      (`_leave`, `_deleteHousehold`), possibly
      `lib/core/household/` for the next-household pick, the `.arb` files.
      Bundle: § D5. Dialog title names the household; body keeps today's
      consequences and ends with "You'll switch to X." in `onSurface`;
      owner sees "Delete household". No switch sentence when leaving a
      household you're not currently in, or your last one. After: Settings
      root in the next household, snackbar "You left X. Now in Y.", no Undo.
      Last household: today's path to onboarding. **Planner checks** "the
      one you used most recently among the others": slice B stores only the
      current selection, so this may need a per-household last-used record in
      `DevicePreferences`, or a decision to fall back to join order.
- [ ] `phase9-import-save-to` — where an import is saved. Files:
      `lib/features/import/presentation/import_review_screen.dart` (its
      `AppActionBar` footer), the import application/data path that saves,
      the `.arb` files. Bundle: § D6. With 2+ households one `bodyMedium`
      line inside the existing hairline footer above the buttons: `home`
      icon, "Saves to **X**", text button "Change", which opens the D3 sheet
      titled "Save to" — it picks the target for this import only and does
      not switch. Snackbar "Saved to X." With one household the footer is
      unchanged. Last because it reuses the switcher's sheet and touches the
      save path (slice A's explicit `householdId` makes it possible). This is
      the share-from-browser entry, so the walk needs a real share intent.

Order rationale: the list comes first because it introduces `HouseholdRow`
and is the "Manage households" destination the sheet links to. Nothing in
the app can create a second membership before slice 4, so seed one by hand
on hosted for walks 1–3.

## Out of scope

- **D1 (a), "Settings only"** — shown as the rejected direction.
- **The canvas chrome** — the status bar mock (`9:41`, signal icons), the
  section prose, the `#E9E4DB` canvas, annotation hex, `.kt-state` — web
  presentation of the canvas, not the app.
- **A colour per household** — D6 rules it out explicitly; nothing to build.
- **A household name on recipe detail, settings rows or the copied list** —
  D6 rules it out.
- No new package is needed. Nothing here contradicts a Hard rule in
  `CLAUDE.md`; the D5 "last used" pick and the D6 "save to another
  household" are data-layer questions for their slice planners, not design
  scope.

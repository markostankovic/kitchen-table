# D146 — The household's destructive slot is a text button; member rows and secondary lines take Settings' pair
**Status:** active
**Touches:** lib/features/households/presentation/household_screen.dart, test/features/households/household_screen_test.dart, docs/DESIGN_SYSTEM.md

**Decided.** For frames 21–22 of round `sync-design-initial` (2026-10-05):
1. **The bottom Leave/Delete slot is a destructive `TextButton.icon`**:
   `xl`, a hairline, `sm`, then the button, left-aligned behind an `xs`
   start inset (the icon lands at 20dp). Leave uses `logout` and Delete
   uses `delete_forever_outlined`. The gating is unchanged: one renders, or
   none while the role is unknown (D115, D126 #3).
2. **Member rows use Settings' name/role pair**: the name is `titleMedium`
   `onSurface` and the role is `bodyMedium` `onSurfaceVariant`. Both are
   set on each `ListTile`, not in `listTileTheme`.
3. **The member count and the invite expiry are `bodyMedium`
   `onSurfaceVariant`** (were `bodySmall`), following D145 #4. The header
   sits `sm` under the app bar, as on Settings.

**Why.**
- § Buttons already listed Leave household as a destructive text button.
  The `ListTile` was the odd one out, and a button reads as an action, not
  a row of the members list above it.
- Settings and Household are one family. Settings' household row shows the
  same `2 člana` that heads this screen, so the two should match.
- Setting the styles per tile keeps the change on this screen.
  `listTileTheme` is shared with other screens.

**Rejected** (seen in the frame, not adopted):
- **The invite code in a 28/36 w500 monospace with 4px tracking.** The
  code keeps the join field's exact style (`titleLarge`, `sm` tracking,
  tabular figures), so a code reads the same where it is shown and where it
  is typed. A monospace face would also be a new font.
- **The 2px code → expiry gap, the card's 12 bottom padding, the 28px
  gap above section headings and the 12px under the Invite heading.**
  These are off the scale, or `AppSectionHeading` and the card theme
  already fix them.
- **The 16/24 secondary-line size.** It is not a type role (as in D145).
- **The 48dp avatar and the green (`primary`) owner avatar.** D126 #2:
  avatars are 40dp mustard circles, and the owner is not colour-coded.
- **A `⋮` on the caller's own row.** D115 / D126 #3: only the owner sees a
  `⋮`, and only on someone else's row.

**Consequences.** Frame 22's dialog already matched (D126 #4) and is
unchanged. `TextButton.icon` builds a private `TextButton` subclass, so
tests find it with `find.bySubtype<TextButton>()`, not `widgetWithText`.
Amends neither D126 nor D145.

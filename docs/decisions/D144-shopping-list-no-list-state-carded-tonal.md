# D144 — The shopping list's no-list state is carded, with the basket glyph and one tonal action
**Status:** active
**Touches:** lib/features/shopping_list/presentation/shopping_list_screen.dart, docs/DESIGN_SYSTEM.md

**Decided.** For frames 18–19 of round `sync-design-initial` (2026-10-05):
1. **The no-list state is `AppEmptyState(card: true)`** (D138) under the
   range bar, inside the `RefreshIndicator`.
2. **Its icon is `shopping_basket_outlined`**, the frame's
   `shopping_basket` in the app's `_outlined` style.
3. **Its one action is a text-only `FilledButton.tonal`** `Napravi listu` /
   `Generate list`, with no leading icon, as on the recipe list.
4. It is chrome, in the reader's locale (D94). The strings are unchanged.

Nothing else in the two frames was adopted.

**Why.**
- An empty state is an invitation. A full-emphasis button on a screen with
  nothing else on it shouts, and § Empty state allows one tonal action.
- The card makes the empty region read as part of the screen, and the recipe
  list already does it this way (D138).
- `checklist` was the old nav glyph (D118). The basket names the screen.

**Rejected** (seen in the frames, not adopted):
- **Aisle headings in the to-buy card.** D105-amended.
- **The offline banner inside the scroll body**, at 16/24 with a 24dp icon,
  and its merged sentence replacing the saved-copy line. D76: the banner
  lives in `AppShell` above every tab, and both lines stay. Restyling it is
  not a one-screen call.
- **`bodyMedium` for the generated-at and `Next list:` lines.** § Shopping
  list sets `bodySmall` captions, and part 2's three-line Serbian wrap is
  why the range line is small and on its own line.
- **The doc-language tag's bold code** (D134), 28dp height and 6px gap. The
  height and gap are within a couple of dp of the shipped padding.
- **The staples card's 15px title and `bodyMedium` subtitle.** 15 is not a
  role.
- **The app-bar order (Regenerate, then Copy) and its `refresh` /
  `content_copy` glyphs.** The order has no stated reason, and the glyphs
  belong to the round's out-of-scope icon-set question.
- **The frame's 12px above the empty card.** The card's `lg` inset plus the
  range bar's `sm` give 24. Matching it would need a padding parameter on
  `AppEmptyState`, which D138 kept minimal.
- **The to-buy card's `4 / 16 / 8` padding.** The frame's top 4 sits under
  headings that bring their own 16. Without headings, `sm` is right.

**Consequences.** The state shows only for a household that has never
generated a list: the screen shows the latest list whatever range is
selected. A device walk of it needs a fresh household.

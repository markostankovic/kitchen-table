# D158 — The open ingredient line is one box in `bodyLarge`, with a live preview; the match chip is gone
**Status:** active
**Touches:** lib/core/ingredients/widgets/ingredient_line_field.dart, lib/core/ingredients/widgets/ingredient_match_chip.dart (deleted), docs/DESIGN_SYSTEM.md

**Decided.** Round `2026-10-06-round-2-recipe-structure`, canvas § A4·2, 2026-10-07:
1. **The open line is `[grip] [box] [✕]`.** The box is
   `surfaceContainerHighest`, radius `sm`, padded `md`, with a 2dp `primary`
   border only while focused. The border is painted as a foreground and is
   always present (`BorderSide.none` when unfocused). A decoration that
   comes and goes changes the `Container`'s subtree and rebuilds the
   `TextField`, which re-ran autofocus.
2. **The typed text and hint are `bodyLarge`.** This is the one exception
   to § Inputs' `bodyMedium`, because the open line *is* the row being
   edited. The `TextField` is bare: `isCollapsed`, no fill, zero padding,
   no constraints, and `InputBorder.none` for all three borders.
   `InputDecoration.collapsed` alone let the theme's `focusedBorder` and
   52dp minimum through (the 2026-10-08 walk).
3. **The preview row replaces `IngredientMatchChip`.** It is `bodyMedium`
   `onSurfaceVariant`: `→ name · note · opciono · Nema poklapanja` on the
   left, and the amount on the right (`primary` w600 tabular number). The
   whole row is an `InkWell` that opens the picker ("choose another").
   Status words keep their spaces, and the space after each `·`,
   non-breaking. They never split across a line end (the walk: `No` /
   `match`).
4. **The field owns a controller and a focus node**, so Backspace can put
   the caret at the end of the line above. Only one line is open, so there
   is no per-row lifecycle.

**Why.**
- Going from an 18/28 row to a 14 field on tap made the line jump.
- One box with the parse under the text reads as the row being edited. The
  chip read as a separate control.

**Rejected.**
- Keeping `bodyMedium`.
- Keeping the chip next to the preview.
- `TextFormField(initialValue:)`, which cannot place the caret on reopen.

**Consequences.** `IngredientMatchChip` and its test are deleted, and its
three states now live in the preview and the pill (D160).

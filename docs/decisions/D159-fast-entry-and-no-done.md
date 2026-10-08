# D159 — Fast entry on the open line, and import review's Done is gone
**Status:** active — amends D123 #1 (`Done` closes a line)
**Touches:** lib/core/ingredients/widgets/ingredient_lines_editor.dart, lib/core/ingredients/widgets/ingredient_line_field.dart, lib/features/recipes/domain/recipe_draft.dart, lib/features/recipes/application/recipe_editor.dart, lib/features/import/application/import_confirm.dart

**Decided.** Round `2026-10-06-round-2-recipe-structure`, canvas § A4·2, 2026-10-07:
1. **The keyboard's Next** (`TextInputAction.next`, with an empty
   `onEditingComplete` so focus stays) on a non-blank line commits it and
   opens a blank line directly after it, in its `section`, with the
   keyboard still up. **Next on a blank line** closes and removes it, which
   ends a burst. Added `RecipeDraft.insertLineAfter(localId)`: pure, with a
   fresh id from `_nextLineId`, the section copied, and an append for an
   unknown id. It is exposed on `RecipeEditor` and `ImportConfirm`.
2. **Backspace on an empty line** (`FocusNode.onKeyEvent`) removes it and
   opens the line above with the caret at the end. It does nothing on the
   first line. This was verified with the Android soft keyboard's own key.
   It is **unverified on iOS**. The zero-width-space trick is rejected
   because it would leak into `raw_text`.
3. **No Done.** A line closes when another opens, on Next, or on ✕. **Any
   blank line that closes is removed, unless it is the only line.** A new
   recipe's lone blank line renders open but unfocused. Add ingredient
   opens and focuses the line it adds. Focusing a blank line the list
   rendered open, but never opened itself, adopts it (`onFocused`).

**Why.**
- Typing a list is the common case, and a burst should never need the
  screen.
- With Next and tap-elsewhere both closing a line, Done was a third way to
  do the same thing.

**Rejected.**
- Autofocus on screen load.
- A "Next ingredient" ghost row.
- The zero-width-space Backspace workaround.

**Consequences.** One rule ("blank lines that close go") covers Next on a
blank line, Backspace, and a blank line left behind. A keystroke and a tap
in the same frame can see a one-frame-stale list, which is harmless on a
device. The widget test pumps between them.

# D166 — Formatting is styled markup in place, no package; the toolbar replaces the save bar while a formattable field is typed in
**Status:** active
**Touches:** lib/core/text/rich_text_markup.dart, lib/core/text/rich_text_editing.dart, lib/core/widgets/rich_text_editing_controller.dart, lib/core/widgets/app_formatting_toolbar.dart, lib/features/recipes/presentation/recipe_edit_screen.dart, docs/DESIGN_SYSTEM.md

**Decided.** Round `2026-10-06-round-2-recipe-structure`, canvas § A3
(A3·2/A3·3), `phase8-rich-text-toolbar`, 2026-10-08. WYSIWYG was Marko's call
(2026-10-08):
1. **Styled markup, not WYSIWYG.** Storage stays exactly the D165 subset. A
   `RichTextEditingController.buildTextSpan` draws bold content w600, italic
   content italic, and every marker (`**`, `*`, `- `, `12. `) in
   `onSurfaceVariant`. Markers stay visible. No span changes size or letter
   spacing, and the composing underline is kept by splitting spans.
2. **Pure rules, thin Flutter side.** The editing logic is pure Dart on plain
   ints in `core/text/rich_text_editing.dart`. `rich_text_markup.dart`'s
   `scanRichInline` / `matchRichListMarker` keep one definition of each
   regex (`parseRichRuns` is built on the scan). The controller, the Enter
   formatter and the toolbar are the Flutter half.
3. **Bold and italic are mutually exclusive in the UI.** Each is disabled
   while the selection is inside the other, because D165 #3 has no nesting.
4. **Inline toggles work per line.** A selection that *overlaps* a same-style
   match unwraps it; otherwise the trimmed part is wrapped and stays
   selected. A caret in a word (Unicode letters and digits) wraps the word.
   A caret elsewhere inserts an empty pair that is removed if still empty
   when the caret leaves or focus goes.
5. **List toggles** work over the touched lines and swap kinds. Numbering
   continues from a numbered line directly above, else 1. Nothing else is
   renumbered (D165 #4).
6. **Enter** in an item continues it (`- ` or `n+1. `); Enter in an empty
   item drops the marker and ends the list.
7. **Where.** Only the editor's description, step text, note text and end
   note (never titles, tags, headings or ingredient lines, D165 #6). Each is
   a private `_FormattableField` (since D167, `AppFormattableField` in
   `core/widgets/`) that owns its controller and `FocusNode`.
   In a step row it is keyed by the row's local id, which amends the
   editor's "fields don't own controllers" note: the key carries the
   lifecycle, so there is no list bookkeeping. The toolbar shows when one
   of them has focus **and** the keyboard is up. The keyboard is read off
   `View.of(context)`, because the editor sits inside the shell's Scaffold,
   which removes the inset. While the toolbar shows, it takes the save
   bar's `bottomNavigationBar` slot, flush on the keyboard.
8. `AppFormattingToolbar` lives in `core/widgets/`. Import review's step and
   notes fields are the second consumer (adopted in D167).

**Why.**
- Rule 8, and a rich-text package (`flutter_quill`, `super_editor`,
  `appflowy_editor`) stores its own document format. Detail, translation
  and import all read markdown text.
- Pure functions make every rule a table test. The device-only part is
  placement.
- `MediaQuery` placement failed on the device (the walk), because the
  shell's Scaffold had already consumed the inset.

**Rejected.**
- A rich-text editor package (rule 8, and its own storage format).
- Hiding markers with zero-width or transparent spans: the caret walks over
  characters the cook can't see.
- Allowing bold inside italic: the parser would not render it.
- The plan's toolbar at the end of the Scaffold body, gated on
  `MediaQuery.viewInsetsOf`: it never shows inside the shell.
- Keeping the save bar over the toolbar: two bars stacked on the keyboard.

**Consequences.** The save bar is out of reach while a formattable field is
typed in: hide the keyboard or tap another field to save. Import review and
the translation review's editable fields stay raw until they adopt the
toolbar. A screen adopting it outside the shell gets the same placement,
because the bar pads by its own Scaffold's inset.

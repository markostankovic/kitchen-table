# D167 — The formattable field is shared, and import review adopts the toolbar in place of its action bar
**Status:** active
**Touches:** lib/core/widgets/app_formattable_field.dart, lib/core/text/rich_text_markup.dart, lib/features/import/presentation/import_review_screen.dart, lib/features/recipes/presentation/recipe_edit_screen.dart, docs/DESIGN_SYSTEM.md

**Decided.** `phase8-import-review-toolbar`, 2026-10-08. Amends D166 #7 and
#8, and closes D165 Consequences' Notes-subline item.
1. **Promoted.** The editor's private `_FormattableField` moves unchanged to
   `core/widgets/app_formattable_field.dart` as `AppFormattableField`, with
   the same API, the same controller-listener reporting and the same
   post-frame dispose. Import review is the second feature that needs it,
   which clears DESIGN_SYSTEM's § Where a component lives bar.
2. **Where, in review.** Import review's Method step and note rows and its
   Notes card are formattable. Heading rows stay a plain `TextFormField`
   (D165 #6). Steps gain `TextInputType.multiline`, matching the end note.
3. **Placement.** Review is inside the shell too, so it reads the keyboard
   off `View.of` and rebuilds on `didChangeMetrics`, as the editor does.
   While a formattable field has focus with the keyboard up, the toolbar
   replaces `AppActionBar` as the last child of the body Column. That Column
   already ends at the keyboard's top, so unlike the editor's
   `bottomNavigationBar` it takes **no inset padding**.
4. **Collapsing a card lets go of focus held inside it.** Method and Notes
   are `ExpansionTile`s with `maintainState: true`. A collapsed body is only
   `Offstage`, so a focused step kept focus and the toolbar stayed on the
   keyboard for a field nobody could see. `onExpansionChanged(false)`
   unfocuses the primary focus only when it is inside that card, so
   collapsing Method leaves a focused end note alone.
5. **`richPlainText(text)`** in `rich_text_markup.dart` strips each line's
   column-0 list marker and joins its `parseRichRuns` texts. It is built on
   the existing scan, so each regex still has one definition. Review's
   collapsed Notes subline is `richPlainText` with the whitespace collapsed,
   and it no longer shows raw `**`.

**Why.**
- A second copy of the field would be a second lifecycle (focus, notifier,
  the post-frame dispose) to keep in step with the first.
- Padding the review's bar by an inset would double-count it: the shell's
  Scaffold, or outside it the review's own, has already resized the body.
- #4 was planned as "note it or fix it". The widget test showed the
  toolbar stranded, so it was fixed in the slice.

**Rejected.**
- `maintainState: false` on the cards: collapsing would throw away the
  fields' controllers, and each re-expand would reseed them.
- Unfocusing on any collapse: that would take focus from a field in the
  other card.
- Stripping markers with a regex of its own for the subline: a second
  definition of the D165 rules (D166 #2).

**Consequences.** As in the editor, save and discard can't be reached while
the toolbar shows (D166 Consequences). The translation review is now the
only formatting surface still raw.

# D165 — The rich-text subset: one paragraph per line, no nesting, numbers as typed; parser in `core/text/`, `AppRichText` in `core/widgets/`
**Status:** active
**Touches:** lib/core/text/rich_text_markup.dart, lib/core/widgets/app_rich_text.dart, lib/features/recipes/presentation/recipe_detail_screen.dart, lib/features/recipes/presentation/translation_review_screen.dart, docs/DESIGN_SYSTEM.md

**Decided.** Round `2026-10-06-round-2-recipe-structure`, canvas § A3 (A3·1),
`phase8-rich-text-render`, 2026-10-08:
1. **The subset is `**bold**`, `*italic*`, `- ` bullets and `1. ` numbered
   items, and nothing else.** No `#`, links, code, `_`, `+`/`*` bullets or
   indented sub-lists. Leading whitespace means "not an item". Parsing is
   total: the worst case is literal markers in a plain run.
2. **Line semantics follow `bundle/RichText.dc.html`.** `\r\n`/`\r` become
   `\n`. Every non-blank, non-item line is its own paragraph, so a single
   `\n` and a blank line read the same (`md` apart). Blank lines emit
   nothing, end a list and collapse. Same-kind items join one list; a kind
   change starts another.
3. **Inline runs** are `\*\*(.+?)\*\*|\*(.+?)\*` left to right, **no nesting**
   (`**a *b* c**` is one bold run containing `*b*`). An unmatched marker
   stays literal.
4. **Numbers are kept as typed** (`3.` stays `3.`), never renumbered.
5. **Rendering.** Bold is w600 (D134 keeps w700 for a recipe's name); italic
   is `FontStyle.italic`; both keep the caller's colour, and the widget
   never picks a role. Markers are `onSurfaceVariant`: a 6dp disc inset `xs`
   in a 20 column, centred on the first line; numbers in tabular figures on
   the text's baseline. **A numbered list's column is `max(20, widest
   marker + xs)`**, measured once per list with a `TextPainter` in the style
   `Text` will draw, i.e. merged over `DefaultTextStyle` (its inherited
   letter spacing made the bare style measure short). `md` between blocks,
   `xs` between items, nothing outside.
6. **Where it applies:** detail's description, step text, step notes and
   end note; the translation review's originals for those (`rich: true`).
   Titles, headings and ingredient lines are never formatted. Editing stays
   raw text.
7. **Placement.** The parser is pure Dart in `core/text/` (beside
   `TextNormalizer`); `parseRichRuns` is public for the toolbar slice. The
   renderer is `AppRichText` in `core/widgets/`, though only `recipes` uses
   it — the `AppStatStrip` / `AppBadge` precedent for generic primitives.

**Why.**
- A hand-written ~100-line parser covers the subset without a package
  (CLAUDE.md rule 8), and copying the prototype's line rules keeps the
  device matching the canvas.
- Measuring the column per list keeps `10.` off its text without a
  `LayoutBuilder`, which throws under the steps' `IntrinsicHeight`.

**Rejected.**
- A markdown package (`flutter_markdown` etc.): far more syntax than the
  subset, and stray `#` in imported text would become headings.
- Keeping a single `\n` as a soft break inside one paragraph: it diverges
  from the prototype.
- A fixed 20 column for numbers: `10.` in `bodyLarge` is ~28 wide.
- Renumbering lists: the text is the household's; the marker says what
  they typed.

**Consequences.** Amends D155 #6: the end note body is `AppRichText`, not
plain `Text`. Text with a single `\n` that used to render as one paragraph
with a line break now renders as two paragraphs 12 apart. Import review's
Notes subline still shows raw `**`. Nothing server-side parses markup; the
translate call was seen to keep the markers.

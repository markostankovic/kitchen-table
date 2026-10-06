# Design round: round-2-recipe-structure

Source: Claude Design handoff, 2026-10-06. Prompt: `PROMPT.md`. Bundle: `bundle/`.
Brief it answers: `docs/design/BRIEF_recipe_notes_markdown_lists.md`.

The canvas is `bundle/Kitchen Table Design Fixes.dc.html`, with six sections:
A1 headings and notes, A2 end note, A3 formatting, A4 ingredients, B shopping
markers and C weekday names. Each section has a spec column and 360dp frames,
light and dark, switched with Tweaks. `bundle/RichText.dc.html` is the canvas's
formatting renderer, about 30 lines. It parses `**bold**`, `*italic*`, `- ` and
`1. ` and nothing else, so it doubles as the reference for the Dart renderer.

Fetched with the design MCP, read-only, from project
`4c9b3914-ad35-43f6-affc-e61d488c0fe5`:
- the canvas
- `RichText.dc.html`
- `_ds_bundle.js`, byte-identical to round 1's
- the DS `readme.md`, `styles.css` and `tokens/{colors,typography,spacing,elevation,base}.css`

The token files were checked against the fetched copies and are identical to
round 1's, so the copies on disk came from round 1's bundle. Not fetched:
`support.js` (the canvas runtime), `tokens/fonts.css`, the fonts and `assets/`.

## Token delta

None. Every colour (light and dark), type role, spacing step, radius, size and
duration in the DS token files is unchanged since round 1, and round 1 already
reconciled all of them. 0 new, 0 changed.

The canvas's own inline values all sit on existing tokens:
- the 4/8/12/16/24/32 spacing scale;
- radius 8 (note panel) and 12 (end-note card);
- 48dp bar and toggles, as `AppSizes.target`;
- 16dp ring and pin, as `AppSizes.iconInMeta`;
- the 2dp drop line, as `KitchenColors.dropTarget`;
- `secondaryContainer` for an active toggle;
- `titleSmall` in `primary` for headings.

There is no tokens slice. The canvas's A4 prose says the unmatched ring is
14dp, but its section B says 16. Keep 16, which DESIGN_SYSTEM.md § Ingredient
lines already explains.

## Token map additions

- `--size-tag` → `AppSizes.tag` (32). This is proposed, not added yet. A4's
  suggestion pill is the first thing in the app to draw at tag height, so the
  ingredient-editor slice adds the constant and replaces this map row's "none".

Private constants, not tokens:
- the list marker column (20) and the bullet disc (6) in the rich-text widget;
- the heading gaps: 32 above and 12 below in steps, 24 above and 4 below in ingredients.

## Slices, in order

Two slices change the schema or the Edge Functions (marked **/plan-slice**).
The rest are UI (`/plan-slice-ui`).

- [x] `phase8-weekday-full-names`: Meal plan. Files:
      `lib/core/l10n/date_labels.dart`,
      `lib/features/meal_plan/presentation/meal_plan_screen.dart`.
      Bundle: canvas § C. Day headers become `Ponedeljak 5` / `Monday 5` in
      `titleSmall`. The leftover meta stays abbreviated (`od pon 5`), so the
      full name is a new helper next to `weekdayAndDay`, not a change to it.
- [x] `phase8-shopping-row-markers`: Shopping list row, plus the shared
      `IngredientLineRow`. Files:
      `lib/core/ingredients/widgets/ingredient_line_row.dart`,
      `lib/features/shopping_list/presentation/shopping_list_screen.dart`.
      Bundle: canvas § B (B·1, B·3).
      - Extra unit families stack right-aligned in the amount column with a
        muted `+`, instead of sitting in the trailer. This changes the shared
        row, so recipe detail and import review change too.
      - A 16dp outlined `push_pin` in `outline` marks a pantry staple
        (list only).
      - The staples card subline becomes the long-press hint.
      - The unmatched trailer `Not added up · from <recipe>` needs the source
        recipe on a shopping item, which the domain doesn't carry today. The
        planner checks whether the list snapshot has it. If not, this slice
        drops the `from …` half and keeps `Not added up`.
- [ ] `phase8-shopping-long-press-menu`: Shopping list. Files:
      `shopping_list_screen.dart`, possibly
      `lib/features/shopping_list/application/`. Bundle: canvas § B (B·2).
      Long-press opens a two-item menu, `Move to Probably have` and
      `Always put here`, and the move confirms with Undo.
      **Behaviour, not just UI:** today a long-press always sets the permanent
      pantry preference (D147). A one-off "move this time" has no storage, and
      the list is a snapshot (D13). Open D13 and D147 first. If a one-off move
      needs a column, this becomes a `/plan-slice`. Or ask Marko whether only
      the `Always` item is wanted.
- [ ] `phase8-recipe-structure-data` (**/plan-slice**): schema, translation
      and import; no screens. Files: a new migration,
      `supabase/functions/_shared/{schema,translate}.ts`,
      `supabase/functions/translate-recipe/`, the `import-*` functions,
      `lib/features/recipes/{data,domain}/`. Bundle: none.
      - Add `recipe_steps.kind` (`step` | `heading` | `note`, default `step`).
      - Add `recipes.notes` and `recipe_translations.notes`.
      - Steps and notes go through the save RPC, the DTOs and the freezed
        models, the translate-recipe function (with `kind` passed through and
        `notes` translated) and the import Zod schemas (headings, notes, a
        "Tips" section). The Drift cache needs no new table.
      - Run `make types` and `dart analyze` after.
      - The translate prompt must also keep `**`, `*`, `- ` and `1. ` intact,
        with a Deno test. Do that here, so slices 7–8 only render.
- [ ] `phase8-step-headings-notes`: Recipe detail Steps and the editor's
      Steps. Files: `recipe_detail_screen.dart`, `recipe_edit_screen.dart`,
      `import_review_screen.dart` (the Method subline counts).
      Bundle: canvas § A1 (A1·1–A1·4).
      - A heading is `titleSmall` in `primary`, flush with the disc column,
        32 above it and 12 below. The connector breaks at a heading.
      - A note is `bodyMedium` `onSurfaceVariant` on a radius-8 panel, padded
        8/12, in the text column. The connector runs past it.
      - Step numbers continue across headings.
      - In the editor every row has a grip, a label row and an ✕. The add row
        offers Step (tonal), Heading and Note. Deleting a heading keeps its
        steps and shows `Heading removed.` with Undo. A dragged row lifts to
        level 3.
      - A recipe with no headings or notes must look exactly as it does today.
- [ ] `phase8-recipe-end-note`: Recipe detail, editor and import review.
      Files: `recipe_detail_screen.dart`, `recipe_edit_screen.dart`,
      `import_review_screen.dart`, `translation_review_screen.dart` (the note
      is translated text).
      Bundle: canvas § A2 (A2·1–A2·3).
      - On detail: 32 below the last step, a borderless `card`, radius 12,
        padded 16, an `edit_note` icon with `Napomena` / `Notes` in
        `titleMedium`, and the body in `bodyLarge`. It isn't rendered when
        empty.
      - In the editor: a growing multiline field under its own heading, with
        the helper text.
      - In import review: a collapsed card after Method, with the first words
        of the note or `None found`.
- [ ] `phase8-ingredient-sections`: ingredient section headings on recipe
      detail. Files: `recipe_detail_screen.dart`, maybe
      `lib/core/ingredients/widgets/`. Bundle: canvas § A4 (A4·3).
      `recipe_ingredients.section` is already stored and carried through
      import and save, but nothing shows it. The heading is `titleSmall` in
      `primary`, 24 above and 4 below.
- [ ] `phase8-ingredient-editor`: Recipe editor ingredients and import review
      lines. Files: `recipe_edit_screen.dart`,
      `lib/core/ingredients/widgets/ingredient_line_field.dart`,
      `import_review_screen.dart`, `lib/core/theme/app_sizes.dart` (`tag`).
      Bundle: canvas § A4 (A4·1, A4·2, A4·4).
      - Each line renders as the parsed `IngredientLineRow` plus a grip. Tap
        opens a single raw-text field with a live preview row under it.
      - Enter commits the line and opens the next one. Backspace on an empty
        line deletes it.
      - A suggestion is a 32dp mustard pill, `name?` with a check.
      - Sections can be added and dragged, and a section takes its lines with
        it.
      - The canvas gives the flagged row a "13 text inset". Every row is
        inset `md` (12) today. Keep `md` unless the frame shows a reason
        not to.
      - This is big. If the planner finds more than about 6 decisions, split
        it into editor and import review.
- [ ] `phase8-rich-text-render`: description, steps, step notes and end
      note, on detail and on the translation review. Files: a new
      `lib/core/widgets/` rich-text widget, `recipe_detail_screen.dart`.
      Bundle: canvas § A3 (A3·1), `bundle/RichText.dc.html`.
      - Bold is weight 600, not 700. Italic is true italic.
      - Bullets are a 6dp `onSurfaceVariant` disc in a 20 column. Numbered
        items use `onSurfaceVariant` with tabular figures.
      - 4 between list items, 12 between blocks, with hanging indents.
      - **No new package.** The subset is small enough for a hand-written
        parser like `RichText.dc.html`'s. Stray `#` in imported text just
        renders as text.
- [ ] `phase8-rich-text-toolbar`: formatting toolbar in the editor. Files:
      `recipe_edit_screen.dart`, a new `lib/core/widgets/` toolbar.
      Bundle: canvas § A3 (A3·2).
      - A 48dp bar on `surfaceContainer` with a hairline on top, shown only
        while a formattable field is focused.
      - Bold, italic, bullet and numbered toggles plus hide-keyboard. An
        active toggle gets the `secondaryContainer` pill.
      - Typing `- ` or `1. ` starts a list.
      - **Blocked on a decision (see Out of scope):** the canvas asks for
        WYSIWYG editing.

## Out of scope

- **WYSIWYG editing (A3).** The canvas says fields "show formatting as you
  type, so cooks never see `**`". A Flutter `TextField` can't hide markup
  characters. Real WYSIWYG means a rich-text editor package (`flutter_quill`,
  `super_editor`, `appflowy_editor`), and CLAUDE.md rule 8 says a new package
  needs asking first. It would also change what is stored, because those
  editors keep their own document format, not markdown text.
  - **Default for `phase8-rich-text-toolbar`, without a package:** a
    `TextEditingController` whose `buildTextSpan` styles bold and italic
    runs in place and dims the `**` / `*` markers. The toolbar inserts and
    removes markers.
  - Marko decides before that slice is planned.
- **The A2·3 import review frame draws Ingredients, Method and Notes as rows
  with `chevron_right`.** DESIGN_SYSTEM.md § Import review says Method
  expands in place, "no route, so no chevron", and A4·4 keeps ingredients
  inline. That frame is read as an abbreviated summary, not a navigation
  change. Notes gets a collapsed card like Method's (`expand_more`).
- **`Not added up · from <recipe>` (B)**, if the shopping item has no
  source-recipe data. Adding it would be a list-generation change, not a
  UI slice.
- **One-off "Move to Probably have" (B·2)**, if it needs storage. See that
  slice.
- The canvas's status bars, the `System keyboard` placeholder and the Tweaks
  panel are web-only frame chrome.

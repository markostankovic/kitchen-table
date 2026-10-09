# Brief for Claude Design: step headings and notes, recipe end note, light formatting, ingredient editing, shopping-list markers, weekday names (2026-10-06)

**Project:** Kitchen Table is a family recipe and meal-planning app (Flutter, Material 3, iOS and Android). It is Serbian-first and bilingual (sr/en), and uses Latin script only. The visual system is "Garden": green primary `#366A35`, mustard secondary, paprika tertiary (reserved for small signals), and warm cream surfaces (`#FFF7EC` light / `#16160F` dark). Please **update the existing design system and screens you made**. Don't start from scratch. Keep all current tokens unless a change below needs a new one, and name any new token you add.

Show every change in **light and dark**, at **360dp width**. Show Serbian and English wherever text length matters, because Serbian strings usually run longer.

Rules that hold everywhere:
- An ingredient line not linked to the catalog ("unmatched") is a supported outcome, not an error. It is **never red** and never styled as a fault.
- What the cook typed for an ingredient line is always shown. Structured data (amount, unit, catalog match) sits on top of it and never replaces it.
- Paprika is for small signals only (a marker bar), never for text or large fills.

---

## A. Recipe detail and recipe editor

### 1. Headings and notes between steps
Today the method is a flat numbered list: each step is a 28dp `todayContainer` disc with the number in `labelLarge`, then 16dp, then the text in `bodyLarge` 18/28 regular. Steps are 24dp apart, and a 2dp `stepConnector` timeline line joins the discs.

Add two new kinds of row that can sit **anywhere** among the steps:
- **Heading.** A short title that groups the steps after it, for example `Za testo` / `For the dough` or `Fil` / `Filling`. Typically 2–4 per recipe.
- **Note.** An un-numbered aside between two steps, for example `Ostavite testo da odstoji preko noći.` / `Let the dough rest overnight.` or a warning. It is one or two sentences, and it is not an action step.

Neither kind gets a number. Step numbers count real steps only, and **numbering continues across headings** (1–4 under "Za testo", 5–9 under "Fil"). Tell me if you think it should restart instead, and why.

Please design:
- How a heading and a note look on the **detail** screen, and how they relate to the timeline. Does the line run through or past a note? Does it break at a heading? It should still read as one sequence.
- How they look in the **editor**. Today each step field has a `Korak N` / `Step N` label above it, a drag grip (`drag_indicator`) on the left, and an "Add step" button at the end. Show how a cook adds a heading or a note: a split or menu on "Add step", or another option. Show that headings and notes drag-reorder like steps, and how a cook deletes one.
- Show the case of a recipe that starts with a heading, and a recipe with no headings at all, which must look exactly as it does today.

### 2. A recipe end note
Add one free-text field at the **end of the recipe**, after the steps: `Napomena` / `Notes`. It holds serving suggestions, finishing touches, storage, variations or Grandma's tip. It is optional and often empty, and when it is empty **nothing is shown** on the detail screen. Its length ranges from one line to a few short paragraphs.
- Design it on the detail screen so it reads as an afterword and not as another step. A quiet card or panel is fine, but don't use the translation panel's `docLanguage` ring, which means something else.
- Design it in the editor, after the steps.
- Show it in the import review too, where it sits after Method and is collapsed like Method.

### 3. Light text formatting
The description, step text, step notes and the end note may contain **light formatting**: **bold**, *italic*, bullet lists and numbered lists. Nothing else: no headings, links, images or tables. Titles and ingredient lines are never formatted.
- Show how each of these renders in `bodyLarge` on the detail screen, including a list inside a step next to the timeline, and a list inside the end note. Give the list indent, the bullet glyph and colour, and the spacing between items and paragraphs.
- **Editing.** Most cooks won't type `**`. Propose a small formatting toolbar (B, I, bullet list, numbered list) that appears above the keyboard while one of these fields is focused. Show it in both themes, with a selection made bold. If you think a toolbar is too much, say what you would do instead.

### 4. Ingredient editing and review
Today the editor's ingredient list is a column of single-line fields. Each one has a drag grip, the raw text the cook typed (for example `2 šolje brašna, prosejanog`), and an ✕ to remove it. Under it is a small match chip that shows the parse while the cook types: the amount, the unit and the catalog match, or `Nema poklapanja` / `No match`, or `{name}?` for a suggestion. It works, but it feels like a form and not like a recipe.

Please redesign how a cook **adds, edits, reorders and reviews** ingredient lines, in the editor and in the import review (where tap-to-open a read-only `IngredientLineRow` into this field already exists). The states the design must cover:
- **Parsed:** an amount, which may be a fraction (`½`) or a range (`2–3`), a unit, a name and a note (`sitno seckan`), and the `opciono` / `optional` flag.
- **Matched to the catalog**, matched with a **suggestion** the cook should confirm, and **unmatched** (dashed ring, not red).
- **Flagged** in import review: a 3px `reviewMarker` left edge on a `surfaceContainerLow` tint.
- **No amount** (`so po ukusu` / `salt to taste`).
- **Sections.** The data model already supports an ingredient section (`Za fil` / `For the filling`), but no screen shows it today. Design a section heading for the ingredient list on the detail screen and in the editor, consistent with the step headings in §1.
- Fast entry of many lines one after another (Enter → next line), deletion, and drag reorder.

Show an editor with about 8 lines across 2 sections, including one unmatched line, one suggestion, one optional line and one line with no amount. Show the same list in import review with one flagged row.

---

## B. Shopping list: item markers
Today each item is an `IngredientLineRow`: the name on the left, the amount on the right (number in `primary` w600 with the unit beside it), and a muted trailer under the name for extra units (`+ 200 g`) and unmatched raw lines. An unmatched item has a 16dp dashed ring after its name. Long-pressing an item moves it to or from **Verovatno imate** / **Probably have**, a collapsed card under the list, and nothing on screen hints that this is possible.

<!-- TODO(Marko): name exactly which markers bother you before sending. -->
Please redesign the markers on a shopping-list row so the states read at a glance in a shop:
- unmatched (dashed ring today),
- an item with more than one unit family (`1 kg + 2 kom`),
- an item the household marked as a pantry staple, and a way to discover the long-press (or propose a visible alternative to it).

This row is shared with recipe detail and import review. Say whether your changes apply there too, or only to the list. Don't add a check-off/bought state; that's a separate feature.

## C. Meal plan: full weekday names
Day headers in the plan currently show the abbreviated weekday and the day number (`pon 6` / `Mon 6`). Show the **full weekday** (`Ponedeljak 6` / `Monday 6`) in the week view and the Today view. The longest Serbian name is `Ponedeljak`, and `Četvrtak` and `Subota` are close behind. Check that the full names fit at 360dp next to whatever else sits on the header row. The leftover chip (`od pon 6`) stays **abbreviated**, because Serbian would have to decline the full name after `od`.

---

**Deliverables overall:** an updated `design-system.pdf` that covers the step heading, step note, end note, formatting styles and toolbar, ingredient section heading, ingredient field states and shopping-row markers, with any new tokens named. Also updated **Recipe detail**, **Recipe editor**, **Review import**, **Shopping list** and **Plan — week** screen references, in light and dark, sr and en.

# D151 — Shopping row markers: stacked amounts and a name-marker slot in the shared row; markers travel with the last word
**Status:** active
**Touches:** lib/core/ingredients/widgets/ingredient_line_row.dart, lib/features/shopping_list/presentation/shopping_list_screen.dart, lib/core/l10n/arb/app_sr.arb, lib/core/l10n/arb/app_en.arb, test/core/ingredients/ingredient_line_row_test.dart, test/features/shopping_list/shopping_list_screen_test.dart, docs/DESIGN_SYSTEM.md

**Decided.** Round `2026-10-06-round-2-recipe-structure`, canvas § B (B·1, B·3), 2026-10-06:
1. **Further unit families stack in the shared row.** `IngredientLineRow`
   takes `extraAmounts` (primitives, D127/D53). Each one is a `bodyLarge`
   line under the first amount, right-aligned, led by `+ `. The `+` is
   `onSurfaceVariant`, not the canvas's `outline`: `outline` is never body
   text. Only the shopping list passes any.
2. **A generic `nameMarker` slot**, inline after the name and optional label,
   `xs` before it, in a fixed 16dp (`iconInMeta`) box. The row gives it no
   meaning. The shopping list passes a `push_pin_outlined` in `outline`
   (tooltip `Uvek u Verovatno imate`), drawn from `item.isPantryStaple`, not
   from which card the row is in.
3. **A marker always travels with the last word.** The row measures the
   name's last line with a `TextPainter`. If the markers (`xs`+16 for the slot,
   `sm`+16 for the unmatched ring) won't fit after it, it turns the last
   space into `\n`. The optional label's last space comes first when there is
   a label.
4. **`Not added up` / `Nije sabrano`** leads an unmatched item's trailer
   **only when it has no amount**. It is chrome (reader's locale).
5. **The Probably-have subline is the long-press hint**: `…premestite ovde.`
   collapsed, `…vratite na listu.` expanded. It is chrome; the heading stays
   in `list.locale`. `cupboardStaplesSubtitle` is gone.

**Why.**
- D9 keeps families apart. Their amounts belong in the amount column, not
  hidden in the trailer under the name.
- The pin is drawn from the flag so that the next slice's one-off move
  ("moved there once, no pin") gets the distinction for free.
- The U+2060 word joiner alone did not hold on the device. The 2026-10-06
  walk saw the ring alone on a fourth line: Flutter breaks before a
  placeholder that overflows anyway. The ring has had this bug since it was
  added; the pin copied it.
- Beside an amount (`1.67 kom`), "not added up" read as a contradiction. It
  exists to say why there is *no* amount.
- The hint and `Not added up` speak to the reader, like the ring's tooltip
  and the snackbars (D94).

**Rejected.**
- **`from <recipe>` in the trailer** (canvas). `ShoppingItem` has no source
  recipe; adding one is a list-generation change.
- **The `+` in `outline`.** Rejected on the rule above.
- **The last word and the marker in one `WidgetSpan`.** It splits the name's
  text, so finders and semantics lose the whole name.
- **An `isStaple` flag on the row.** The row stays model-agnostic (D127).

**Consequences.** Every-row pin means it distinguishes nothing until a
one-off move exists (`phase8-shopping-long-press-menu`). A caller's marker
must fit 16dp. On a line that needs it, the name's plain text holds a `\n`
in place of its last space, so an exact `find.text(name)` misses that row.

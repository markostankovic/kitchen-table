# D160 — The suggestion pill confirms directly; closed rows search only when unmatched and never auto-accept; `AppSizes.tag`
**Status:** active
**Touches:** lib/core/ingredients/widgets/ingredient_suggestion_pill.dart, lib/core/ingredients/widgets/ingredient_line_field.dart, lib/core/ingredients/widgets/ingredient_lines_editor.dart, lib/core/theme/app_sizes.dart, lib/core/l10n/arb/app_sr.arb, docs/DESIGN_SYSTEM.md

**Decided.** Round `2026-10-06-round-2-recipe-structure`, canvas § A4·1, 2026-10-07:
1. **The pill** sits under any unmatched, non-blank line, closed or open,
   whenever the search has a candidate. On a closed row it goes above the
   divider. It is a 32dp (`AppSizes.tag`, new) stadium in
   `secondaryContainer`: a `check` (18), then `{name}?` in `labelLarge`
   `onSecondaryContainer`, with a 48dp hit area. Beside it, `Dodirni za
   potvrdu` / `Tap to confirm` (new key `ingredientSuggestionConfirmHint`)
   sits in a `Wrap`.
2. **Tapping the pill confirms**, with no picker: `manual`, confidence 1,
   then the alias write-back (D7, D8). The pill and the picker's
   `ChooseExisting` share one function, `confirmIngredientMatch`.
3. **A closed row searches only when it is unmatched.** It searches once,
   with no debounce, using `ingredientSearchName` (the parse's name, or the
   whole line). An opened unmatched line starts its `_query` from the same
   search, so the pill survives the open. **A closed row never
   auto-accepts.** Only typing in the open line can.
4. **Auto-accept applies only to the line as it is now.** The controller's
   text must equal the line's `rawText`, and its parsed name must equal the
   query. A search that went out during a typing pause can land after more
   was typed. Without this check it matched the wrong word, and it could
   write the older text back over newer keystrokes (the 2026-10-08 walk:
   `secera` onto `secerazzz brasnaa`). This was pre-existing, carried over
   unchanged from the old field.

**Why.**
- A one-tap confirm is the fast path that D8 wants.
- Opening a saved recipe must not change a line nobody touched.
- Searching a matched line is wasted work.

**Rejected.**
- The pill opening the picker (the old chip did that).
- Closed rows auto-accepting.
- An `ActionChip` fighting the chip theme's 8dp radius and 40dp height.

**Consequences.** Confirming a pill on a typo teaches the catalog the typo,
globally. The walk left `seceraa → šećer` on hosted this way.

# D122 — The shopping list's component vocabulary: a derived range bar, an always-on doc-language tag, one headingless document card, and a hairline on every row
**Status:** active
**Touches:** lib/features/shopping_list/presentation/shopping_list_screen.dart, lib/features/shopping_list/domain/format_item_quantity.dart, lib/core/ingredients/widgets/ingredient_line_row.dart, docs/DESIGN_SYSTEM.md

**Decided.** Phase 7 Part 5 builds the shopping list out of a range bar, a
doc-language tag and two theme `Card`s. The range bar and the tag are
private classes in `shopping_list_screen.dart`, and nothing goes into
`core/widgets/`, because each has one consumer. Six calls:

1. **The segment selection is derived, never stored.** A range equal to
   this week or next selects that segment, and anything else selects
   `Datumi`. `emptySelectionAllowed` turns a re-tap on the selected `Datumi`
   into a second picker. **The segments carry no selected check.**
2. **The range line shows only when it differs**, meaning there is no list,
   or the selected range is not the list's own. It never shares the
   segments' row.
3. **The doc-language tag is always shown.** Its code comes from
   `list.locale`, and its sentence is in the reader's locale (chrome about
   the document, D94).
4. **The Garden mock's category headings are declined** in favour of
   D105-amended. Blocks stay ordered by `groupByCategory` and sit `md` apart.
5. **Every to-buy row keeps its hairline except the card's last.**
6. **Item rows split quantities.** The first quantity goes in
   `IngredientLineRow`'s column with its unit beside the name. Further
   families (D9) and unmatched raw lines go in the trailer.
   `formatItemQuantityParts` supplies the halves, and `formatItemQuantity`
   is built on it.

**Why.** A stored selection can disagree with the range the next list will
cover, and a derived one cannot. Beside the buttons, the range wrapped to
three lines in Serbian (part 2's walk). Under them, it is only worth a line
when it tells the reader something the list does not. Part 1's walk
reported "untranslated strings" that were a list generated in English,
rendering in English as designed (D94). The split was invisible, so the tag
makes it legible. Shown only on a mismatch, it would read as a warning.
Headings were removed as noise when scanning a list in a shop, and a mock
does not overrule that. The last two calls were settled on the device. The
selected check pushed `Ova nedelja` / `This week` onto two lines in both
languages at ~109dp a segment, and the fill already marks the selection.
Dropping the hairline at each block's end left, on a real list where most
categories hold one item, a single arbitrary hairline, and the gaps read as
uneven spacing rather than grouping.

**Rejected.** Moving the document's strings to the reader's locale to
"translate" them, which would break D94. A shorter `Ova nedelja` label, or
narrower segment padding, instead of dropping the check. No hairlines at all
in the document card, which would make a long list harder to track across.
Headings in the clipboard text. Promoting the tag or the range bar to
`core/widgets/`, since each has one consumer. The mock's decimal comma
(`1,5`), which is out of scope and in `docs/IDEAS.md`.

**Consequences.** `IngredientLineRow.showDivider` means "last row of a
card", not "last row of a block". A future card of rows that wants a group
break should use a gap, not a missing hairline. The segment wrap cannot be
caught by a widget test (the test font wraps at any width), so the test pins
`showSelectedIcon: false` itself.

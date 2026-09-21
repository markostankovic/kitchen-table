# D105 — The exported list shares one grouping definition with the screen, and renders in the document's own locale
**Status:** active
**Touches:** lib/features/shopping_list/presentation/shopping_list_text.dart, lib/features/shopping_list/presentation/shopping_list_screen.dart, test/features/shopping_list/shopping_list_screen_test.dart

**Decided.** `_ListBody`'s private `_uncategorisedCategory`,
`_categoryLabel`, `_CategoryGroup` and `_byCategory` move, unrenamed in
behaviour, into a new plain library,
`shopping_list_text.dart` (`uncategorisedCategory`, `categoryLabel`,
`CategoryGroup`, `groupByCategory`), and the screen imports them back
rather than keeping its own copy. `formatShoppingListAsText(list, units,
l10n)` is built on top of that same `groupByCategory`, so the on-screen
category order and the clipboard text's category order cannot drift apart
-- they are structurally the same call. The library sits in
`presentation/`, not `domain/`: it imports the generated
`AppLocalizations`, which imports Flutter, and rule 7 keeps `domain/` pure
Dart (`format_item_quantity.dart` stays in `domain/` precisely because it
never touches ARB, only a `locale` string). The exported text is built
from `lookupAppLocalizations(Locale(list.locale))`, the same as
`_ListBody`'s own `bodyL10n` -- the export is the document, not the chrome,
so it follows D94/D86's existing split rather than the reader's ambient
locale via `AppLocalizations.of(context)`.

**Why.** D94 already drew the line between the document (`list.locale`)
and the chrome (the reader's locale) for this exact screen; the clipboard
text has no chrome at all, so treating it as anything other than more
document would reintroduce the half-translated-list bug D94 exists to
prevent. Sharing `groupByCategory` rather than writing a second grouping
function for the exported text is the same instinct as CLAUDE.md rule 6
(one definition, verified once), even though both sides are Dart here, not
a language boundary: two copies of a sort rule are two chances for the
screen and the export to disagree about where an item lands.

**Rejected.** Keeping `_byCategory` private to the screen and writing a
second, `domain/`-resident grouping function that takes a
`category-code -> label` callback instead of `AppLocalizations` directly
-- adds a layer of indirection for no reader, since the only caller of
either grouping function is presentation code that already has an
`AppLocalizations` in hand.

**Consequences.** An item whose every contributing line produced no
quantity (`unmatchedLines`, migration 4's "not a quantity" -- `po ukusu`,
`prstohvat`) pastes as a bare name with no amount; accepted, not a bug.
Pantry staples (`list.probablyHave`) and the generated-for-range header are
never in the exported text -- a bare to-buy list is the whole ask, a share
sheet and a fuller export are a later conversation. Separately: this
slice's own widget test discovered that this Flutter SDK's `flutter_test`
does **not** stub the clipboard's `flutter/platform` channel by default --
an unmocked call to `Clipboard.setData` hangs indefinitely instead of
throwing, rather than the in-memory clipboard the original slice plan
assumed. `shopping_list_screen_test.dart` now registers a minimal mock
handler for `SystemChannels.platform` in `setUp`/`tearDown` to unblock the
SnackBar assertion; the exported text's own content is verified directly,
and more thoroughly, by `shopping_list_text_test.dart` instead of via
`Clipboard.getData` (which hangs the same way when called from a test
body).

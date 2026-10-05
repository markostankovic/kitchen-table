# D147 — Pull and a pantry long-press both regenerate the shopping list
**Status:** active
**Touches:** lib/features/shopping_list/application/shopping_list_providers.dart, lib/features/shopping_list/presentation/shopping_list_screen.dart, lib/core/l10n/arb/app_en.arb, lib/core/l10n/arb/app_sr.arb

**Decided.** Phase 8 part 1, user's call 2026-10-05:
1. **Pull-to-refresh means generate**, the same `generate()` and failure
   snackbar as the app-bar button: the range bar's dates, the reader's
   locale (D81). On the empty no-list state too, where it does what that
   state's own button does.
2. **A pantry long-press saves the preference and then regenerates the list
   on screen** (`regenerateCurrent()`), with the list's **own** `dateFrom` /
   `dateTo` and `locale`, not the range bar's selection or the reader's
   language. The item moves in or out of "Probably have" at once. The
   success snackbar shows only if both steps succeed; if the preference
   saved and the regeneration failed, the failure snackbar alone is enough,
   because the preference applies on the next generation anyway.
3. **The list stays on screen while it reloads** (`skipLoadingOnReload:
   true` on the screen's `when`), so a regeneration keeps the cook's scroll
   position and the expanded staples section.

Amends the Phase 3 part 6 stance in `_togglePantry` and `setPantryPref`
("deliberately does not rewrite the list on screen"). **D13 stands**: each
regeneration is a new snapshot (save, then soft-delete the previous one),
with no per-item state and no offline write.

**Why.**
- A pull that re-read the stored snapshot and a button that regenerated
  were two gestures for one screen that disagreed.
- "Takes effect next time you generate" made the cook do the second step
  every time. Doing it for them is what the long-press was for.
- Its own range and locale: the cook asked to move one item. Swapping the
  week to whatever the range bar now shows, or translating the document
  into the chrome's language (D94), would be a different action.
- The device walk found a long-press blanking the list and returning it
  scrolled to the top, which on a long list loses the cook's place every
  time.

**Rejected.**
- **Pull keeps re-reading the snapshot.** It was the disagreement this part
  removes.
- **The long-press regenerates with the range bar and reader's locale**,
  i.e. calls `generate()`. It silently changes the week or the language.
- **Patching the on-screen snapshot in place** (moving the one item). It
  would be per-item state on a snapshot, which D13 rules out, and a second
  aggregation path.

**Consequences.** Every long-press is a network write plus a full
regeneration, so offline it fails at once with `No connection.` and nothing
moves. Both snackbars changed value, with their keys kept
(`markedAsStapleSnackbar`, `willBeOnListSnackbar`). The sr wording uses a
neuter participle (`premešteno`) whatever the noun's gender, as the old
string did.

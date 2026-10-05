# D142 — Import review: an unmatched line names its state in the trailer, and the review's secondary lines are `bodyMedium`
**Status:** active — amends D123 (#3's unmatched line gains words; the summary and Method secondary lines change role)
**Touches:** lib/features/import/presentation/import_review_screen.dart, docs/DESIGN_SYSTEM.md

**Decided.** For frame 14 of round `sync-design-initial` (2026-10-05):
1. **An unmatched line's trailer leads with `Nije povezano sa sastojkom` /
   `Not matched to an ingredient`.** It reuses the ring's
   `ingredientNotMatchedTooltip` string (no new key), and is joined to the
   note with ` · ` the way a matched line's `→ <catalog name>` is. It is set
   in the row's muted `bodySmall` `onSurfaceVariant`. The ring and its
   tooltip stay. The line is still **not flagged**: no marker, no tint
   (D123 #3).
2. **The summary's attention line and Method's step count are `bodyMedium`**
   `onSurfaceVariant` (was `bodySmall`).

**Why.**
- Every closed row's second line should say what the matcher made of it.
  Before this an unmatched line explained itself only through a tooltip,
  which needs a long-press on a phone. The frame shows exactly this under
  `Vegeta, to taste`.
- Reusing the tooltip string keeps the ring and the words in step, with one
  translation to maintain.
- Secondary lines beside a `titleMedium` are `bodyMedium` across the app:
  D139's stat-strip labels and `AppSectionHeading`'s trailing text, and
  D138's result count.

**Rejected.**
- Flagging the unmatched line, as the frame does with `Vegeta`: D123 #3
  stands. An unmatched line is a supported outcome (rule 3), so it is never
  red or paprika.
- A separate, shorter string for the trailer: two strings for one state.
- The frame's row metrics (10dp padding, 16dp gap, `bodyMedium` trailer,
  12px / 1px ring): `IngredientLineRow` is shared with recipe detail and the
  shopping list (D127 / D129, part 17).
- A flag reason line: `needsAttention` is a bare `Set<int>` with no reason
  to show.

**Consequences.** An unmatched line added by hand on the review (Add
ingredient, no catalog pick) gets the same trailer, since it goes through the
same `_lineRow`.

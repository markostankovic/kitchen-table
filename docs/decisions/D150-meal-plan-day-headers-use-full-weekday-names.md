# D150 — Meal plan day headers use full weekday names; the compact form stays where a name is embedded
**Status:** active
**Touches:** lib/core/l10n/date_labels.dart, lib/features/meal_plan/presentation/meal_plan_screen.dart, test/core/l10n/date_labels_test.dart, test/features/meal_plan/meal_plan_screen_test.dart, docs/DESIGN_SYSTEM.md

**Decided.** Round `2026-10-06-round-2-recipe-structure`, canvas § C, 2026-10-06:
1. **The week view's day header is `weekdayNameAndDay`**: `Ponedeljak 5` /
   `Monday 5`.
2. **The Today view's header is `fullDateLabel`**: `Ponedeljak, 6. oktobar` /
   `Monday, October 6`. It is the full weekday **plus the month**, which is
   Marko's call against the canvas's C·3 (`Ponedeljak 5`).
3. **Both are sentence-cased** with intl's `toBeginningOfSentenceCase`, given
   the `_tag()`ed locale (D91).
4. **The compact `weekdayAndDay` is unchanged** and stays for the leftover
   meta (`od pon 5` / `from Mon 5`) and the move dialog's day dropdown. The
   leftover dialog keeps `shortDateLabel`.

**Why.**
- The header starts a card, and there is room for the full name. The canvas
  puts the worst collapsed row (`Četvrtak 8` + `Dodaj obrok`) at about 198
  of 308dp.
- A lone Today card has no week bar above it to name the month, the same
  argument the old `shortDateLabel` header made.
- A full Serbian weekday after `od` has to be declined (`od ponedeljka`), and
  a generated date string can't be, so the leftover meta stays abbreviated.
- intl gives Serbian weekdays in lower case. A header starts a line.

**Rejected.**
- **Changing `weekdayAndDay` itself.** It would break the leftover meta's
  grammar.
- **The canvas's bare `Ponedeljak 5` in the Today view.** It loses the month.
- **Full names in the move dialog's dropdown.** It is out of the round's
  scope.
- **The canvas's `Pustite ovde` / `Drop here` hint.** The app has never
  rendered one, and the dashed `primary` ring already says it.

**Consequences.** A new date label in a header or at the start of a line
wants the sentence-cased form. One embedded mid-sentence after a Serbian
preposition wants the abbreviated form.

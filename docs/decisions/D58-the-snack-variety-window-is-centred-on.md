## D58 — The snack variety window is centred on the candidate date, not trailing, and the warning never blocks a write

**Decided.** `snack_variety.dart`'s `varietyWindowAround` returns a window
`kVarietyWindowDays` (7) either side of the date being considered — 15
calendar days inclusive, close to `docs/DATA_MODEL.md`'s original "last 14
days" figure but centred rather than trailing. `shouldWarnOnRepeat` fires at
`kVarietyWarnAtOrAbove` (2) or more existing occurrences in that window. The
screen's warning dialog (Cancel / Add anyway) is advisory only — declining to
proceed after seeing it is the only way the check stops a write; the check
itself never does.

**Why.** `docs/DATA_MODEL.md`'s original sketch worded this as a trailing
window ending on the candidate date, written before the meal plan existed to
plan against. A meal plan is a forward-looking document: most of what a
candidate snack should be compared against has not been cooked yet, only
planned, and a trailing window only warns when slots happen to be filled in
calendar order — planning Saturday's snack before Wednesday's would get no
warning from a trailing window even though the two sit five days apart. A
centred window catches the repeat regardless of the order slots are filled
in, which is how meal planning actually happens. Advisory rather than
blocking follows D54's instinct for every meal-plan failure already: a
cook's plan is not something the app second-guesses past a single "are you
sure".

**Rejected.** A trailing window matching `docs/DATA_MODEL.md`'s original
wording literally — would depart from the app's actual usage pattern for the
reason above. Blocking the write outright — a warning that cannot be
overridden would make "plan the same snack twice on purpose" impossible, and
there is nothing wrong with that on occasion.

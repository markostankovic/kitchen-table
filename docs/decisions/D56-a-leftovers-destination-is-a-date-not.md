## D56 — A leftover's destination is a date, not a slot in the visible week

**Decided.** `MealPlanEditor.addLeftover` ignores the `week` its own `_write`
funnel would otherwise supply (the week on screen) and derives the
destination week from the leftover's `entryDate` instead:
`MealPlanRepository.addLeftoverEntry` calls `_ensurePlan` with
`PlanWeek.of(entryDate)`. The leftover dialog offers 14 consecutive dates
starting at the source entry's own date, crossing a week boundary freely.

**Why.** Sunday dinner's leftovers landing on Monday lunch is the single most
common leftover there is, and Monday sits in a different `meal_plans` row
than Sunday. Restricting the leftover dialog to the visible week's 7 days
(the same list `_showMoveDialog` already offers) cannot express that at all.
`ensure_meal_plan` already creates a week's row lazily on its first write
(D50); a leftover's write is just another caller of the same path, into
whichever week its date falls in.

**Consequence.** A leftover placed into next week is invisible on the grid
until the cook pages forward — the grid shows one week at a time by design
(D54), and this is not a bug, just a fact worth having named once rather than
rediscovered as a "missing" entry.

**Rejected.** Restricting the leftover dialog to the visible week's days —
cannot express the Sunday → Monday case, which is the main one.

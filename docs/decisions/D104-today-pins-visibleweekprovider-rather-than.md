# D104 — Today pins `visibleWeekProvider` rather than reading a week of its own
**Status:** active
**Touches:** lib/features/meal_plan/presentation/meal_plan_screen.dart, lib/features/meal_plan/application/meal_plan_providers.dart

**Decided.** The Plan tab's Today view does not add a second week provider.
Selecting Today calls `ref.read(visibleWeekProvider.notifier).today()` —
the same method the week view's own jump-to-today icon already used — and
then reads `mealPlanEditorProvider` exactly as the week view does, showing
one `_DaySection` for `DateTime.now()` instead of looping over
`plan.week.days`. Switching to Today is therefore destructive of wherever
the cook had paged the week view to: the invariant this buys is that Today
never renders a day outside `plan.week`, so a slot tap always writes into
the week the on-screen data actually came from.

**Why.** D54 already ruled `visibleWeekProvider` a single, non-family
notifier — keyed on `PlanWeek.of(DateTime.now())` would make it
clock-dependent to override in a test, and every write is meant to land in
the one week on screen, not some other week resolved from a hidden second
source of truth. Today and This week are one screen looking at the same
data two ways, not two independent data sources; giving Today its own
week-of-today value that could silently diverge from `visibleWeekProvider`
(e.g. after paging forward and switching back) would reintroduce exactly
the kind of second provider D54 ruled out, just moved into this screen.

**Rejected.** A `todayProvider` computed once and left alone regardless of
paging — reads naturally but breaks the moment `mealPlanEditorProvider`
disagrees with `visibleWeekProvider` about which week's data is on screen,
since a slot tap still writes via `visibleWeekProvider`. Making
`visibleWeekProvider` a family keyed by view — same clock-dependency
problem D54 already rejected once.

**Consequences.** Paging forward in This week and then tapping Today
snaps back to the real today, discarding the page position — deliberate,
not a bug to fix later. `test/features/meal_plan/meal_plan_screen_test.dart`
pins this down directly (`the pin: paging forward in week view then
switching back to Today...`).

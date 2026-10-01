# D121 — The meal plan's component vocabulary: collapsed empty days, a slot chooser, drag that carries the entry, and today outlined rather than filled
**Status:** active — amended by D135: a drag never changes an entry's slot; it reorders on an entry of the same day and slot, or moves to another day's card in its own slot
**Touches:** lib/features/meal_plan/presentation/meal_plan_screen.dart, lib/core/theme/kitchen_colors.dart, docs/DESIGN_SYSTEM.md

**Decided.** Phase 7 Part 4 builds the meal plan out of day cards with
nested entry cards. Every new widget is a private class in
`meal_plan_screen.dart`, and nothing goes into `core/widgets/`, because each
has a single consumer. Five calls inside that:

1. **Empty days collapse.** A Week-view day with no entries, other than
   today, is one compact card with `+ Dodaj obrok`. An expanded day shows a
   `+ <Slot>` button per *empty* slot plus a trailing `+`. Both `+ Dodaj
   obrok` and the trailing `+` open a **slot chooser**, a small bottom sheet
   of the four slots. The Today view never collapses.
2. **Drag carries the `MealPlanEntry`, not its id**, and there are three
   drop targets: a filled slot's group, a `+ <Slot>` button, and a collapsed
   day. A drop onto a collapsed day **keeps the entry's own slot**.
3. **Today is outlined, not filled.** Today's card has a 2dp border in
   `KitchenColors.today` and a `Danas`/`Today` pill. `todayContainer` now
   means only the step-number disc.
4. **A leftover names its source's day only when the source is in the loaded
   week**, found by `leftoverOfEntryId` in the `MealPlanWeek` the screen
   already holds, and only in the abbreviated `weekdayAndDay` form (`od pon
   14.`).
5. **The mock's "Already planned recently" line under an entry is not
   built.**

**Why.** Twenty-eight identical `Add` chips made an empty week read as a
form, not a plan. Collapsing leaves one action per empty day, and the
chooser recovers the choice of slot. The trailing `+` is not decoration: it
is the only path for a second entry in a filled slot, and several entries
per slot is supported. A collapsed day shows no slots to aim at, so a drop
there cannot pick one. Keeping the entry's slot is the only answer that is
not a guess, and it needs the entry itself, not an id. Filling today's card
would make a planned today and an empty today look different in a way that
means nothing, whereas an outline marks the day without competing with its
content. The source lookup needs no new query. A full Serbian weekday would
have to be declined after `od` (`od ponedeljka`), and a generated date string
cannot be declined. The app keeps no per-entry repeat flag, and D58's
snack-variety check is an advisory at add time, so a persistent line would
need new data.

**Rejected.** A `+ <Slot>` button for every slot, filled or not: it is the
old 28-button wall again. Omitting the trailing `+` when every slot is
filled: that would strand the second-entry path. Carrying the id and
defaulting a collapsed-day drop to breakfast: it silently changes a meal.
Fetching the leftover's source when it is outside the week: that is a new
query for a label. A full weekday name in `leftoverFromDay`. Photos or
monograms on entries: D53, since an entry carries a title, not a `Recipe`.
Promoting `_MealEntryCard` or the dashed painter to `core/`: each has one
consumer. A dashed-border package: CLAUDE.md rule 8. Flipping the toggle to
the mock's `This week | Today` order: Phase 5 chose to open on Today.

**Consequences.** `todayContainer` is now only the step-number disc, and a
screen that fills something with it to mean "today" contradicts this
decision. A meal-plan drop highlight shows up on the entry cards'
own fill, because a highlight drawn behind them would be hidden. Tests find
the `+` buttons with `find.bySubtype<TextButton>()`, because
`TextButton.icon` returns a private subclass.

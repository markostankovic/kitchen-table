# Slice: The meal plan's Today and This week views

## Goal

`MealPlanScreen` gains a two-segment `SegmentedButton` under the AppBar:
**Today** (the default) and **This week**. Today renders one `_DaySection` for
`DateTime.now()` — four slot rows, every existing interaction unchanged — with
the week bar's chevrons and the AppBar's jump-to-today action hidden, because
neither means anything when the view is pinned to one day. This week is
today's screen, untouched: `_WeekBar` plus seven day sections. Switching to
Today pins `visibleWeekProvider` to the current week so the day on screen is
always inside the week the data came from. No schema change, no migration, no
new package.

Both shape choices were settled in the planning session and are not open:
**Today is the default view** (Phase 5's intro names "the plan always opens on
a whole week" as one of the six frictions), and the control is a
**`SegmentedButton`**, the app's existing answer to "two views, one screen" —
there is no `TabBar`, `TabController` or `PageView` anywhere in `lib/`, and
this slice does not introduce one.

## Constraints already resolved (do not re-derive)

- **D54 — one visible week, a non-family provider, every write lands
  immediately.** `visibleWeekProvider` holds the single week on screen; it is
  deliberately not a family keyed on the week (a family keyed on
  `PlanWeek.of(DateTime.now())` would be clock-dependent to override in a
  test). Do not add a second week provider, and do not make it a family. The
  Today view reads the same `mealPlanEditorProvider` the week view does.
- **D53 — the meal plan reads recipes through `core/recipes/`, and tapping a
  slot is the primary tested way to add or move an entry.** The Today view
  reuses `_SlotRow` and `_EntryChip` as they are; no new write path, no second
  copy of the add/move/remove flow.
- **D56 — a leftover's destination is a date, not a slot in the visible
  week.** Unchanged here, but it is why `plan_week.dart` owns date arithmetic
  and why `shortDateLabel` exists: a date shown outside a week's context needs
  the month, not just the weekday.
- **D77 — the AppBar title shares `navPlan` with the bottom-nav label.** Leave
  the AppBar title alone.
- **D91 — never feed a bare `'sr'` to `DateFormat`.** All date rendering goes
  through `core/l10n/date_labels.dart`, which maps `sr` → `sr_Latn`. Never
  call `DateFormat` directly from the screen.
- **CLAUDE.md rule 7 — domain models are pure Dart.** The new same-day helper
  goes in `features/meal_plan/domain/plan_week.dart`: no Flutter import, no
  `intl`, and dates built with `DateTime(y, m, d + n)`, never
  `.add(Duration(days: n))` (that file's own header explains the DST reason).
- **CLAUDE.md rule 8 — a new package needs asking first.** Nothing new is
  needed; `SegmentedButton` is Material.
- **ARB house style:** `app_sr.arb` is the template and carries a
  `"@key": {"description": ...}` block for every key; `app_en.arb` carries the
  bare translations. `test/core/l10n/arb_parity_test.dart` fails if the two
  drift. New keys go in both, and `make gen` must run before `dart analyze`
  (`l10n-check` diffs the generated output against what is committed).

## Files to touch

- `lib/features/meal_plan/domain/plan_week.dart`
  Add a top-level `bool isSameDate(DateTime a, DateTime b)` comparing
  year/month/day. This file is already the feature's only home for date
  arithmetic, and its header says so.
- `lib/features/meal_plan/domain/meal_plan_week.dart`
  Replace `entriesFor`'s inline three-field day comparison with `isSameDate`.
  One definition, per the same instinct rule 6 applies across languages.
  Behaviour identical; existing tests must stay green untouched.
- `lib/features/meal_plan/presentation/meal_plan_screen.dart`
  The bulk of the slice:
  - `MealPlanScreen` becomes a `ConsumerStatefulWidget` holding
    `_PlanView _view = _PlanView.today` (a private enum,
    `enum _PlanView { today, week }`).
  - A `SegmentedButton<_PlanView>` between the AppBar and the body, in the
    same `Column` slot `_WeekBar` occupies today. Its `onSelectionChanged`
    does `setState(() => _view = selection.first)` and, for
    `_PlanView.today`, also `ref.read(visibleWeekProvider.notifier).today()`.
  - `_WeekBar` renders only in `_PlanView.week`. The AppBar's
    `Icons.today_outlined` action renders only in `_PlanView.week` too — in
    Today view it is a no-op button.
  - The `data:` branch builds either the seven `_DaySection`s (week) or a
    single `_DaySection(day: DateTime.now(), plan: plan, showFullDate: true)`
    (today). `_SavedCopyLine` stays first in the `ListView` in both, and the
    `RefreshIndicator` wraps both.
  - `_DaySection` gains `final bool showFullDate` (default `false`), choosing
    `shortDateLabel(day, l10n.localeName)` over `weekdayAndDay(...)` — the
    Today header has no week around it to disambiguate the month, the same
    argument `_showLeftoverDialog` already makes for its 14-day list.
  - `_DaySection._isToday` becomes `isSameDate(day, DateTime.now())`.
- `lib/core/l10n/arb/app_sr.arb` and `lib/core/l10n/arb/app_en.arb`
  Two new keys: `todayViewLabel` ("Danas" / "Today") and `weekViewLabel`
  ("Ova nedelja" / "This week"). Deliberately **not** a reuse of
  `thisWeekTooltip` or the shopping list's `thisWeekButton` — both carry
  `@`-descriptions naming the one widget they belong to, and this file
  already keeps per-widget keys apart on exactly that principle. Then
  `make gen`.
- `test/features/meal_plan/plan_week_test.dart`
  A case for `isSameDate`: same calendar day at different times of day is
  true; adjacent days false; same day-of-month in different months false.
- `test/features/meal_plan/meal_plan_screen_test.dart`
  `_pump` gains a `bool weekView = false` parameter; when true it taps
  `find.text('This week')` and settles before returning, so every existing
  grid test keeps asserting exactly what it asserts today. New cases:
  - Today is the default view: exactly one day header, four `Add` chips, no
    `Previous week` / `Next week` tooltip present.
  - The Today header renders `shortDateLabel(DateTime.now(), 'en')`.
  - Switching to This week shows seven headers and 28 `Add` chips, and the
    chevrons come back.
  - The pin: in week view tap `Next week`, switch back to Today, and assert
    the header is still `shortDateLabel(DateTime.now(), 'en')` — the
    invariant that Today never renders a day outside `plan.week`. (Note
    `_PinnedWeek` in this suite pins `build()` to the June 2026 week but
    leaves `next` / `previous` / `today` real, so this exercises the real
    notifier.)
  - The srLatn case gains a Today-view assertion, so D91 stays covered on the
    new header path.

## Pattern to follow

- **The control:** `lib/features/auth/presentation/settings_screen.dart:64`
  — `SegmentedButton<AppLocale>` wrapped in
  `Padding(padding: EdgeInsets.symmetric(horizontal: 16))`, `selected` as a
  single-element set, `onSelectionChanged` taking `selection.first`. Copy that
  shape exactly.
- **The screen's state:** `lib/features/recipes/presentation/recipe_list_screen.dart`
  — a `ConsumerStatefulWidget` whose ephemeral view state lives in plain
  fields updated with `setState` (`_tag`, `_favoritesOnly`). A chip/segment
  tap is discrete, so no debounce and no provider for the selection itself.
  Do the same here: `_view` is local state, not a Riverpod provider.
- **The day header:** `_showLeftoverDialog` in the same screen file already
  chooses `shortDateLabel` over `weekdayAndDay` when a date is shown outside
  one visible week. `showFullDate` is that same call, made for a header.

## Acceptance

- `make check` is clean apart from the **known pre-existing `seed-check`
  failure** from `c8be2bc` (a comment-only edit to
  `supabase/seeds/ingredients.csv`; `docs/STATE.md` records it as deliberately
  deferred). Everything else — `lint`, `test`, `test-functions`, `test-sql`,
  `l10n-check` — must pass. If `dart analyze` is not clean, the slice is not
  done.
- `make gen` has been run and the regenerated `lib/core/l10n/generated/` is
  committed alongside the ARB edits (`l10n-check` is what catches forgetting).
- Every existing test in `test/features/meal_plan/meal_plan_screen_test.dart`
  still asserts what it asserts today, reached through `weekView: true`.
- Device walk (`make install-hosted`, release build against hosted — not
  `flutter run`, not local Supabase): the Plan tab opens on Today showing the
  real current date; adding a recipe to a slot from Today lands in the right
  day; switching to This week shows the current week with today's header
  emphasised; paging forward then switching to Today returns to the real
  today. Record what was and was not walked — parts 2 and 3 both shipped with
  the device walk stopping short, and `docs/STATE.md` says so twice.
- While the app is on the device, close two loops STATE.md is still carrying,
  since both are one tap away from this screen: **(a)** part 3's add-to-plan
  flow (recipe detail → overflow → Add to meal plan… → a day next week → page
  the Plan tab forward and confirm the entry), and **(b)** part 2's filter row
  (add a tag to a recipe in the editor first, then tap to narrow the list).
  Neither is this slice's code — if either misbehaves, report it, do not
  widen the slice to fix it.

## To record on completion

`docs/journal/phase-5.md`, plus `docs/ROADMAP.md` Part 4 → complete with the
commit hash, and `docs/STATE.md`.

**A decision record is expected — one, not two.** Not for `SegmentedButton`
(that is the house style, not a departure), but for the Today/week pinning
rule: *the Today view pins `visibleWeekProvider` rather than reading a week of
its own*, i.e. how D54's single non-family week provider is made to serve two
views, and the invariant that falls out of it (Today never renders a day
outside `plan.week`; switching to Today is destructive of where the cook had
paged to, deliberately). That would be **D104**. If the build turns out not to
need the pin — it will — drop the record rather than writing a hollow one.

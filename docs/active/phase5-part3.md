# Slice: Add to meal plan from a recipe

## Goal

Today the only recipe→plan link runs one way: the Plan tab's slot row opens
`showRecipePicker` and finds a recipe. This slice is its mirror — you already
have the recipe open, you need a day and a slot. The recipe detail screen's
overflow menu gains **Add to meal plan...**, which opens a bottom sheet
offering four meal slots and the next 14 days; picking one writes a
`meal_plan_entries` row and confirms with a snackbar. The snack variety
warning (D58, advisory) fires here exactly as it does in the plan. No schema
change, no migration.

The layering wall is the mirror image too:
`features/recipes/presentation/` may not import
`features/meal_plan/application/` — `tool/check_layers.dart` fails any
cross-feature import that is not into `domain/`. That is why the recipe
picker lives in `lib/core/recipes/`, and it is why the day+slot sheet and the
write shim go in `lib/core/meal_plan/`. `lib/core/**` is outside the feature
rule entirely (`_featureOf` matches only `lib/features/<x>/<layer>/`).

Two things the roadmap entry did not account for, both settled in planning:

1. **`MealPlanEditor.addRecipe` writes into the *visible* week, not the
   chosen day's week.** Its `_write` funnel does
   `ref.read(visibleWeekProvider)` and hands that `PlanWeek` to
   `addRecipeEntry`, which is what `ensure_meal_plan` resolves the
   `meal_plans` row from, and the `meal_plan_entries_before_write` trigger
   (migration 14) *refuses* an `entry_date` outside it. From the recipe
   screen there is no meaningful visible week, so anything past whatever the
   Plan tab happens to be showing would be rejected.
2. **`mealPlanEditorProvider` is autoDispose.** Reading `.notifier` from a
   screen that does not watch it can see the notifier torn down mid-`await`,
   and its `build()` would fire a pointless `watchWeek` network fetch from
   the recipe tab.

So the slice adds a small keepAlive `MealPlanWriter` in `lib/core/meal_plan/`
over its own `MealPlanRepository`, deriving the destination week from the
chosen date. `MealPlanEditor` is not touched.

## Constraints already resolved (do not re-derive)

- **D53** — the meal plan reads recipes through `core/recipes/`, and an entry
  carries a title, not a `Recipe`. The precedent for a `core/` module that
  reaches into another feature's `data/` + `domain/` but never its
  `application/`.
- **D43 / D33** — one implementation in `core/`, not a copy per feature. Why
  `core/` exists as an escape hatch at all.
- **D56** — a leftover's destination is a date, not a slot in the visible
  week: `addLeftover` ignores `_write`'s week and uses `PlanWeek.of(entryDate)`,
  and its day list is 14 consecutive dates that may cross a week or month
  boundary. The new writer and the new sheet follow this exactly.
- **D50** — `ensure_meal_plan` creates a week's `meal_plans` row lazily on its
  first write, so writing into next week needs no extra step.
- **D58** — the snack variety window is centred on the candidate date (±7
  days) and warns at 2 or more prior occurrences, and the warning is
  **advisory**: Cancel / Add anyway, and the check never blocks a write on
  its own.
- **D54** — every meal-plan action writes immediately; there is no Save.
- **D12** — meal-plan writes are online-only; there is no local write path,
  and nothing to add here.
- **D92** — a domain enum may not know a sentence, so a label is a sibling
  `(value, AppLocalizations)` function, never a method on `MealSlot`.
- **D77** — `app_sr.arb` is the gen-l10n *template*. A key added only to
  `app_en.arb` is a build-time gap in English; add Serbian first, with its
  `@key.description` block.
- **CLAUDE.md rule 1** — no `supabase_flutter`, no `Map<String, dynamic>`, no
  `PostgrestException` outside `data/`. The new `core/meal_plan/` files must
  name none of them; `core/supabase/supabase_client.dart` hands over the
  client opaquely, exactly as `recipe_picker_providers.dart` does.
- **CLAUDE.md rule 7** — `MealSlot` and `PlanWeek` stay pure Dart.
- **CLAUDE.md rule 8** — no new packages. Everything needed is already here.
- `plan_week.dart`'s own rule — every date is built with
  `DateTime(y, m, d + n)`, never `.add(Duration(days: n))` (DST).
- **No migration in this slice**, so no `supabase db push` before the device
  walk (unlike Phase 5 part 1 — see `docs/STATE.md`).

## Files to touch

**New**

- `lib/core/meal_plan/meal_plan_writer.dart` (+ generated `.g.dart`)
  - `@Riverpod(keepAlive: true) MealPlanRepository mealPlanWriteSink(Ref ref)`
    — `MealPlanRepository(RemoteMealPlanDataSource(ref.watch(supabaseClientProvider)),
    LocalMealPlanDataSource(ref.watch(appDatabaseProvider)))`, the exact shape
    of `plannableRecipeSourceProvider`.
  - `@Riverpod(keepAlive: true) class MealPlanWriter extends _$MealPlanWriter`,
    `void build() {}`, two methods:
    - `Future<int> snackRepeatCount({required String recipeId, required DateTime entryDate})`
      — resolve the household (return `0` when there is none), then
      `countRecipeInSlot` over `varietyWindowAround(entryDate)` with
      `MealSlot.snack`. Copy `MealPlanEditor.snackRepeatCount`'s body.
    - `Future<void> addRecipe({required DateTime entryDate, required MealSlot slot, required String recipeId})`
      — resolve the household (throw
      `const NotFoundFailure(message: 'You are not in a household yet.', code: FailureCode.noHousehold)`
      when there is none, as `MealPlanEditor._write` does), call
      `addRecipeEntry(week: PlanWeek.of(entryDate), ...)`, then
      `ref.read(mealPlanRevisionProvider.notifier).bump()` so the Plan tab
      picks it up.
  - `keepAlive` on both is load-bearing, not decoration: the caller never
    watches them, and an autoDispose notifier can be torn down mid-`await`.
    Say that in the doc comment, alongside the D56 week rule.

- `lib/core/meal_plan/widgets/meal_slot_picker_sheet.dart`
  - `class MealSlotPick { const MealSlotPick(this.date, this.slot); final DateTime date; final MealSlot slot; }`
    — one value, not a sealed hierarchy: unlike `RecipePick` there is only
    one kind of decision here.
  - `Future<MealSlotPick?> showMealSlotPicker(BuildContext context)` →
    `showModalBottomSheet<MealSlotPick>(context:, isScrollControlled: true,
    showDragHandle: true, builder: ...)` — the same three flags
    `showRecipePicker` uses.
  - Private `_MealSlotPickerSheet`, a plain `StatefulWidget` (it reads no
    providers): a title row (`l10n.addToPlanSheetTitle`), then slot selection
    as a `Wrap` of `ChoiceChip`s over `MealSlot.ordered` defaulting to
    `MealSlot.dinner`, a `Divider`, then a `ListView` of **14 consecutive
    days from today**, `List<DateTime>.generate(14, (int i) => DateTime(now.year, now.month, now.day + i))`.
    Day labels are `shortDateLabel(day, l10n.localeName)` — the range crosses
    a month, so not `weekdayAndDay`. The first row carries
    `l10n.todayChipLabel`. Tapping a day pops
    `MealSlotPick(day, selectedSlot)`.
  - **The sheet writes nothing** — it returns the decision and the caller
    acts on it, the split `showRecipePicker` and `showIngredientPicker` both
    use.
  - `SafeArea` → `ConstrainedBox(maxHeight: MediaQuery.of(context).size.height * 0.8)`
    → `Column(mainAxisSize: MainAxisSize.min)`, as the picker does.
  - `ChoiceChip`s, **not** `SegmentedButton`: four labels
    (`Doručak / Ručak / Večera / Užina`) do not fit a segmented control at
    phone width, and Phase 5 part 2's filter row already established chips.

- `lib/core/l10n/meal_slot_labels.dart`
  - `String mealSlotLabel(MealSlot slot, AppLocalizations l10n)` — the body of
    the current private `_slotLabel`, moved. No `default` arm, deliberately: a
    new `MealSlot` must fail to compile until it has a label. Sits beside
    `core/l10n/date_labels.dart` for the reason `core/error/failure_l10n.dart`
    sits where it does (D92).

**Changed**

- `lib/features/meal_plan/presentation/meal_plan_screen.dart` — delete the
  private `_slotLabel` (~line 190), import `mealSlotLabel`, update its three
  call sites (~318, ~550, ~636). No behaviour change.
- `lib/features/recipes/presentation/recipe_detail_screen.dart`
  - `enum _DetailAction { translate, review, addToPlan, delete }` (~line 263).
  - An unconditional `PopupMenuItem` for `addToPlan` labelled
    `l10n.addToPlanMenuItem`, below the conditional translate/review pair and
    above Delete.
  - `Future<void> _addToPlan(Recipe recipe, AppLocalizations l10n)`:
    `showMealSlotPicker` → `null` or `!mounted` returns → if
    `pick.slot == MealSlot.snack`, `snackRepeatCount` + `shouldWarnOnRepeat`
    + a Cancel / Add-anyway `AlertDialog` reusing `snackRepeatWarningTitle`,
    `snackRepeatWarningBody(l10n.snackSlotCount(n))` and `addAnywayButton`
    (lift `_SlotRow._confirmRepeat`'s shape verbatim) → then
    `ref.read(mealPlanWriterProvider.notifier).addRecipe(entryDate: pick.date, slot: pick.slot, recipeId: widget.recipeId)`
    → success `SnackBar(Text(l10n.addedToPlanSnackbar(...)))`.
    `on AppFailure catch (e)` → `SnackBar(Text(e.localized(l10n)))`, the
    screen's existing shape. Re-check `mounted` after every `await`.
  - New imports: `core/meal_plan/meal_plan_writer.dart`,
    `core/meal_plan/widgets/meal_slot_picker_sheet.dart`,
    `features/meal_plan/domain/meal_slot.dart`,
    `features/meal_plan/domain/snack_variety.dart`. **The two
    `features/meal_plan/domain/` imports are legal** — cross-feature into
    `domain/` is the one permitted direction, and
    `meal_plan_screen.dart` already imports `features/recipes/domain/` the
    same way.
  - A **success** snackbar here is deliberate: the favorite star and the
    rating stars are silent on success because the widget visibly changes,
    whereas this screen shows no evidence at all that the write landed.
    Precedent: `shopping_list_screen.dart:487` `markedAsStapleSnackbar`.
- `lib/core/l10n/arb/app_sr.arb` (template — value + `@key.description`, and
  `placeholders` where there are args) **and** `lib/core/l10n/arb/app_en.arb`
  (value only, same key order). New keys:
  - `addToPlanMenuItem` — "Dodaj u plan..." / "Add to meal plan..."
  - `addToPlanSheetTitle` — "Dodaj u plan obroka" / "Add to meal plan"
  - `todayChipLabel` — "danas" / "today"
  - `addedToPlanSnackbar`, placeholders `{day}` and `{slot}` — e.g.
    "Dodato: {day}, {slot}." / "Added to {day}, {slot}."
  Reused as-is: `mealSlotBreakfast/Lunch/Dinner/Snack`, `cancelButton`,
  `snackRepeatWarningTitle`, `snackRepeatWarningBody`, `snackSlotCount`,
  `addAnywayButton`.
- `lib/core/l10n/generated/*` — regenerated and committed (`make gen`).

**Tests**

- `test/features/recipes/recipe_screens_test.dart` — extend `_pumpDetail`
  (~line 152) with `mealPlanWriterProvider.overrideWith(() => _StubWriter(calls, repeatCount: ...))`.
  `MealPlanWriter` is a non-family notifier, so plain `.overrideWith`, the
  way `mealPlanEditorProvider` is overridden in `meal_plan_screen_test.dart`
  (`.overrideWith2` is only for the family case, e.g. `recipeListProvider`).
  Keep the spy **off** the notifier in a `_Calls` struct — `riverpod_lint`'s
  `avoid_public_notifier_properties` forbids public fields on a `Notifier`.
  Cases: the menu item renders; picking a day + slot calls `addRecipe` with
  exactly that date and slot; a snack slot over the threshold shows the
  warning and "Add anyway" writes while Cancel writes nothing; a non-snack
  slot never calls `snackRepeatCount`; an `AppFailure` renders a snackbar.
- `test/core/meal_plan/meal_slot_picker_sheet_test.dart` (new) — the sheet
  offers exactly 14 days starting today, defaults to dinner, and returns a
  `MealSlotPick` carrying the tapped date and the selected chip.

## Pattern to follow

`lib/core/recipes/` end to end — this slice is its literal mirror.

- `lib/core/recipes/recipe_picker_providers.dart` — its file header is the
  written argument for why a `core/` module may reach into
  `features/<x>/data/` while staying clear of `application/`. Mirror that
  reasoning (and the `@Riverpod(keepAlive: true)` repository-construction
  shape) in `core/meal_plan/meal_plan_writer.dart`'s header.
- `lib/core/recipes/widgets/recipe_picker_sheet.dart` — the sheet's
  structure, the `show*` function signature, the three
  `showModalBottomSheet` flags, and above all the "sheet returns a decision,
  caller performs the write" split.
- `lib/features/meal_plan/presentation/meal_plan_screen.dart` —
  `_SlotRow._add` (~224) and `_confirmRepeat` (~257) are the exact
  snack-warning-then-write sequence to reproduce in `_addToPlan`;
  `_showLeftoverDialog` (~594) is the 14-day `List<DateTime>.generate` +
  `shortDateLabel` usage.
- `test/features/meal_plan/meal_plan_screen_test.dart` — the `_Calls` spy +
  `_StubPlan extends MealPlanEditor` override pattern to copy for
  `_StubWriter`.

## Acceptance

`make check` clean **except** the pre-existing `seed-check` failure recorded
in `docs/STATE.md` (a *comment* edit to `supabase/seeds/ingredients.csv` in
`c8be2bc`). That is not this slice's and must not be "fixed" here. Within
that:

- `dart analyze` clean and `dart run tool/check_layers.dart` OK — the
  layer check is this slice's real proof, since the whole `core/meal_plan/`
  placement exists to satisfy it.
- `flutter test` green, including the new cases and
  `test/core/l10n/arb_parity_test.dart` (key **and** placeholder parity
  across the two ARBs).
- `make l10n-check` — ARB edits regenerated into
  `lib/core/l10n/generated` and committed.
- Run `make gen` after touching an ARB file or adding a `@riverpod`
  annotation, then `dart analyze` before moving on.

Device walk (`make install-hosted` on the attached Galaxy S25 — a release
build against hosted Supabase; `flutter run` and the local stack are not a
demo): open a recipe → overflow → **Add to meal plan...** → pick a day in
*next* week and a slot → see the snackbar → open the Plan tab, page forward
one week, and find the entry there. That forward-paging step is what
actually proves the `PlanWeek.of(entryDate)` decision; no widget test can.
Then add the same recipe to two snack slots to watch D58's advisory dialog
fire from this screen.

No migration in this slice, so no `supabase db push` is needed.

## To record on completion

`docs/journal/phase-5.md`. **One new decision is expected, D103** — *adding
to the plan from a recipe writes through `core/meal_plan/`'s own writer, and
the destination week comes from the chosen date, not the visible one*: cite
D53/D43 for the placement, D56 for the week rule, and name the
`mealPlanEditorProvider` autoDispose hazard as the second, independent reason
for not reusing `MealPlanEditor`. Also update `docs/ROADMAP.md`'s Phase 5
Part 3 entry (status + commit hash) and `docs/STATE.md`.

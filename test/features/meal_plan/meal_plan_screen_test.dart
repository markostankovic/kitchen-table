import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/error/app_failure.dart';
import 'package:kitchen_table/core/recipes/recipe_picker_providers.dart';
import 'package:kitchen_table/features/meal_plan/application/meal_plan_providers.dart';
import 'package:kitchen_table/features/meal_plan/domain/meal_plan_entry.dart';
import 'package:kitchen_table/features/meal_plan/domain/meal_plan_week.dart';
import 'package:kitchen_table/features/meal_plan/domain/meal_slot.dart';
import 'package:kitchen_table/features/meal_plan/domain/plan_week.dart';
import 'package:kitchen_table/features/meal_plan/presentation/meal_plan_screen.dart';
import 'package:kitchen_table/features/recipes/domain/recipe.dart';

/// Captured write calls, kept off the notifier itself: `riverpod_lint` flags
/// a `Notifier` subclass for exposing public state through anything but
/// `state` (`avoid_public_notifier_properties`), so the spy lives in this
/// plain class instead of as fields on [_StubPlan].
class _Calls {
  ({DateTime date, MealSlot slot, String recipeId})? addedRecipe;
  ({DateTime date, MealSlot slot, String note})? addedNote;
  ({String id, DateTime date, MealSlot slot})? moved;
  String? removed;
  ({String sourceId, DateTime date, MealSlot slot})? addedLeftover;
  ({String id, int newPosition})? reordered;
  bool snackRepeatCountCalled = false;
}

/// The notifier is overridden, not mocked -- Riverpod's own override
/// mechanism, so CLAUDE.md rule 8 is never triggered. `build` is replaced
/// with fixed data, and every write method is replaced too (unlike
/// `_StubEditor` in `recipe_edit_screen_test.dart`): those methods reach
/// `currentHouseholdIdProvider` -> `HouseholdRepository.fetchCurrent` ->
/// `Supabase.instance.client`, and this suite overrides no household
/// provider at all -- there is nothing here for a real write to reach.
/// Overriding them turns the call into something this file can capture and
/// assert on directly.
class _StubPlan extends MealPlanEditor {
  _StubPlan(this.initial, this.calls, {this.repeatCount = 0});

  final MealPlanWeek initial;
  final _Calls calls;

  /// What [snackRepeatCount] returns, regardless of the arguments it is
  /// called with -- the exact window/threshold arithmetic is
  /// `snack_variety_test.dart`'s job; this suite only needs to control
  /// whether the screen's warning dialog appears.
  final int repeatCount;

  @override
  Future<MealPlanWeek> build() async => initial;

  @override
  Future<void> addRecipe({
    required DateTime entryDate,
    required MealSlot slot,
    required String recipeId,
  }) async {
    calls.addedRecipe = (date: entryDate, slot: slot, recipeId: recipeId);
  }

  @override
  Future<void> addNote({
    required DateTime entryDate,
    required MealSlot slot,
    required String note,
  }) async {
    calls.addedNote = (date: entryDate, slot: slot, note: note);
  }

  @override
  Future<void> moveEntry({
    required String entryId,
    required DateTime entryDate,
    required MealSlot slot,
  }) async {
    calls.moved = (id: entryId, date: entryDate, slot: slot);
  }

  @override
  Future<void> removeEntry(String entryId) async {
    calls.removed = entryId;
  }

  @override
  Future<void> addLeftover({
    required String sourceEntryId,
    required DateTime entryDate,
    required MealSlot slot,
  }) async {
    calls.addedLeftover =
        (sourceId: sourceEntryId, date: entryDate, slot: slot);
  }

  @override
  Future<void> reorderEntry({
    required String entryId,
    required int newPosition,
  }) async {
    calls.reordered = (id: entryId, newPosition: newPosition);
  }

  @override
  Future<int> snackRepeatCount({
    required String recipeId,
    required DateTime entryDate,
  }) async {
    calls.snackRepeatCountCalled = true;
    return repeatCount;
  }
}

/// A [VisibleWeek] pinned to a known Monday, so day headers and the week
/// label are deterministic. `next` / `previous` / `today` stay real, so
/// navigation is exercised, not bypassed.
class _PinnedWeek extends VisibleWeek {
  @override
  PlanWeek build() => PlanWeek.of(DateTime(2026, 6, 1));
}

final PlanWeek _week = PlanWeek.of(DateTime(2026, 6, 1));
final DateTime _monday = _week.days[0];
final DateTime _tuesday = _week.days[1];

Future<_Calls> _pump(
  WidgetTester tester, {
  required MealPlanWeek initial,
  List<Recipe> plannable = const <Recipe>[],
  int repeatCount = 0,
}) async {
  // The week list is taller than the default 800x600 test surface -- without
  // this, days below the fold simply are not there to find.
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final _Calls calls = _Calls();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mealPlanEditorProvider.overrideWith(
            () => _StubPlan(initial, calls, repeatCount: repeatCount)),
        visibleWeekProvider.overrideWith(() => _PinnedWeek()),
        plannableRecipesProvider(query: '')
            .overrideWith((Ref ref) async => plannable),
      ],
      child: const MaterialApp(home: MealPlanScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return calls;
}

Recipe _plannableRecipe({required String id, required String title}) =>
    Recipe(
      id: id,
      householdId: 'h1',
      title: title,
      originalLocale: 'sr',
      sourceType: RecipeSourceType.manual,
      status: RecipeStatus.tested,
      createdBy: 'u1',
    );

void main() {
  testWidgets('the AppBar is titled Plan', (WidgetTester tester) async {
    await _pump(tester, initial: MealPlanWeek.empty(_week));
    expect(find.widgetWithText(AppBar, 'Plan'), findsOneWidget);
  });

  testWidgets('shows all 7 day headers and 28 slot rows',
      (WidgetTester tester) async {
    await _pump(tester, initial: MealPlanWeek.empty(_week));

    for (final DateTime day in _week.days) {
      expect(find.text('${_dayAbbrev(day)} ${day.day}'), findsOneWidget);
    }
    // Every slot -- populated or not -- carries exactly one "Add" chip.
    expect(find.widgetWithText(ActionChip, 'Add'), findsNWidgets(28));
  });

  testWidgets('an empty week renders with no entry tiles',
      (WidgetTester tester) async {
    await _pump(tester, initial: MealPlanWeek.empty(_week));
    expect(find.byType(Chip), findsNothing);
  });

  testWidgets('a recipe entry renders its title in the right slot',
      (WidgetTester tester) async {
    final MealPlanWeek plan = MealPlanWeek(
      week: _week,
      planId: 'plan-1',
      entries: <MealPlanEntry>[
        MealPlanEntry(
          id: 'e1',
          mealPlanId: 'plan-1',
          entryDate: _monday,
          slot: MealSlot.lunch,
          position: 0,
          entryKind: MealEntryKind.recipe,
          recipeId: 'r1',
          recipeTitle: 'Šargarepa torta',
        ),
      ],
    );

    await _pump(tester, initial: plan);
    expect(find.text('Šargarepa torta'), findsOneWidget);
  });

  testWidgets('a note entry renders its text', (WidgetTester tester) async {
    final MealPlanWeek plan = MealPlanWeek(
      week: _week,
      planId: 'plan-1',
      entries: <MealPlanEntry>[
        MealPlanEntry(
          id: 'e1',
          mealPlanId: 'plan-1',
          entryDate: _tuesday,
          slot: MealSlot.breakfast,
          position: 0,
          entryKind: MealEntryKind.note,
          note: 'zzz kupi mleko',
        ),
      ],
    );

    await _pump(tester, initial: plan);
    expect(find.text('zzz kupi mleko'), findsOneWidget);
  });

  testWidgets('next / previous / today navigate the visible week',
      (WidgetTester tester) async {
    await _pump(tester, initial: MealPlanWeek.empty(_week));

    expect(find.text(_week.label), findsOneWidget);

    await tester.tap(find.byTooltip('Next week'));
    await tester.pumpAndSettle();
    expect(find.text(_week.next.label), findsOneWidget);

    await tester.tap(find.byTooltip('Previous week'));
    await tester.pumpAndSettle();
    expect(find.text(_week.label), findsOneWidget);

    await tester.tap(find.byTooltip('Next week'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('This week'));
    await tester.pumpAndSettle();
    expect(find.text(PlanWeek.of(DateTime.now()).label), findsOneWidget);
  });

  testWidgets('tapping Add, then "Add a note instead" calls addNote',
      (WidgetTester tester) async {
    final _Calls calls =
        await _pump(tester, initial: MealPlanWeek.empty(_week));

    await tester.tap(find.widgetWithText(ActionChip, 'Add').first);
    await tester.pumpAndSettle();

    expect(find.text('Add a note instead'), findsOneWidget);
    await tester.tap(find.text('Add a note instead'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'zzz eating out');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(calls.addedNote, isNotNull);
    expect(calls.addedNote!.note, 'zzz eating out');
    expect(calls.addedNote!.date, _monday);
    expect(calls.addedNote!.slot, MealSlot.breakfast);
  });

  testWidgets('tapping an entry then Remove calls removeEntry',
      (WidgetTester tester) async {
    final MealPlanWeek plan = MealPlanWeek(
      week: _week,
      planId: 'plan-1',
      entries: <MealPlanEntry>[
        MealPlanEntry(
          id: 'e1',
          mealPlanId: 'plan-1',
          entryDate: _monday,
          slot: MealSlot.dinner,
          position: 0,
          entryKind: MealEntryKind.note,
          note: 'zzz removable',
        ),
      ],
    );
    final _Calls calls = await _pump(tester, initial: plan);

    await tester.tap(find.text('zzz removable'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(calls.removed, 'e1');
  });

  testWidgets(
      'the action sheet offers "Plan leftovers..." for a recipe entry, not '
      'for a note or a leftover', (WidgetTester tester) async {
    final MealPlanWeek plan = MealPlanWeek(
      week: _week,
      planId: 'plan-1',
      entries: <MealPlanEntry>[
        MealPlanEntry(
          id: 'e-recipe',
          mealPlanId: 'plan-1',
          entryDate: _monday,
          slot: MealSlot.lunch,
          position: 0,
          entryKind: MealEntryKind.recipe,
          recipeId: 'r1',
          recipeTitle: 'zzz recipe entry',
        ),
        MealPlanEntry(
          id: 'e-note',
          mealPlanId: 'plan-1',
          entryDate: _monday,
          slot: MealSlot.breakfast,
          position: 0,
          entryKind: MealEntryKind.note,
          note: 'zzz note entry',
        ),
        MealPlanEntry(
          id: 'e-leftover',
          mealPlanId: 'plan-1',
          entryDate: _tuesday,
          slot: MealSlot.dinner,
          position: 0,
          entryKind: MealEntryKind.leftover,
          recipeId: 'r1',
          recipeTitle: 'zzz leftover entry',
          leftoverOfEntryId: 'e-recipe',
        ),
      ],
    );
    await _pump(tester, initial: plan);

    await tester.tap(find.text('zzz recipe entry'));
    await tester.pumpAndSettle();
    expect(find.text('Plan leftovers...'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10)); // dismiss via the modal barrier
    await tester.pumpAndSettle();

    await tester.tap(find.text('zzz note entry'));
    await tester.pumpAndSettle();
    expect(find.text('Plan leftovers...'), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Leftovers: zzz leftover entry'));
    await tester.pumpAndSettle();
    expect(find.text('Plan leftovers...'), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
  });

  testWidgets(
      '"Plan leftovers..." defaults to the source date + 1 day and the '
      "source's own slot, and confirming calls addLeftover",
      (WidgetTester tester) async {
    final MealPlanWeek plan = MealPlanWeek(
      week: _week,
      planId: 'plan-1',
      entries: <MealPlanEntry>[
        MealPlanEntry(
          id: 'e1',
          mealPlanId: 'plan-1',
          entryDate: _monday,
          slot: MealSlot.dinner,
          position: 0,
          entryKind: MealEntryKind.recipe,
          recipeId: 'r1',
          recipeTitle: 'zzz sarma',
        ),
      ],
    );
    final _Calls calls = await _pump(tester, initial: plan);
    final DateTime expectedDefault =
        DateTime(_monday.year, _monday.month, _monday.day + 1);

    await tester.tap(find.text('zzz sarma'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plan leftovers...'));
    await tester.pumpAndSettle();

    expect(find.text('Plan leftovers'), findsOneWidget); // dialog title
    expect(find.text(shortDateLabel(expectedDefault)), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(calls.addedLeftover, isNotNull);
    expect(calls.addedLeftover!.sourceId, 'e1');
    expect(calls.addedLeftover!.date, expectedDefault);
    expect(calls.addedLeftover!.slot, MealSlot.dinner);
  });

  testWidgets(
      'the action sheet shows Move up only when not first, Move down only '
      'when not last', (WidgetTester tester) async {
    final MealPlanWeek plan = MealPlanWeek(
      week: _week,
      planId: 'plan-1',
      entries: <MealPlanEntry>[
        MealPlanEntry(
          id: 'e0',
          mealPlanId: 'plan-1',
          entryDate: _monday,
          slot: MealSlot.breakfast,
          position: 0,
          entryKind: MealEntryKind.note,
          note: 'zzz note 0',
        ),
        MealPlanEntry(
          id: 'e1',
          mealPlanId: 'plan-1',
          entryDate: _monday,
          slot: MealSlot.breakfast,
          position: 1,
          entryKind: MealEntryKind.note,
          note: 'zzz note 1',
        ),
        MealPlanEntry(
          id: 'e2',
          mealPlanId: 'plan-1',
          entryDate: _monday,
          slot: MealSlot.breakfast,
          position: 2,
          entryKind: MealEntryKind.note,
          note: 'zzz note 2',
        ),
      ],
    );
    await _pump(tester, initial: plan);

    await tester.tap(find.text('zzz note 0'));
    await tester.pumpAndSettle();
    expect(find.text('Move up'), findsNothing);
    expect(find.text('Move down'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.text('zzz note 2'));
    await tester.pumpAndSettle();
    expect(find.text('Move up'), findsOneWidget);
    expect(find.text('Move down'), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
  });

  testWidgets('tapping Move up calls reorderEntry with index - 1',
      (WidgetTester tester) async {
    final MealPlanWeek plan = MealPlanWeek(
      week: _week,
      planId: 'plan-1',
      entries: <MealPlanEntry>[
        MealPlanEntry(
          id: 'e0',
          mealPlanId: 'plan-1',
          entryDate: _monday,
          slot: MealSlot.breakfast,
          position: 0,
          entryKind: MealEntryKind.note,
          note: 'zzz note 0',
        ),
        MealPlanEntry(
          id: 'e1',
          mealPlanId: 'plan-1',
          entryDate: _monday,
          slot: MealSlot.breakfast,
          position: 1,
          entryKind: MealEntryKind.note,
          note: 'zzz note 1',
        ),
        MealPlanEntry(
          id: 'e2',
          mealPlanId: 'plan-1',
          entryDate: _monday,
          slot: MealSlot.breakfast,
          position: 2,
          entryKind: MealEntryKind.note,
          note: 'zzz note 2',
        ),
      ],
    );
    final _Calls calls = await _pump(tester, initial: plan);

    await tester.tap(find.text('zzz note 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move up'));
    await tester.pumpAndSettle();

    expect(calls.reordered, (id: 'e2', newPosition: 1));
  });

  testWidgets(
      'picking a repeated snack recipe warns, and Cancel writes nothing',
      (WidgetTester tester) async {
    final Recipe recipe = _plannableRecipe(id: 'r1', title: 'zzz snack bar');
    final _Calls calls = await _pump(
      tester,
      initial: MealPlanWeek.empty(_week),
      plannable: <Recipe>[recipe],
      repeatCount: 2,
    );

    // Monday's slot rows are breakfast(0), lunch(1), dinner(2), snack(3).
    await tester.tap(find.widgetWithText(ActionChip, 'Add').at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('zzz snack bar'));
    await tester.pumpAndSettle();

    expect(calls.snackRepeatCountCalled, isTrue);
    expect(find.text('Already planned recently'), findsOneWidget);
    expect(find.text('Already in 2 snack slots this fortnight.'),
        findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(calls.addedRecipe, isNull);
  });

  testWidgets('picking a repeated snack recipe, then Add anyway calls '
      'addRecipe', (WidgetTester tester) async {
    final Recipe recipe = _plannableRecipe(id: 'r1', title: 'zzz snack bar');
    final _Calls calls = await _pump(
      tester,
      initial: MealPlanWeek.empty(_week),
      plannable: <Recipe>[recipe],
      repeatCount: 2,
    );

    await tester.tap(find.widgetWithText(ActionChip, 'Add').at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('zzz snack bar'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Add anyway'));
    await tester.pumpAndSettle();

    expect(calls.addedRecipe, isNotNull);
    expect(calls.addedRecipe!.recipeId, 'r1');
    expect(calls.addedRecipe!.slot, MealSlot.snack);
  });

  testWidgets(
      'a non-snack slot never calls snackRepeatCount, and adds immediately',
      (WidgetTester tester) async {
    final Recipe recipe = _plannableRecipe(id: 'r1', title: 'zzz lunch dish');
    final _Calls calls = await _pump(
      tester,
      initial: MealPlanWeek.empty(_week),
      plannable: <Recipe>[recipe],
      repeatCount: 99,
    );

    // Monday's lunch Add chip -- breakfast(0), lunch(1), dinner(2), snack(3).
    await tester.tap(find.widgetWithText(ActionChip, 'Add').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('zzz lunch dish'));
    await tester.pumpAndSettle();

    expect(calls.snackRepeatCountCalled, isFalse);
    expect(find.text('Already planned recently'), findsNothing);
    expect(calls.addedRecipe, isNotNull);
    expect(calls.addedRecipe!.slot, MealSlot.lunch);
  });

  testWidgets('an AppFailure from the provider renders its message',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mealPlanEditorProvider.overrideWith(() => _ThrowingPlan()),
          visibleWeekProvider.overrideWith(() => _PinnedWeek()),
        ],
        child: const MaterialApp(home: MealPlanScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No connection.'), findsOneWidget);
    // The AppBar must still render even though the body errored.
    expect(find.widgetWithText(AppBar, 'Plan'), findsOneWidget);
  });
}

class _ThrowingPlan extends MealPlanEditor {
  @override
  Future<MealPlanWeek> build() async => throw const NetworkFailure();
}

String _dayAbbrev(DateTime date) =>
    const <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][
        date.weekday - DateTime.monday];

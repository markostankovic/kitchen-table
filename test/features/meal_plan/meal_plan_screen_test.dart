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
  _StubPlan(this.initial, this.calls);

  final MealPlanWeek initial;
  final _Calls calls;

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
        mealPlanEditorProvider.overrideWith(() => _StubPlan(initial, calls)),
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

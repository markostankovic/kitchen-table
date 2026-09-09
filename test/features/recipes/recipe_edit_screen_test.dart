import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/features/recipes/application/recipe_editor.dart';
import 'package:kitchen_table/features/recipes/domain/recipe.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_detail.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_draft.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_ingredient.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_step.dart';
import 'package:kitchen_table/features/recipes/presentation/recipe_edit_screen.dart';

/// The notifier is overridden, not mocked -- Riverpod's own override
/// mechanism, so CLAUDE.md rule 8 is never triggered. Only `build` is
/// replaced: every mutator under test is the real one, because the behaviour
/// worth asserting is exactly what those do to the draft.
///
/// No test presses Save with a valid form. `save()` is the one method that
/// reaches the repository, and it is covered by the pure draft tests either
/// side of it plus the SQL suite; what matters here is that an invalid form
/// never gets that far.
class _StubEditor extends RecipeEditor {
  _StubEditor(this.initial);

  final RecipeDraft initial;

  @override
  Future<RecipeDraft> build(String? recipeId) async => initial;
}

const Recipe _torta = Recipe(
  id: 'r1',
  householdId: 'h1',
  title: 'Šargarepa torta',
  originalLocale: 'sr',
  sourceType: RecipeSourceType.manual,
  status: RecipeStatus.draft,
  createdBy: 'u1',
  servings: 8,
);

final RecipeDetail _detail = RecipeDetail(
  recipe: _torta,
  ingredients: const <RecipeIngredient>[
    RecipeIngredient(position: 0, rawText: '200 g šargarepe'),
    RecipeIngredient(position: 1, rawText: 'so po ukusu'),
  ],
  steps: const <RecipeStep>[
    RecipeStep(position: 0, text: 'Zagrej rernu.'),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  String? recipeId,
  required RecipeDraft draft,
}) async {
  // The form is taller than the default 800x600 test surface, and a ListView
  // does not build what is below the fold. Without this the ingredient and
  // step lists simply are not there to find.
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        recipeEditorProvider(recipeId).overrideWith(() => _StubEditor(draft)),
      ],
      child: MaterialApp(home: RecipeEditScreen(recipeId: recipeId)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('a new recipe', () {
    testWidgets('opens with one empty ingredient line and one empty step',
        (WidgetTester tester) async {
      await _pump(tester, draft: RecipeDraft.empty());

      expect(find.text('New recipe'), findsOneWidget);
      expect(find.text('2 šolje glatkog brašna'), findsOneWidget);
      expect(find.text('Step 1'), findsOneWidget);
    });

    testWidgets('will not save without a title', (WidgetTester tester) async {
      await _pump(tester, draft: RecipeDraft.empty());

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      // The validator stopped it before the repository was ever reached; had
      // it not, this test would have thrown on an uninitialised client.
      expect(find.text('Enter a title.'), findsOneWidget);
    });

    testWidgets('adding an ingredient adds a field',
        (WidgetTester tester) async {
      await _pump(tester, draft: RecipeDraft.empty());

      // One ingredient row and one step row to start with.
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(2));

      await tester.tap(find.widgetWithText(TextButton, 'Add ingredient'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.drag_handle), findsNWidgets(3));
    });
  });

  group('an existing recipe', () {
    testWidgets('opens with its fields and lines filled in',
        (WidgetTester tester) async {
      await _pump(
        tester,
        recipeId: 'r1',
        draft: RecipeDraft.fromDetail(_detail),
      );

      expect(find.text('Edit recipe'), findsOneWidget);
      expect(find.text('Šargarepa torta'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('200 g šargarepe'), findsOneWidget);
      expect(find.text('so po ukusu'), findsOneWidget);
      expect(find.text('Zagrej rernu.'), findsOneWidget);
    });

    testWidgets('removing a line removes that line and no other',
        (WidgetTester tester) async {
      await _pump(
        tester,
        recipeId: 'r1',
        draft: RecipeDraft.fromDetail(_detail),
      );

      // The first Remove button belongs to the first ingredient line.
      await tester.tap(find.widgetWithIcon(IconButton, Icons.close).first);
      await tester.pumpAndSettle();

      expect(find.text('200 g šargarepe'), findsNothing);
      expect(find.text('so po ukusu'), findsOneWidget);
      expect(find.text('Zagrej rernu.'), findsOneWidget);
    });
  });

  group('photo', () {
    testWidgets('a recipe with no photo offers Camera and Gallery, no Remove',
        (WidgetTester tester) async {
      await _pump(tester, draft: RecipeDraft.empty());

      expect(find.widgetWithText(OutlinedButton, 'Camera'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Gallery'), findsOneWidget);
      expect(find.byTooltip('Remove photo'), findsNothing);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('a recipe that already has a photo shows it and offers '
        'Remove', (WidgetTester tester) async {
      final Recipe withPhoto = _torta.copyWith(
        imagePath: 'h1/existing.jpg',
        imageUrl: 'https://example.test/existing.jpg',
      );
      await _pump(
        tester,
        recipeId: 'r1',
        draft: RecipeDraft.fromDetail(_detail.copyWith(recipe: withPhoto)),
      );

      expect(find.byTooltip('Remove photo'), findsOneWidget);
      expect(
        find.byWidgetPredicate((Widget w) =>
            w is Image &&
            w.image is NetworkImage &&
            (w.image as NetworkImage).url ==
                'https://example.test/existing.jpg'),
        findsOneWidget,
      );
    });

    testWidgets('tapping Remove clears the preview and the Remove button',
        (WidgetTester tester) async {
      final Recipe withPhoto = _torta.copyWith(
        imagePath: 'h1/existing.jpg',
        imageUrl: 'https://example.test/existing.jpg',
      );
      await _pump(
        tester,
        recipeId: 'r1',
        draft: RecipeDraft.fromDetail(_detail.copyWith(recipe: withPhoto)),
      );

      await tester.tap(find.byTooltip('Remove photo'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Remove photo'), findsNothing);
      expect(find.byType(Image), findsNothing);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/features/ingredients/domain/ingredient_match.dart';
import 'package:kitchen_table/features/ingredients/domain/quantity.dart';
import 'package:kitchen_table/features/recipes/domain/recipe.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_detail.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_draft.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_ingredient.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_step.dart';

/// The editor's logic lives on [RecipeDraft] as pure functions precisely so it
/// can be tested here, with no Supabase client and no widget tree.

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

RecipeDraft _withLines(List<String> texts) => RecipeDraft(
      lines: <RecipeDraftLine>[
        for (final (int index, String text) in texts.indexed)
          RecipeDraftLine(localId: index, rawText: text),
      ],
    );

void main() {
  group('saving', () {
    test('blank lines are dropped, and the rest are renumbered', () {
      final RecipeDraft draft =
          _withLines(<String>['200 g šargarepe', '   ', 'so po ukusu', '']);

      final List<RecipeIngredient> lines = draft.toIngredients();

      expect(lines.map((RecipeIngredient l) => l.rawText),
          <String>['200 g šargarepe', 'so po ukusu']);
      // Positions are contiguous from zero even though line 1 was dropped.
      expect(lines.map((RecipeIngredient l) => l.position), <int>[0, 1]);
    });

    test('an all-blank line list saves as no lines rather than as a bad row',
        () {
      // recipe_ingredients.raw_text carries length(trim(raw_text)) > 0, so
      // sending the editor's spare empty field would fail the whole
      // transaction.
      expect(RecipeDraft.empty().toIngredients(), isEmpty);
      expect(RecipeDraft.empty().toSteps(), isEmpty);
    });

    test('raw text is trimmed but otherwise untouched', () {
      final List<RecipeIngredient> lines =
          _withLines(<String>['  2 šolje glatkog brašna, prosejano  '])
              .toIngredients();

      expect(lines.single.rawText, '2 šolje glatkog brašna, prosejano');
    });

    test('blank steps are dropped and the rest renumbered', () {
      final RecipeDraft draft = RecipeDraft(
        steps: const <RecipeDraftStep>[
          RecipeDraftStep(localId: 0, text: 'Zagrej rernu.'),
          RecipeDraftStep(localId: 1, text: '  '),
          RecipeDraftStep(localId: 2, text: 'Umuti jaja.'),
        ],
      );

      final List<RecipeStep> steps = draft.toSteps();

      expect(steps.map((RecipeStep s) => s.text),
          <String>['Zagrej rernu.', 'Umuti jaja.']);
      expect(steps.map((RecipeStep s) => s.position), <int>[0, 1]);
    });

    test('structured fields survive the trip to a RecipeIngredient', () {
      final DateTime matchedAt = DateTime.utc(2026, 9, 7, 12);
      final RecipeDraft draft = RecipeDraft(
        lines: <RecipeDraftLine>[
          RecipeDraftLine(
            localId: 0,
            rawText: '200 g šargarepe',
            ingredientId: 'i1',
            quantity: Quantity.whole(200),
            unitCode: 'g',
            matchMethod: MatchMethod.manual,
            matchConfidence: 1,
            matchedAt: matchedAt,
          ),
        ],
      );

      final RecipeIngredient line = draft.toIngredients().single;

      expect(line.ingredientId, 'i1');
      expect(line.quantity, Quantity.whole(200));
      expect(line.unitCode, 'g');
      expect(line.matchMethod, MatchMethod.manual);
      expect(line.matchedAt, matchedAt);
    });
  });

  group('editing lines', () {
    test('a reorder moves the line, using onReorderItem indices', () {
      // ReorderableListView.onReorderItem hands over a newIndex that is
      // already adjusted for the lifted child, so dragging the first line to
      // the end of three reports (0, 2).
      final RecipeDraft draft = _withLines(<String>['a', 'b', 'c'])
          .reorderLines(0, 2);

      expect(draft.lines.map((RecipeDraftLine l) => l.rawText),
          <String>['b', 'c', 'a']);
    });

    test('a reorder upwards moves the line', () {
      final RecipeDraft draft = _withLines(<String>['a', 'b', 'c'])
          .reorderLines(2, 0);

      expect(draft.lines.map((RecipeDraftLine l) => l.rawText),
          <String>['c', 'a', 'b']);
    });

    test('a new line never reuses a live id after a removal', () {
      // Ids key the widgets. Allocating from the list length would hand out 1
      // again here, and the new empty row would inherit the removed row's
      // editing state.
      final RecipeDraft draft =
          _withLines(<String>['a', 'b', 'c']).removeLine(1).addLine();

      final List<int> ids =
          draft.lines.map((RecipeDraftLine l) => l.localId).toList();
      expect(ids, <int>[0, 2, 3]);
      expect(ids.toSet().length, ids.length);
    });

    test('replacing a line leaves its neighbours alone', () {
      final RecipeDraft draft = _withLines(<String>['a', 'b', 'c']);

      final RecipeDraft next = draft.replaceLine(
        draft.lines[1].copyWith(ingredientId: 'i1', displayName: 'brašno'),
      );

      expect(next.lines[0].ingredientId, isNull);
      expect(next.lines[1].ingredientId, 'i1');
      expect(next.lines[2].ingredientId, isNull);
    });

    test('editing one line does not disturb another line’s match decision',
        () {
      // D7: a manual link is a human decision and nothing incidental may
      // overwrite it.
      final RecipeDraft draft = RecipeDraft(
        lines: const <RecipeDraftLine>[
          RecipeDraftLine(
            localId: 0,
            rawText: 'šargarepa',
            ingredientId: 'i1',
            matchMethod: MatchMethod.manual,
          ),
          RecipeDraftLine(localId: 1, rawText: ''),
        ],
      );

      final RecipeDraft next = draft.setLineText(1, 'so');

      expect(next.lines[0].ingredientId, 'i1');
      expect(next.lines[0].isManual, isTrue);
      expect(next.lines[1].rawText, 'so');
    });
  });

  group('loading and folding back', () {
    test('fromDetail carries the recipe and its children', () {
      final RecipeDetail detail = RecipeDetail(
        recipe: _torta,
        ingredients: const <RecipeIngredient>[
          RecipeIngredient(
            position: 0,
            rawText: '200 g šargarepe',
            ingredientId: 'i1',
            displayName: 'šargarepa',
          ),
        ],
        steps: const <RecipeStep>[
          RecipeStep(position: 0, text: 'Zagrej rernu.'),
        ],
      );

      final RecipeDraft draft = RecipeDraft.fromDetail(detail);

      expect(draft.recipeId, 'r1');
      expect(draft.title, 'Šargarepa torta');
      expect(draft.servings, 8);
      expect(draft.originalLocale, 'sr');
      expect(draft.lines.single.rawText, '200 g šargarepe');
      expect(draft.lines.single.displayName, 'šargarepa');
      expect(draft.steps.single.text, 'Zagrej rernu.');
      // Local ids are handed out on load, since the server rows have none the
      // widget layer can use.
      expect(draft.lines.single.localId, 0);
    });

    test('toRecipe folds the edits onto the row without losing its owner', () {
      final RecipeDraft draft = RecipeDraft.fromDetail(
        const RecipeDetail(recipe: _torta),
      ).copyWith(title: 'Torta od šargarepe', servings: 12);

      final Recipe updated = draft.toRecipe();

      expect(updated.id, 'r1');
      expect(updated.title, 'Torta od šargarepe');
      expect(updated.servings, 12);
      // Not the editor's to change, and never sent in an update payload.
      expect(updated.householdId, 'h1');
      expect(updated.createdBy, 'u1');
      expect(updated.sourceType, RecipeSourceType.manual);
    });

    test('toRecipe refuses a draft that has never been saved', () {
      // There is no household id or author to preserve yet -- that draft has
      // to go through RecipeRepository.create instead.
      expect(RecipeDraft.empty().toRecipe, throwsStateError);
    });

    test('a new draft has no recipe id until it is given one', () {
      expect(RecipeDraft.empty().recipeId, isNull);
      expect(
        RecipeDraft.empty().copyWith(source: _torta).recipeId,
        'r1',
      );
    });

    test('imagePath survives fromDetail and reaches toRecipe unchanged', () {
      final Recipe withPhoto =
          _torta.copyWith(imagePath: 'h1/123.jpg', imageUrl: 'https://x/1');
      final RecipeDraft draft =
          RecipeDraft.fromDetail(RecipeDetail(recipe: withPhoto));

      expect(draft.imagePath, 'h1/123.jpg');

      final Recipe updated = draft.toRecipe();
      expect(updated.imagePath, 'h1/123.jpg');
    });

    test('clearing imagePath reaches toRecipe as null -- removing a photo '
        'must actually reach the wire', () {
      final Recipe withPhoto = _torta.copyWith(imagePath: 'h1/123.jpg');
      final RecipeDraft draft = RecipeDraft.fromDetail(
        RecipeDetail(recipe: withPhoto),
      ).copyWith(imagePath: null);

      final Recipe updated = draft.toRecipe();
      expect(updated.imagePath, isNull);
    });
  });
}

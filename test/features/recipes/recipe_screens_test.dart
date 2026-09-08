import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/features/ingredients/domain/ingredient_match.dart';
import 'package:kitchen_table/features/ingredients/domain/quantity.dart';
import 'package:kitchen_table/features/ingredients/domain/unit.dart';
import 'package:kitchen_table/features/ingredients/domain/unit_catalog.dart';
import 'package:kitchen_table/core/ingredients/ingredient_catalog_providers.dart';
import 'package:kitchen_table/features/recipes/application/recipe_providers.dart';
import 'package:kitchen_table/features/recipes/domain/recipe.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_detail.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_ingredient.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_step.dart';
import 'package:kitchen_table/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:kitchen_table/features/recipes/presentation/recipe_list_screen.dart';

/// Providers are overridden rather than mocked -- Riverpod's own override
/// mechanism means no mocking package, so CLAUDE.md rule 8 is never triggered.

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

const Recipe _pita = Recipe(
  id: 'r2',
  householdId: 'h1',
  title: 'Pita sa sirom',
  originalLocale: 'sr',
  sourceType: RecipeSourceType.manual,
  status: RecipeStatus.tested,
  createdBy: 'u1',
);

/// A lexicon with the Serbian display spellings the seed actually carries, so
/// the detail screen has something to render other than the bare code.
final UnitCatalog _units = UnitCatalog(
  units: const <Unit>[
    Unit(code: 'g', family: UnitFamily.mass, toBase: 1, isMetric: true),
    Unit(code: 'tbsp', family: UnitFamily.volume, toBase: 15),
  ],
  aliases: const <String, String>{'g': 'g', 'kašika': 'tbsp'},
  displayNames: const <String, String>{
    'g|sr': 'g',
    'tbsp|sr': 'kašika',
    'tbsp|en': 'tbsp',
  },
);

final RecipeDetail _detail = RecipeDetail(
  recipe: _torta,
  ingredients: <RecipeIngredient>[
    // Matched: renders the CATALOG's word, not the genitive the cook typed.
    RecipeIngredient(
      position: 0,
      rawText: '200 g šargarepe',
      ingredientId: 'i1',
      displayName: 'šargarepa',
      quantity: Quantity.whole(200),
      unitCode: 'g',
      matchMethod: MatchMethod.alias,
      matchConfidence: 1,
    ),
    // Matched, with a unit whose Serbian spelling differs from its code.
    RecipeIngredient(
      position: 1,
      rawText: '1 kašika ajvara',
      ingredientId: 'i2',
      displayName: 'ajvar',
      quantity: Quantity.whole(1),
      unitCode: 'tbsp',
      matchMethod: MatchMethod.alias,
      matchConfidence: 1,
    ),
    // Unmatched: renders exactly what was typed (rule 3).
    const RecipeIngredient(
      position: 2,
      rawText: 'malo domaćeg sira',
      note: 'po ukusu',
      isOptional: true,
    ),
  ],
  steps: const <RecipeStep>[
    RecipeStep(position: 0, text: 'Zagrej rernu.'),
  ],
);

Future<void> _pumpList(
  WidgetTester tester, {
  required List<Recipe> recipes,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        recipeListProvider.overrideWith(
          (Ref ref, String query) async => query.isEmpty
              ? recipes
              : recipes
                  .where((Recipe r) =>
                      r.title.toLowerCase().contains(query.toLowerCase()))
                  .toList(),
        ),
      ],
      child: const MaterialApp(home: RecipeListScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpDetail(WidgetTester tester, RecipeDetail detail) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        recipeDetailProvider('r1').overrideWith((Ref ref) async => detail),
        unitCatalogProvider.overrideWith((Ref ref) async => _units),
      ],
      child: const MaterialApp(
        home: RecipeDetailScreen(recipeId: 'r1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('recipe list', () {
    testWidgets('lists the household\'s recipes', (WidgetTester tester) async {
      await _pumpList(tester, recipes: <Recipe>[_torta, _pita]);

      expect(find.text('Šargarepa torta'), findsOneWidget);
      expect(find.text('Pita sa sirom'), findsOneWidget);
    });

    testWidgets('marks a draft and leaves a tested recipe unmarked',
        (WidgetTester tester) async {
      await _pumpList(tester, recipes: <Recipe>[_torta, _pita]);

      expect(find.widgetWithText(Chip, 'Draft'), findsOneWidget);
    });

    testWidgets('an empty household gets the invitation, not "no match"',
        (WidgetTester tester) async {
      await _pumpList(tester, recipes: <Recipe>[]);

      expect(find.textContaining('No recipes yet'), findsOneWidget);
    });

    testWidgets('typing filters, after the debounce', (WidgetTester tester) async {
      await _pumpList(tester, recipes: <Recipe>[_torta, _pita]);

      await tester.enterText(find.byType(TextField), 'pita');
      // Before the debounce elapses the list is untouched -- that is the
      // point of it, and it is why the provider family stays small.
      await tester.pump();
      expect(find.text('Šargarepa torta'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Pita sa sirom'), findsOneWidget);
      expect(find.text('Šargarepa torta'), findsNothing);
    });
  });

  group('recipe detail', () {
    testWidgets('a matched line renders the catalog name, not the raw text',
        (WidgetTester tester) async {
      await _pumpDetail(tester, _detail);

      // D1: the cook typed the genitive `šargarepe`; the catalog says
      // `šargarepa`, and that is what a reader sees.
      expect(find.text('šargarepa'), findsOneWidget);
      expect(find.text('200 g šargarepe'), findsNothing);
    });

    testWidgets('an unmatched line renders exactly what was typed',
        (WidgetTester tester) async {
      await _pumpDetail(tester, _detail);

      // Rule 3: a failed match is a supported state, and the line survives it.
      expect(find.text('malo domaćeg sira'), findsOneWidget);
      expect(find.text('po ukusu'), findsOneWidget);
    });

    testWidgets('units render in the recipe\'s language, not as their code',
        (WidgetTester tester) async {
      await _pumpDetail(tester, _detail);

      expect(find.text('1 kašika'), findsOneWidget);
      expect(find.text('1 tbsp'), findsNothing);
      // Grams are spelled the same either way.
      expect(find.text('200 g'), findsOneWidget);
    });

    testWidgets('quantities render as fractions, never decimals',
        (WidgetTester tester) async {
      await _pumpDetail(
        tester,
        _detail.copyWith(
          ingredients: <RecipeIngredient>[
            RecipeIngredient(
              position: 0,
              rawText: '1 1/2 šolje mleka',
              ingredientId: 'i3',
              displayName: 'mleko',
              quantity: Quantity.fraction(3, 2),
            ),
          ],
        ),
      );

      expect(find.text('1½'), findsOneWidget);
      expect(find.textContaining('1.5'), findsNothing);
    });
  });
}

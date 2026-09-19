import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/l10n/app_locale.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations.dart';
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
import 'package:kitchen_table/features/recipes/domain/recipe_translation.dart';
import 'package:kitchen_table/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:kitchen_table/features/recipes/presentation/recipe_list_screen.dart';

/// Providers are overridden rather than mocked -- Riverpod's own override
/// mechanism means no mocking package, so CLAUDE.md rule 8 is never triggered.

/// A stub for the `StreamNotifier` family `recipeListProvider` became in
/// Phase 2 part 6a -- on `shopping_list_screen_test.dart`'s `_StubList`
/// precedent. Filters [recipes] by `query` itself, matching the old
/// override's own inline logic, since [RecipeList.build] is never reached
/// through a stub.
class _StubRecipeList extends RecipeList {
  _StubRecipeList(this.recipes);

  final List<Recipe> recipes;

  @override
  Stream<List<Recipe>> build({String query = ''}) async* {
    yield query.isEmpty
        ? recipes
        : recipes
            .where(
              (Recipe r) =>
                  r.title.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
  }
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
  readingLocale: 'sr',
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
        recipeListProvider.overrideWith2((_) => _StubRecipeList(recipes)),
      ],
      // The AppBar title reads AppLocalizations now (D77, Phase 3 part 1),
      // so this screen needs the delegates wired in -- the real app root
      // does this once in `main.dart`; a bare `MaterialApp` in a widget test
      // has to do it itself.
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
        home: RecipeListScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpDetail(WidgetTester tester, RecipeDetail detail) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // appLocaleProvider is pinned to detail.readingLocale rather than
        // left at its own fallback: the screen derives `readingLocale` from
        // it, and the two must agree or the screen requests a different
        // provider instance than this override matches.
        appLocaleProvider
            .overrideWith((Ref ref) => Locale(detail.readingLocale)),
        recipeDetailProvider('r1', locale: detail.readingLocale)
            .overrideWith((Ref ref) async => detail),
        unitCatalogProvider.overrideWith((Ref ref) async => _units),
      ],
      // The screen now reads AppLocalizations too (Phase 3 part 2), on
      // `_pumpList`'s own precedent above.
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
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

    testWidgets('a recipe with a photo shows a thumbnail',
        (WidgetTester tester) async {
      final Recipe withPhoto =
          _torta.copyWith(imageUrl: 'https://example.test/thumb.jpg');
      await _pumpList(tester, recipes: <Recipe>[withPhoto, _pita]);

      expect(
        find.byWidgetPredicate((Widget w) =>
            w is Image &&
            w.image is NetworkImage &&
            (w.image as NetworkImage).url == 'https://example.test/thumb.jpg'),
        findsOneWidget,
      );
    });

    testWidgets('a recipe with no photo shows no thumbnail, unchanged',
        (WidgetTester tester) async {
      await _pumpList(tester, recipes: <Recipe>[_torta, _pita]);

      expect(find.byType(Image), findsNothing);
    });

    testWidgets('a favorited, rated recipe shows a star and the rating',
        (WidgetTester tester) async {
      final Recipe favorited =
          _torta.copyWith(isFavorite: true, rating: 4);
      await _pumpList(tester, recipes: <Recipe>[favorited, _pita]);

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.textContaining('★ 4'), findsOneWidget);
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

    testWidgets('renders the recipe photo when the recipe has one',
        (WidgetTester tester) async {
      await _pumpDetail(
        tester,
        _detail.copyWith(
          recipe: _torta.copyWith(imageUrl: 'https://example.test/torta.jpg'),
        ),
      );

      expect(
        find.byWidgetPredicate((Widget w) =>
            w is Image &&
            w.image is NetworkImage &&
            (w.image as NetworkImage).url == 'https://example.test/torta.jpg'),
        findsOneWidget,
      );
    });

    testWidgets('renders unchanged when the recipe has no photo',
        (WidgetTester tester) async {
      await _pumpDetail(tester, _detail);

      expect(find.byType(Image), findsNothing);
    });

    testWidgets('three filled and two outlined stars for rating: 3',
        (WidgetTester tester) async {
      await _pumpDetail(
        tester,
        _detail.copyWith(recipe: _torta.copyWith(rating: 3)),
      );

      final Finder stars = find.byKey(const Key('ratingStars'));
      expect(
        find.descendant(of: stars, matching: find.byIcon(Icons.star)),
        findsNWidgets(3),
      );
      expect(
        find.descendant(of: stars, matching: find.byIcon(Icons.star_border)),
        findsNWidgets(2),
      );
    });

    testWidgets('five outlined stars for rating: null',
        (WidgetTester tester) async {
      await _pumpDetail(tester, _detail);

      final Finder stars = find.byKey(const Key('ratingStars'));
      expect(
        find.descendant(of: stars, matching: find.byIcon(Icons.star)),
        findsNothing,
      );
      expect(
        find.descendant(of: stars, matching: find.byIcon(Icons.star_border)),
        findsNWidgets(5),
      );
    });
  });

  // Phase 3, part 3: the overflow menu's Translate/Review entry points and
  // the Machine translation chip, none of which had a widget test before
  // this part.
  group('translation review entry points', () {
    testWidgets('Translate shows and Review does not, with no translation',
        (WidgetTester tester) async {
      await _pumpDetail(tester, _detail.copyWith(readingLocale: 'en'));

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // The recipe's own language is Serbian, so translating INTO the
      // reading locale ('en') is offered as "Translate to English".
      expect(find.text('Translate to English'), findsOneWidget);
      expect(find.text('Review translation'), findsNothing);
    });

    testWidgets('Review shows and Translate does not, once a translation exists',
        (WidgetTester tester) async {
      final RecipeDetail translated = _detail.copyWith(
        readingLocale: 'en',
        translations: <RecipeTranslation>[
          const RecipeTranslation(locale: 'en', title: 'Carrot cake'),
        ],
      );
      await _pumpDetail(tester, translated);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Review translation'), findsOneWidget);
      expect(find.textContaining('Translate to'), findsNothing);
    });

    testWidgets('neither shows while reading the recipe\'s own language',
        (WidgetTester tester) async {
      await _pumpDetail(tester, _detail); // readingLocale: 'sr', same as original

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.textContaining('Translate to'), findsNothing);
      expect(find.text('Review translation'), findsNothing);
    });

    testWidgets('the Machine translation chip renders for a machine draft',
        (WidgetTester tester) async {
      await _pumpDetail(
        tester,
        _detail.copyWith(
          readingLocale: 'en',
          translations: <RecipeTranslation>[
            const RecipeTranslation(locale: 'en', title: 'Carrot cake'),
          ],
        ),
      );

      expect(find.text('Machine translation'), findsOneWidget);
    });

    testWidgets('the Machine translation chip is absent once reviewed',
        (WidgetTester tester) async {
      await _pumpDetail(
        tester,
        _detail.copyWith(
          readingLocale: 'en',
          translations: <RecipeTranslation>[
            RecipeTranslation(
              locale: 'en',
              title: 'Carrot cake',
              isMachineGenerated: false,
              reviewedBy: 'u2',
              reviewedAt: DateTime.utc(2026, 9, 14),
            ),
          ],
        ),
      );

      expect(find.text('Machine translation'), findsNothing);
      // And Review is still on offer -- a reviewed translation stays
      // reviewable (canReview does not narrow to an unreviewed one).
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text('Review translation'), findsOneWidget);
    });
  });
}

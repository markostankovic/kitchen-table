import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/images/recipe_image_cache.dart';
import 'package:kitchen_table/core/error/app_failure.dart';
import 'package:kitchen_table/core/household/current_household.dart';
import 'package:kitchen_table/core/household/widgets/household_switch_placeholder.dart';
import 'package:kitchen_table/core/supabase/supabase_client.dart';
import 'package:kitchen_table/core/l10n/app_locale.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations.dart';
import 'package:kitchen_table/core/meal_plan/meal_plan_writer.dart';
import 'package:kitchen_table/core/recipes/widgets/recipe_card.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/core/widgets/app_badge.dart';
import 'package:kitchen_table/core/widgets/app_meta_row.dart';
import 'package:kitchen_table/core/widgets/app_monogram_tile.dart';
import 'package:kitchen_table/features/households/application/household_providers.dart';
import 'package:kitchen_table/features/households/domain/household.dart';
import 'package:kitchen_table/features/ingredients/domain/ingredient_match.dart';
import 'package:kitchen_table/features/ingredients/domain/quantity.dart';
import 'package:kitchen_table/features/ingredients/domain/unit.dart';
import 'package:kitchen_table/features/ingredients/domain/unit_catalog.dart';
import 'package:kitchen_table/core/ingredients/ingredient_catalog_providers.dart';
import 'package:kitchen_table/core/ingredients/widgets/ingredient_line_row.dart';
import 'package:kitchen_table/features/meal_plan/domain/meal_slot.dart';
import 'package:kitchen_table/features/recipes/application/recipe_providers.dart';
import 'package:kitchen_table/features/recipes/domain/recipe.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_detail.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_filter.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_ingredient.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_step.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_translation.dart';
import 'package:kitchen_table/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:kitchen_table/features/recipes/presentation/recipe_list_screen.dart';

import '../../helpers/fake_image_cache.dart';
import '../../helpers/household_switch_harness.dart';

/// Providers are overridden rather than mocked -- Riverpod's own override
/// mechanism means no mocking package, so CLAUDE.md rule 8 is never triggered.

/// A stub for the `StreamNotifier` family `recipeListProvider` became in
/// Phase 2 part 6a -- on `shopping_list_screen_test.dart`'s `_StubList`
/// precedent. Filters [recipes] through the real [RecipeFilter.apply] (Phase
/// 6, part 2) rather than a hand-rolled inline filter, so a widget test can
/// never again assert semantics the repository has moved past, since
/// [RecipeList.build] is never reached through a stub.
class _StubRecipeList extends RecipeList {
  _StubRecipeList(this.recipes);

  final List<Recipe> recipes;

  @override
  Stream<List<Recipe>> build({
    String query = '',
    String tag = '',
    bool favoritesOnly = false,
  }) async* {
    yield RecipeFilter.apply(
      recipes,
      query: query,
      tag: tag,
      favoritesOnly: favoritesOnly,
    );
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

/// Two sections of two unmatched lines each: rendered as typed (rule 3).
const List<RecipeIngredient> _sectionedLines = <RecipeIngredient>[
  RecipeIngredient(position: 0, rawText: 'brašno', section: 'Za testo'),
  RecipeIngredient(position: 1, rawText: 'jaja', section: 'Za testo'),
  RecipeIngredient(position: 2, rawText: 'sir', section: 'Za fil'),
  RecipeIngredient(position: 3, rawText: 'pavlaka', section: 'Za fil'),
];

Future<void> _pumpList(
  WidgetTester tester, {
  required List<Recipe> recipes,
  String locale = 'sr',
  Map<String, String> tagLabels = const <String, String>{},
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        recipeListProvider.overrideWith2((_) => _StubRecipeList(recipes)),
        // Phase 8 part 2: a recipe photo goes through the disk cache, and
        // the real one opens a database through path_provider.
        recipeImageCacheManagerProvider.overrideWithValue(FakeImageCache()),
        // Pinned rather than left at its own fallback (`_pumpDetail`'s own
        // reasoning): `_FilterRow` now watches this to resolve tag labels
        // (Phase 6, part 1a), and the default reaches the real profile
        // provider chain, which nothing in this file stubs.
        appLocaleProvider.overrideWith((Ref ref) => Locale(locale)),
        tagLabelsProvider(locale).overrideWith((Ref ref) async => tagLabels),
      ],
      // The AppBar title reads AppLocalizations now (D77, Phase 3 part 1),
      // so this screen needs the delegates wired in -- the real app root
      // does this once in `main.dart`; a bare `MaterialApp` in a widget test
      // has to do it itself. Phase 7 part 3 adds the theme for the same
      // reason: the redesigned widgets read `KitchenColors` off it, and a
      // default `ThemeData` carries no extensions.
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
        home: const RecipeListScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Captured `MealPlanWriter` calls, kept off the notifier itself:
/// `riverpod_lint`'s `avoid_public_notifier_properties` forbids public fields
/// on a `Notifier`, so the spy lives in this plain class instead, on
/// `meal_plan_screen_test.dart`'s own `_Calls` precedent.
class _Calls {
  ({DateTime date, MealSlot slot, String recipeId})? addedRecipe;
  bool snackRepeatCountCalled = false;
}

/// The notifier is overridden, not mocked (Riverpod's own override
/// mechanism, CLAUDE.md rule 8) -- `meal_plan_screen_test.dart`'s `_StubPlan`
/// is this class's exact precedent, one notifier over.
class _StubWriter extends MealPlanWriter {
  _StubWriter(this.calls, {this.repeatCount = 0});

  final _Calls calls;
  final int repeatCount;

  @override
  void build() {}

  @override
  Future<int> snackRepeatCount({
    required String recipeId,
    required DateTime entryDate,
  }) async {
    calls.snackRepeatCountCalled = true;
    return repeatCount;
  }

  @override
  Future<void> addRecipe({
    required DateTime entryDate,
    required MealSlot slot,
    required String recipeId,
  }) async {
    calls.addedRecipe = (date: entryDate, slot: slot, recipeId: recipeId);
  }
}

class _ThrowingWriter extends MealPlanWriter {
  @override
  void build() {}

  @override
  Future<void> addRecipe({
    required DateTime entryDate,
    required MealSlot slot,
    required String recipeId,
  }) async {
    throw const NotFoundFailure(
      message: 'You are not in a household yet.',
      code: FailureCode.noHousehold,
    );
  }
}

Future<void> _pumpDetail(
  WidgetTester tester,
  RecipeDetail detail, {
  MealPlanWriter? writer,
  Map<String, String> tagLabels = const <String, String>{},
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Phase 8 part 2: a recipe photo goes through the disk cache, and
        // the real one opens a database through path_provider.
        recipeImageCacheManagerProvider.overrideWithValue(FakeImageCache()),
        // appLocaleProvider is pinned to detail.readingLocale rather than
        // left at its own fallback: the screen derives `readingLocale` from
        // it, and the two must agree or the screen requests a different
        // provider instance than this override matches.
        appLocaleProvider
            .overrideWith((Ref ref) => Locale(detail.readingLocale)),
        recipeDetailProvider('r1', locale: detail.readingLocale)
            .overrideWith((Ref ref) async => detail),
        unitCatalogProvider.overrideWith((Ref ref) async => _units),
        // Phase 6, part 1a: the tags chip row resolves through this now.
        tagLabelsProvider(detail.readingLocale)
            .overrideWith((Ref ref) async => tagLabels),
        if (writer != null) mealPlanWriterProvider.overrideWith(() => writer),
      ],
      // The screen now reads AppLocalizations too (Phase 3 part 2), and the
      // theme for `KitchenColors`, both on `_pumpList`'s own precedent above.
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
        home: const RecipeDetailScreen(recipeId: 'r1'),
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

      // An AppBadge since Phase 7 part 3, not a Chip: a chip in this app is
      // a control, and nothing taps this.
      expect(find.widgetWithText(AppBadge, 'Draft'), findsOneWidget);
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

    testWidgets('typing a tag name into the search field narrows the list',
        (WidgetTester tester) async {
      await _pumpList(
        tester,
        recipes: <Recipe>[
          _torta.copyWith(tags: <String>['Posno']),
          _pita.copyWith(tags: <String>['Brzo']),
        ],
      );

      await tester.enterText(find.byType(TextField), 'posno');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Šargarepa torta'), findsOneWidget);
      expect(find.text('Pita sa sirom'), findsNothing);
    });

    testWidgets('a recipe with a photo shows a thumbnail',
        (WidgetTester tester) async {
      final Recipe withPhoto = _torta.copyWith(
        imagePath: 'h1/thumb.jpg',
        imageUrl: 'https://example.test/thumb.jpg',
      );
      await _pumpList(tester, recipes: <Recipe>[withPhoto, _pita]);

      // Cached under the object path, not the signed URL, and decoded near
      // the tile's size rather than at the full upload.
      final CachedNetworkImage image =
          tester.widget(find.byType(CachedNetworkImage));
      expect(image.imageUrl, 'https://example.test/thumb.jpg');
      expect(image.cacheKey, 'h1/thumb.jpg');
      expect(image.memCacheWidth, isNotNull);
    });

    testWidgets('a recipe with no photo gets a monogram tile, not a gap',
        (WidgetTester tester) async {
      await _pumpList(tester, recipes: <Recipe>[_torta, _pita]);

      // Phase 7 part 3: an empty leading square read as a thumbnail that had
      // failed to load, and most recipes in this app will never have a
      // photo. The tile is the title's first letter, upper-cased.
      expect(find.byType(Image), findsNothing);
      expect(find.byType(AppMonogramTile), findsNWidgets(2));
      expect(find.widgetWithText(AppMonogramTile, 'Š'), findsOneWidget);
      expect(find.widgetWithText(AppMonogramTile, 'P'), findsOneWidget);
    });

    testWidgets('a favorited, rated recipe shows a heart and the rating',
        (WidgetTester tester) async {
      final Recipe favorited =
          _torta.copyWith(isFavorite: true, rating: 4);
      await _pumpList(tester, recipes: <Recipe>[favorited, _pita]);

      // Phase 7 part 3 split the two meanings the star used to carry:
      // favourite is a heart, and a star is a rating and nothing else. The
      // Favorites filter chip lost its star avatar in the same change, so
      // this no longer has to scope around it -- but it stays scoped to the
      // card, because the meta row's own rating star is also an Icons.star.
      final Finder card = find.byType(RecipeCard);
      expect(
        find.descendant(of: card, matching: find.byIcon(Icons.favorite)),
        findsOneWidget,
      );
      // The rating is its own meta item now, a star beside a bare number --
      // never the `★ 4` run that used to be glued into the joined meta line.
      expect(
        find.descendant(of: card, matching: find.byIcon(Icons.star)),
        findsOneWidget,
      );
      expect(find.widgetWithText(AppMetaItem, '4'), findsOneWidget);
      expect(find.textContaining('★'), findsNothing);
    });

    testWidgets('shows a chip per distinct tag', (WidgetTester tester) async {
      await _pumpList(
        tester,
        recipes: <Recipe>[
          _torta.copyWith(tags: <String>['Posno']),
          _pita.copyWith(tags: <String>['Brzo']),
        ],
      );

      expect(find.text('Posno'), findsOneWidget);
      expect(find.text('Brzo'), findsOneWidget);
    });

    testWidgets('tapping a tag chip narrows the list',
        (WidgetTester tester) async {
      await _pumpList(
        tester,
        recipes: <Recipe>[
          _torta.copyWith(tags: <String>['Posno']),
          _pita.copyWith(tags: <String>['Brzo']),
        ],
      );

      await tester.tap(find.text('Posno'));
      await tester.pumpAndSettle();

      expect(find.text('Šargarepa torta'), findsOneWidget);
      expect(find.text('Pita sa sirom'), findsNothing);
    });

    // Phase 6, part 1a: a tag typed in one language renders in the reader's
    // own language.
    testWidgets('a tag with a translated pair renders in the reader\'s '
        'language', (WidgetTester tester) async {
      await _pumpList(
        tester,
        recipes: <Recipe>[_torta.copyWith(tags: <String>['Posno'])],
        locale: 'en',
        tagLabels: <String, String>{'posno': 'Lenten'},
      );

      expect(find.text('Lenten'), findsOneWidget);
      expect(find.text('Posno'), findsNothing);
    });

    testWidgets('a tag with no pair renders exactly as typed, in either '
        'language', (WidgetTester tester) async {
      await _pumpList(
        tester,
        recipes: <Recipe>[_torta.copyWith(tags: <String>['Brzo'])],
        locale: 'en',
        tagLabels: <String, String>{'posno': 'Lenten'},
      );

      expect(find.text('Brzo'), findsOneWidget);
    });

    testWidgets(
        'tapping a translated chip still narrows the list -- its key is '
        'unchanged', (WidgetTester tester) async {
      await _pumpList(
        tester,
        recipes: <Recipe>[
          _torta.copyWith(tags: <String>['Posno']),
          _pita.copyWith(tags: <String>['Brzo']),
        ],
        locale: 'en',
        tagLabels: <String, String>{'posno': 'Lenten'},
      );

      await tester.tap(find.text('Lenten'));
      await tester.pumpAndSettle();

      expect(find.text('Šargarepa torta'), findsOneWidget);
      expect(find.text('Pita sa sirom'), findsNothing);
    });

    testWidgets('the Favorites chip narrows to starred recipes',
        (WidgetTester tester) async {
      await _pumpList(
        tester,
        recipes: <Recipe>[
          _torta.copyWith(isFavorite: true, tags: <String>['Posno']),
          _pita.copyWith(tags: <String>['Posno']),
        ],
      );

      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();

      expect(find.text('Šargarepa torta'), findsOneWidget);
      expect(find.text('Pita sa sirom'), findsNothing);
    });

    testWidgets(
        'a household with recipes but no tags still shows the Favorites '
        'chip', (WidgetTester tester) async {
      // No tags on either recipe -- the filter row's visibility is bound to
      // the recipe list, not the tag vocabulary (Phase 6, part 2, closing
      // D102's open consequence), so Favorites must still have a home.
      await _pumpList(tester, recipes: <Recipe>[_torta, _pita]);

      expect(find.text('Favorites'), findsOneWidget);

      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No recipes match'), findsOneWidget);
    });

    testWidgets('favorites and a tag combine', (WidgetTester tester) async {
      await _pumpList(
        tester,
        recipes: <Recipe>[
          _torta.copyWith(isFavorite: true, tags: <String>['Posno']),
          // Favorited too, but a different tag -- must drop out once both
          // filters are on, proving the AND rather than either alone.
          _pita.copyWith(isFavorite: true, tags: <String>['Brzo']),
        ],
      );

      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();
      expect(find.text('Šargarepa torta'), findsOneWidget);
      expect(find.text('Pita sa sirom'), findsOneWidget);

      await tester.tap(find.text('Posno'));
      await tester.pumpAndSettle();

      expect(find.text('Šargarepa torta'), findsOneWidget);
      expect(find.text('Pita sa sirom'), findsNothing);
    });
  });

  // Phase 7 part 9b: Clear, the result count, the filter-aware empty state.
  group('recipe list filters', () {
    final List<Recipe> tagged = <Recipe>[
      _torta.copyWith(isFavorite: true, tags: <String>['Posno']),
      _pita.copyWith(tags: <String>['Brzo']),
    ];

    testWidgets('Clear appears only while a filter is on',
        (WidgetTester tester) async {
      await _pumpList(tester, recipes: tagged);
      expect(find.widgetWithText(ActionChip, 'Clear'), findsNothing);

      await tester.tap(find.text('Posno'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ActionChip, 'Clear'), findsOneWidget);

      await tester.tap(find.text('Posno'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ActionChip, 'Clear'), findsNothing);
    });

    testWidgets('a query alone does not bring Clear up',
        (WidgetTester tester) async {
      await _pumpList(tester, recipes: tagged);

      await tester.enterText(find.byType(TextField), 'pita');
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      expect(find.widgetWithText(ActionChip, 'Clear'), findsNothing);
    });

    testWidgets('Clear resets the tag and favorites, not the query',
        (WidgetTester tester) async {
      await _pumpList(
        tester,
        recipes: <Recipe>[
          ...tagged,
          _pita.copyWith(id: 'r3', title: 'Pita sa jabukama'),
        ],
      );

      await tester.enterText(find.byType(TextField), 'pita');
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      await tester.tap(find.text('Brzo'));
      await tester.pumpAndSettle();
      expect(find.text('Pita sa sirom'), findsOneWidget);
      expect(find.text('Pita sa jabukama'), findsNothing);

      await tester.tap(find.widgetWithText(ActionChip, 'Clear'));
      await tester.pumpAndSettle();

      // Tag gone: both pitas back. Query kept: the torte stays out.
      expect(find.text('Pita sa sirom'), findsOneWidget);
      expect(find.text('Pita sa jabukama'), findsOneWidget);
      expect(find.text('Šargarepa torta'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        'pita',
      );
      final FilterChip favorites = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Favorites'),
      );
      expect(favorites.selected, isFalse);
    });

    testWidgets('the result count always shows above a non-empty list',
        (WidgetTester tester) async {
      await _pumpList(tester, recipes: tagged);
      expect(find.text('2 recipes'), findsOneWidget);

      await tester.tap(find.text('Posno'));
      await tester.pumpAndSettle();
      expect(find.text('1 recipe'), findsOneWidget);
    });

    testWidgets('the add menu opens from the app bar, not a FAB',
        (WidgetTester tester) async {
      await _pumpList(tester, recipes: tagged);

      expect(find.byType(FloatingActionButton), findsNothing);
      final Finder add = find.byTooltip('Add a recipe');
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.ancestor(of: add, matching: find.byType(IconButton)),
        ),
        findsOneWidget,
      );

      await tester.tap(add);
      await tester.pumpAndSettle();
      for (final String label in <String>[
        'New recipe',
        'Import from a link',
        'Paste a recipe',
        'Photograph a page',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
    });

    test('the count reads right in Serbian: 1 / 2 / 5', () {
      final AppLocalizations sr = lookupAppLocalizations(const Locale('sr'));
      expect(sr.recipeCount(1), '1 recept');
      expect(sr.recipeCount(2), '2 recepta');
      expect(sr.recipeCount(5), '5 recepata');
    });

    testWidgets('the no-results state with a filter on offers Clear filters, '
        'and it restores the list', (WidgetTester tester) async {
      await _pumpList(tester, recipes: tagged);

      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Brzo'));
      await tester.pumpAndSettle();

      expect(find.text('Try removing a filter to see more recipes.'),
          findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Clear filters'));
      await tester.pumpAndSettle();

      expect(find.text('Šargarepa torta'), findsOneWidget);
      expect(find.text('Pita sa sirom'), findsOneWidget);
    });

    testWidgets('a query alone that matches nothing gets no action',
        (WidgetTester tester) async {
      await _pumpList(tester, recipes: tagged);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      expect(find.textContaining('No recipes match'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('recipe detail', () {
    testWidgets('a matched line renders the catalog name, not the raw text',
        (WidgetTester tester) async {
      await _pumpDetail(tester, _detail);

      // D1: the cook typed the genitive `šargarepe`; the catalog says
      // `šargarepa`, and that is what a reader sees. The amount `200 g` sits
      // apart on the right (D127).
      expect(find.text('šargarepa'), findsOneWidget);
      expect(find.text('200 g'), findsOneWidget);
      expect(find.text('200 g šargarepe'), findsNothing);
    });

    testWidgets('an unmatched line renders exactly what was typed',
        (WidgetTester tester) async {
      await _pumpDetail(tester, _detail);

      // Rule 3: a failed match is a supported state, and the line survives it.
      // `textContaining`: the unmatched ring is a WidgetSpan inline after
      // the name.
      expect(find.textContaining('malo domaćeg sira'), findsOneWidget);
      expect(find.text('po ukusu'), findsOneWidget);
    });

    testWidgets('an unmatched line with an amount says it once, as typed', (
      WidgetTester tester,
    ) async {
      await _pumpDetail(
        tester,
        _detail.copyWith(
          ingredients: <RecipeIngredient>[
            RecipeIngredient(
              position: 0,
              rawText: '1,5 kg mlevenog mesa',
              quantity: Quantity.fraction(3, 2),
              unitCode: 'g',
            ),
          ],
        ),
      );

      // The raw text already carries `1,5 kg`; a second amount on the right
      // would say it twice.
      expect(find.textContaining('1,5 kg mlevenog mesa'), findsOneWidget);
      expect(find.byKey(const Key('ingredientAmount')), findsNothing);
    });

    testWidgets('an optional line whose note already says so gets no inline '
        'opciono', (WidgetTester tester) async {
      await _pumpDetail(tester, _detail);

      // The parser moved `po ukusu` into the note; `opciono` beside it too
      // would say the same thing twice.
      expect(find.textContaining('opciono'), findsNothing);
      expect(find.text('po ukusu'), findsOneWidget);
    });

    testWidgets('units render in the recipe\'s language, not as their code',
        (WidgetTester tester) async {
      await _pumpDetail(tester, _detail);

      expect(find.text('1 kašika'), findsOneWidget);
      expect(find.textContaining('tbsp'), findsNothing);
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

    testWidgets('the last ingredient line draws no divider under it',
        (WidgetTester tester) async {
      await _pumpDetail(tester, _detail);

      // Three lines, two dividers: `Recipe@1x.png` has none under the last.
      expect(
        find.byKey(const Key('ingredientDivider'), skipOffstage: false),
        findsNWidgets(2),
      );
    });

    testWidgets('a connector joins each step to the next',
        (WidgetTester tester) async {
      await _pumpDetail(
        tester,
        _detail.copyWith(
          steps: const <RecipeStep>[
            RecipeStep(position: 0, text: 'Zagrej rernu.'),
            RecipeStep(position: 1, text: 'Umuti jaja.'),
            RecipeStep(position: 2, text: 'Peci 40 minuta.'),
          ],
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Peci 40 minuta.'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      // Three steps, two connectors: none above step 1, none below the last.
      expect(
        find.byKey(const Key('stepConnector'), skipOffstage: false),
        findsNWidgets(2),
      );
    });

    testWidgets('a single step draws no connector',
        (WidgetTester tester) async {
      await _pumpDetail(tester, _detail);
      await tester.scrollUntilVisible(
        find.text('Zagrej rernu.'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Zagrej rernu.'), findsOneWidget);
      expect(
        find.byKey(const Key('stepConnector'), skipOffstage: false),
        findsNothing,
      );
    });

    testWidgets(
        'headings group the steps, notes sit between them, numbers continue',
        (WidgetTester tester) async {
      await _pumpDetail(
        tester,
        _detail.copyWith(
          steps: const <RecipeStep>[
            RecipeStep(
              position: 0,
              text: 'Za testo',
              kind: RecipeStepKind.heading,
            ),
            RecipeStep(position: 1, text: 'Umuti jaja.'),
            RecipeStep(position: 2, text: 'Dodaj brašno.'),
            RecipeStep(
              position: 3,
              text: 'Testo treba da bude meko.',
              kind: RecipeStepKind.note,
            ),
            RecipeStep(position: 4, text: 'Ostavi da odmori.'),
            RecipeStep(position: 5, text: 'Fil', kind: RecipeStepKind.heading),
            RecipeStep(position: 6, text: 'Umuti fil.'),
          ],
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Umuti fil.'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      // The discs count steps only and run on across the heading.
      final Iterable<String> discs = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byWidgetPredicate(
                (Widget w) =>
                    w is Container &&
                    w.decoration is BoxDecoration &&
                    (w.decoration! as BoxDecoration).shape == BoxShape.circle,
              ),
              matching: find.byType(Text),
            ),
          )
          .map((Text t) => t.data!);
      expect(discs, <String>['1', '2', '3', '4']);

      expect(find.text('Za testo'), findsOneWidget);
      expect(find.text('Fil'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('stepNotePanel')),
          matching: find.text('Testo treba da bude meko.'),
        ),
        findsOneWidget,
      );
      // Step 1 -> step 2, step 2 -> the note, the note -> step 3. Step 3
      // breaks at "Fil", and step 4 is last.
      expect(
        find.byKey(const Key('stepConnector'), skipOffstage: false),
        findsNWidgets(3),
      );
    });

    testWidgets('a translated method numbers by the source rows\' kinds',
        (WidgetTester tester) async {
      await _pumpDetail(
        tester,
        _detail.copyWith(
          readingLocale: 'en',
          steps: const <RecipeStep>[
            RecipeStep(
              position: 0,
              text: 'Za testo',
              kind: RecipeStepKind.heading,
            ),
            RecipeStep(position: 1, text: 'Umesiti testo.'),
            RecipeStep(
              position: 2,
              text: 'Može i dan ranije.',
              kind: RecipeStepKind.note,
            ),
            RecipeStep(position: 3, text: 'Razvući testo.'),
          ],
          translations: const <RecipeTranslation>[
            RecipeTranslation(
              locale: 'en',
              title: 'Carrot cake',
              // Prose only -- every translated row has the default kind.
              steps: <RecipeStep>[
                RecipeStep(position: 0, text: 'For the dough'),
                RecipeStep(position: 1, text: 'Knead the dough.'),
                RecipeStep(position: 2, text: 'It keeps a day ahead.'),
                RecipeStep(position: 3, text: 'Roll it out.'),
              ],
            ),
          ],
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Roll it out.'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      final Iterable<String> discs = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byWidgetPredicate(
                (Widget w) =>
                    w is Container &&
                    w.decoration is BoxDecoration &&
                    (w.decoration! as BoxDecoration).shape == BoxShape.circle,
              ),
              matching: find.byType(Text),
            ),
          )
          .map((Text t) => t.data!);
      expect(discs, <String>['1', '2']);
      expect(
        find.descendant(
          of: find.byKey(const Key('stepNotePanel')),
          matching: find.text('It keeps a day ahead.'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a note ending a group still carries the line into it',
        (WidgetTester tester) async {
      await _pumpDetail(
        tester,
        _detail.copyWith(
          steps: const <RecipeStep>[
            RecipeStep(position: 0, text: 'Umuti jaja.'),
            RecipeStep(
              position: 1,
              text: 'Ne preteruj.',
              kind: RecipeStepKind.note,
            ),
            RecipeStep(
              position: 2,
              text: 'Usamljena beleška.',
              kind: RecipeStepKind.note,
            ),
          ],
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Usamljena beleška.'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      // Step -> note, note -> note, and the last note's own stretch.
      expect(
        find.byKey(const Key('stepConnector'), skipOffstage: false),
        findsNWidgets(3),
      );
    });

    testWidgets('the end note renders as a card after the last step', (
      WidgetTester tester,
    ) async {
      await _pumpDetail(
        tester,
        _detail.copyWith(
          recipe: _torta.copyWith(notes: 'Čuva se tri dana u frižideru.'),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Čuva se tri dana u frižideru.'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.byIcon(Icons.edit_note), findsOneWidget);
      // The harness renders in English: `recipeNotesHeading` is `Notes`.
      expect(find.text('Notes'), findsOneWidget);
      final Finder card = find.ancestor(
        of: find.text('Čuva se tri dana u frižideru.'),
        matching: find.byType(Card),
      );
      expect(card, findsOneWidget);
      expect(
        tester.getTopLeft(card).dy,
        greaterThan(tester.getBottomLeft(find.text('Zagrej rernu.')).dy),
      );
    });

    for (final String? notes in <String?>[null, '   ']) {
      testWidgets(
        'no end note card for notes: ${notes == null ? 'null' : 'blank'}',
        (WidgetTester tester) async {
          await _pumpDetail(
            tester,
            _detail.copyWith(recipe: _torta.copyWith(notes: notes)),
          );

          expect(
            find.byIcon(Icons.edit_note, skipOffstage: false),
            findsNothing,
          );
          expect(find.text('Notes', skipOffstage: false), findsNothing);
        },
      );
    }

    testWidgets('steps, notes and the end note render the formatting subset; '
        'a heading stays literal (D165)', (WidgetTester tester) async {
      await _pumpDetail(
        tester,
        _detail.copyWith(
          recipe: _torta.copyWith(notes: 'Čuva se **tri** dana.'),
          steps: const <RecipeStep>[
            RecipeStep(
              position: 0,
              text: '**Za testo**',
              kind: RecipeStepKind.heading,
            ),
            RecipeStep(position: 1, text: 'Umuti **jaja**.'),
            RecipeStep(
              position: 2,
              text: 'Testo je *meko*.',
              kind: RecipeStepKind.note,
            ),
          ],
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Čuva se tri dana.'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Umuti jaja.', skipOffstage: false), findsOneWidget);
      expect(find.text('Testo je meko.', skipOffstage: false), findsOneWidget);
      expect(find.text('Čuva se **tri** dana.'), findsNothing);
      expect(find.text('**Za testo**', skipOffstage: false), findsOneWidget);
    });

    testWidgets('a translated recipe shows the translation\'s end note', (
      WidgetTester tester,
    ) async {
      await _pumpDetail(
        tester,
        _detail.copyWith(
          readingLocale: 'en',
          recipe: _torta.copyWith(notes: 'Čuva se tri dana.'),
          translations: const <RecipeTranslation>[
            RecipeTranslation(
              locale: 'en',
              title: 'Carrot cake',
              notes: 'Keeps three days.',
              steps: <RecipeStep>[
                RecipeStep(position: 0, text: 'Heat the oven.'),
              ],
            ),
          ],
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Keeps three days.'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Čuva se tri dana.', skipOffstage: false), findsNothing);
    });

    testWidgets('renders the recipe photo when the recipe has one',
        (WidgetTester tester) async {
      await _pumpDetail(
        tester,
        _detail.copyWith(
          recipe: _torta.copyWith(
            imagePath: 'h1/torta.jpg',
            imageUrl: 'https://example.test/torta.jpg',
          ),
        ),
      );

      final CachedNetworkImage image =
          tester.widget(find.byType(CachedNetworkImage));
      expect(image.imageUrl, 'https://example.test/torta.jpg');
      expect(image.cacheKey, 'h1/torta.jpg');
    });

    testWidgets('a recipe with no photo still gets the well, with a '
        'placeholder in it', (WidgetTester tester) async {
      await _pumpDetail(tester, _detail);

      // Phase 7 part 3: the hero used to be omitted entirely, so the screen
      // started somewhere different depending on whether a recipe had a
      // picture. A missing picture is not a failure (rule 3's spirit), so
      // the well renders with a quiet placeholder rather than a broken-image
      // icon.
      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
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

    // Phase 7 part 3's device walk found stars three, four and five off the
    // right edge of a real phone: `app_theme.dart`'s `iconButtonTheme` sets a
    // 48dp minimum, which `padding: zero` and `constraints: BoxConstraints()`
    // do not override, so five stars wanted ~220dp inside a quarter-width
    // column. Nobody could rate a recipe above 2. The old tests all pumped at
    // 800x600, where a 220dp row simply fits -- so this one pumps a phone.
    testWidgets('all five stars stay inside the stat strip at phone width',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3; // 360 x 780 logical -- a small phone
      addTearDown(tester.view.reset);

      await _pumpDetail(
        tester,
        _detail.copyWith(
          recipe: _torta.copyWith(
            servings: 8,
            prepMinutes: 30,
            cookMinutes: 45,
            rating: 3,
          ),
        ),
      );

      final Finder stars = find.byKey(const Key('ratingStars'));
      final double screenWidth = tester.view.physicalSize.width /
          tester.view.devicePixelRatio;

      // Every star is on screen...
      for (final Finder star in <Finder>[
        find.descendant(of: stars, matching: find.byIcon(Icons.star)),
        find.descendant(of: stars, matching: find.byIcon(Icons.star_border)),
      ]) {
        for (final Element e in star.evaluate()) {
          final Rect box = tester.getRect(find.byWidget(e.widget));
          expect(box.right, lessThanOrEqualTo(screenWidth),
              reason: 'a star ran off the right edge');
          expect(box.left, greaterThanOrEqualTo(0));
        }
      }

      // ...and all five are still there, with the fourth column intact.
      expect(
        find.descendant(of: stars, matching: find.byIcon(Icons.star)),
        findsNWidgets(3),
      );
      expect(
        find.descendant(of: stars, matching: find.byIcon(Icons.star_border)),
        findsNWidgets(2),
      );
      expect(tester.takeException(), isNull);
    });

    // Being on screen is not quite the claim; the claim is that a tap on the
    // fifth star reaches the fifth star. This hit-tests rather than tapping,
    // because a real tap runs `_setRating` into the repository and this suite
    // stubs no Supabase client -- reachability is what the walk found broken,
    // and reachability is what this asserts.
    testWidgets('a tap on the fifth star reaches it at phone width',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await _pumpDetail(
        tester,
        _detail.copyWith(
          recipe: _torta.copyWith(
            servings: 8,
            prepMinutes: 30,
            cookMinutes: 45,
          ),
        ),
      );

      final Finder fifth = find
          .descendant(
            of: find.byKey(const Key('ratingStars')),
            matching: find.byIcon(Icons.star_border),
          )
          .last;
      final RenderObject target = tester.renderObject(fifth);
      final HitTestResult result =
          tester.hitTestOnBinding(tester.getCenter(fifth));

      expect(
        result.path.any((HitTestEntry<HitTestTarget> e) => e.target == target),
        isTrue,
        reason: 'the fifth star did not receive the hit at its own centre',
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

    // Phase 6, part 1a.
    testWidgets('a tag with a translated pair renders in the reader\'s '
        'language', (WidgetTester tester) async {
      await _pumpDetail(
        tester,
        _detail.copyWith(
          readingLocale: 'en',
          recipe: _torta.copyWith(tags: <String>['Posno']),
        ),
        tagLabels: <String, String>{'posno': 'Lenten'},
      );

      expect(find.text('Lenten'), findsOneWidget);
      expect(find.text('Posno'), findsNothing);
    });

    testWidgets('a tag with no pair renders exactly as typed',
        (WidgetTester tester) async {
      await _pumpDetail(
        tester,
        _detail.copyWith(
          readingLocale: 'en',
          recipe: _torta.copyWith(tags: <String>['Brzo']),
        ),
        tagLabels: <String, String>{'posno': 'Lenten'},
      );

      expect(find.text('Brzo'), findsOneWidget);
    });

    // Phase 7 part 17: the frame's servings trailer beside the heading.
    testWidgets('the Ingredients heading says how many it serves',
        (WidgetTester tester) async {
      await _pumpDetail(tester, _detail.copyWith(readingLocale: 'en'));

      expect(find.text('for 8 servings'), findsOneWidget);
    });

    // Phase 8 round 2: ingredient section headings (A4·3).
    testWidgets('sections get a primary heading above their first line',
        (WidgetTester tester) async {
      await _pumpDetail(
        tester,
        _detail.copyWith(ingredients: _sectionedLines),
      );

      expect(find.text('Za testo'), findsOneWidget);
      expect(find.text('Za fil'), findsOneWidget);
      double top(String text) =>
          tester.getTopLeft(find.textContaining(text, findRichText: true)).dy;
      expect(top('Za testo'), lessThan(top('brašno')));
      expect(top('brašno'), lessThan(top('jaja')));
      expect(top('jaja'), lessThan(top('Za fil')));
      expect(top('Za fil'), lessThan(top('sir')));

      final BuildContext context = tester.element(find.text('Za testo'));
      final Color primary = Theme.of(context).colorScheme.primary;
      expect(tester.widget<Text>(find.text('Za testo')).style?.color, primary);
      expect(tester.widget<Text>(find.text('Za fil')).style?.color, primary);
    });

    testWidgets('a section\'s last line draws no divider',
        (WidgetTester tester) async {
      await _pumpDetail(
        tester,
        _detail.copyWith(ingredients: _sectionedLines),
      );

      expect(
        tester
            .widgetList<IngredientLineRow>(
              find.byType(IngredientLineRow, skipOffstage: false),
            )
            .map((IngredientLineRow row) => row.showDivider),
        <bool>[true, false, true, false],
      );
    });

    testWidgets('a flat list gets no section heading and one closing line',
        (WidgetTester tester) async {
      await _pumpDetail(tester, _detail);

      final BuildContext context = tester.element(find.byType(Scaffold));
      final ThemeData theme = Theme.of(context);
      final Iterable<Text> headings = tester
          .widgetList<Text>(find.byType(Text, skipOffstage: false))
          .where(
            (Text t) =>
                t.style?.color == theme.colorScheme.primary &&
                t.style?.fontSize == theme.textTheme.titleSmall?.fontSize &&
                t.style?.fontWeight == theme.textTheme.titleSmall?.fontWeight,
          );
      expect(headings, isEmpty);
      expect(
        tester
            .widgetList<IngredientLineRow>(
              find.byType(IngredientLineRow, skipOffstage: false),
            )
            .map((IngredientLineRow row) => row.showDivider),
        <bool>[true, true, false],
      );
    });

    testWidgets('lines before the first section have no heading',
        (WidgetTester tester) async {
      await _pumpDetail(
        tester,
        _detail.copyWith(
          ingredients: const <RecipeIngredient>[
            RecipeIngredient(position: 0, rawText: 'so'),
            RecipeIngredient(position: 1, rawText: 'sir', section: 'Za fil'),
          ],
        ),
      );

      double top(String text) =>
          tester.getTopLeft(find.textContaining(text, findRichText: true)).dy;
      expect(find.text('Za fil'), findsOneWidget);
      expect(top('so'), lessThan(top('Za fil')));
      expect(top('Za fil'), lessThan(top('sir')));
      expect(
        tester
            .widgetList<IngredientLineRow>(
              find.byType(IngredientLineRow, skipOffstage: false),
            )
            .map((IngredientLineRow row) => row.showDivider),
        <bool>[false, false],
      );
    });

    testWidgets('a run of lines in one section gets one heading',
        (WidgetTester tester) async {
      await _pumpDetail(
        tester,
        _detail.copyWith(
          ingredients: const <RecipeIngredient>[
            RecipeIngredient(position: 0, rawText: 'brašno', section: 'Za testo'),
            RecipeIngredient(position: 1, rawText: 'jaja', section: 'Za testo '),
            RecipeIngredient(position: 2, rawText: 'mleko', section: 'Za testo'),
          ],
        ),
      );

      expect(find.textContaining('Za testo'), findsOneWidget);
    });

    testWidgets('no servings, no trailer on the Ingredients heading',
        (WidgetTester tester) async {
      await _pumpDetail(
        tester,
        _detail.copyWith(
          readingLocale: 'en',
          recipe: _torta.copyWith(servings: null),
        ),
      );

      expect(find.textContaining('serving'), findsNothing);
    });

    // Design round 4: the Ingredients heading and its rows sit on one card.
    testWidgets('the ingredients sit on a card; the Steps heading does not',
        (WidgetTester tester) async {
      await _pumpDetail(
        tester,
        _detail.copyWith(ingredients: _sectionedLines),
      );

      Element cardOf(Finder of) =>
          tester.element(find.ancestor(of: of, matching: find.byType(Card)));
      // The harness renders in English.
      final Element card = cardOf(find.text('Ingredients'));
      expect(cardOf(find.text('Za testo')), same(card));
      expect(cardOf(find.text('Za fil')), same(card));
      expect(
        cardOf(find.textContaining('brašno', findRichText: true)),
        same(card),
      );
      expect(
        cardOf(find.textContaining('pavlaka', findRichText: true)),
        same(card),
      );
      expect(
        find.ancestor(
          of: find.text('Steps', skipOffstage: false),
          matching: find.byType(Card),
        ),
        findsNothing,
      );
    });

    testWidgets('with no ingredients, the empty text sits on the card',
        (WidgetTester tester) async {
      await _pumpDetail(
        tester,
        _detail.copyWith(ingredients: const <RecipeIngredient>[]),
      );

      Element cardOf(Finder of) =>
          tester.element(find.ancestor(of: of, matching: find.byType(Card)));
      expect(
        cardOf(find.text('No ingredients yet.')),
        same(cardOf(find.text('Ingredients'))),
      );
    });

    testWidgets('a URL import\'s source line is the lead-in and the host, '
        'on one line', (WidgetTester tester) async {
      await _pumpDetail(
        tester,
        _detail.copyWith(
          readingLocale: 'en',
          recipe: _torta.copyWith(
            sourceType: RecipeSourceType.urlImport,
            sourceUrl: 'https://www.kuvajmo.rs/punjene-paprike',
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.byIcon(Icons.link),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Imported from a link · kuvajmo.rs'), findsOneWidget);
      expect(find.textContaining('https://'), findsNothing);
    });

    testWidgets('an attribution replaces the host on the source line',
        (WidgetTester tester) async {
      await _pumpDetail(
        tester,
        _detail.copyWith(
          readingLocale: 'en',
          recipe: _torta.copyWith(
            sourceType: RecipeSourceType.urlImport,
            sourceUrl: 'https://www.kuvajmo.rs/punjene-paprike',
            sourceAttribution: 'Kuvajmo',
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.byIcon(Icons.link),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Imported from a link · Kuvajmo'), findsOneWidget);
      expect(find.textContaining('kuvajmo.rs'), findsNothing);
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

    // Phase 7 part 17: a badge, not a chip -- nothing taps it.
    testWidgets('the Machine translation caveat is a tonal badge, not a Chip',
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

      final Finder label = find.text('Machine translation');
      expect(
        find.ancestor(of: label, matching: find.byType(Chip)),
        findsNothing,
      );
      expect(
        find.ancestor(of: label, matching: find.byType(AppBadge)),
        findsOneWidget,
      );
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

  // Phase 5, part 3: the overflow menu's "Add to meal plan..." entry point,
  // mirroring `meal_plan_screen_test.dart`'s own snack-warning-then-write
  // coverage of `_SlotRow._add` / `_confirmRepeat`.
  group('add to meal plan', () {
    testWidgets('the menu item renders', (WidgetTester tester) async {
      await _pumpDetail(tester, _detail);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Add to meal plan...'), findsOneWidget);
    });

    testWidgets(
        'picking a day and slot calls addRecipe with exactly that date and '
        'slot', (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await _pumpDetail(tester, _detail, writer: _StubWriter(calls));

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to meal plan...'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Lunch'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ListTile).at(2));
      await tester.pumpAndSettle();

      final DateTime now = DateTime.now();
      final DateTime expected = DateTime(now.year, now.month, now.day + 2);

      expect(calls.addedRecipe, isNotNull);
      expect(calls.addedRecipe!.recipeId, 'r1');
      expect(calls.addedRecipe!.date, expected);
      expect(calls.addedRecipe!.slot, MealSlot.lunch);
    });

    testWidgets('a non-snack slot never calls snackRepeatCount, and adds '
        'immediately', (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await _pumpDetail(tester, _detail,
          writer: _StubWriter(calls, repeatCount: 99));

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to meal plan...'));
      await tester.pumpAndSettle();

      // Dinner is the sheet's default slot -- no chip tap needed.
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      expect(calls.snackRepeatCountCalled, isFalse);
      expect(find.text('Already planned recently'), findsNothing);
      expect(calls.addedRecipe, isNotNull);
      expect(calls.addedRecipe!.slot, MealSlot.dinner);
    });

    testWidgets('a repeated snack slot warns, and Cancel writes nothing',
        (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await _pumpDetail(tester, _detail,
          writer: _StubWriter(calls, repeatCount: 2));

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to meal plan...'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Snack'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      expect(calls.snackRepeatCountCalled, isTrue);
      expect(find.text('Already planned recently'), findsOneWidget);
      expect(find.text('Already in 2 snack slots this fortnight.'),
          findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(calls.addedRecipe, isNull);
    });

    testWidgets('a repeated snack slot, then Add anyway calls addRecipe',
        (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await _pumpDetail(tester, _detail,
          writer: _StubWriter(calls, repeatCount: 2));

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to meal plan...'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Snack'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Add anyway'));
      await tester.pumpAndSettle();

      expect(calls.addedRecipe, isNotNull);
      expect(calls.addedRecipe!.slot, MealSlot.snack);
    });

    testWidgets('an AppFailure from the writer renders a snackbar',
        (WidgetTester tester) async {
      await _pumpDetail(tester, _detail, writer: _ThrowingWriter());

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to meal plan...'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      expect(find.text('You are not in a household yet.'), findsOneWidget);
    });
  });

  // phase9-household-switch-loading -- between a switch and its data.
  group('household switch', () {
    testWidgets('mid-switch: the placeholder and the bar, nothing of the old '
        'household, + disabled; then the new recipes', (
      WidgetTester tester,
    ) async {
      final HeldHouseholdRepository repo =
          HeldHouseholdRepository(<Household>[_homeHousehold, _weekend]);
      final ProviderContainer container = await _pumpSwitchable(tester, repo);
      expect(find.text('Šargarepa torta'), findsOneWidget);
      expect(_chip('dessert'), findsOneWidget);

      repo.currentHold = Completer<void>();
      final Future<void> switching = container
          .read(currentHouseholdProvider.notifier)
          .switchTo('weekend');
      await tester.pump();
      await tester.pump();

      expect(find.byType(HouseholdSwitchPlaceholder), findsOneWidget);
      expect(find.byType(HouseholdSwitchProgressBar), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Šargarepa torta'), findsNothing);
      expect(find.byType(FilterChip), findsNothing);
      expect(_addButton(tester).onPressed, isNull);

      repo.currentHold!.complete();
      await switching;
      await tester.pumpAndSettle();
      expect(find.byType(HouseholdSwitchPlaceholder), findsNothing);
      expect(find.byType(HouseholdSwitchProgressBar), findsNothing);
      expect(find.text('Pita sa sirom'), findsOneWidget);
      expect(_addButton(tester).onPressed, isNotNull);
    });

    testWidgets('a switch clears the tag filter', (WidgetTester tester) async {
      final HeldHouseholdRepository repo =
          HeldHouseholdRepository(<Household>[_homeHousehold, _weekend]);
      final ProviderContainer container = await _pumpSwitchable(tester, repo);
      await tester.tap(_chip('dessert'));
      await tester.pumpAndSettle();

      // Held across a frame, as the real network-first re-read always is:
      // a derived provider sees only what lasts until the next frame.
      repo.currentHold = Completer<void>();
      final Future<void> switching = container
          .read(currentHouseholdProvider.notifier)
          .switchTo('weekend');
      await tester.pump();
      repo.currentHold!.complete();
      await switching;
      await tester.pumpAndSettle();

      // Pita has no `dessert` tag: it shows only with the filter gone.
      expect(find.text('Pita sa sirom'), findsOneWidget);
    });

    testWidgets('one household: the first load is still the spinner', (
      WidgetTester tester,
    ) async {
      final HeldHouseholdRepository repo =
          HeldHouseholdRepository(<Household>[_homeHousehold])
            ..currentHold = Completer<void>();
      await _pumpSwitchable(tester, repo, settle: false);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(HouseholdSwitchPlaceholder), findsNothing);
      expect(find.byType(HouseholdSwitchProgressBar), findsNothing);

      repo.currentHold!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Šargarepa torta'), findsOneWidget);
      expect(find.byType(HouseholdSwitchPlaceholder), findsNothing);
    });
  });
}

const Household _homeHousehold =
    Household(id: 'h1', name: 'Kod Mire', createdBy: 'u1');
const Household _weekend =
    Household(id: 'weekend', name: 'Vikendica', createdBy: 'u1');

/// [recipeListProvider] answering per household, the way the real one keys
/// on `currentHouseholdIdProvider`.
class _HouseholdRecipeList extends RecipeList {
  @override
  Stream<List<Recipe>> build({
    String query = '',
    String tag = '',
    bool favoritesOnly = false,
  }) async* {
    final String? id = await ref.watch(currentHouseholdIdProvider.future);
    yield RecipeFilter.apply(
      id == 'h1'
          ? const <Recipe>[
              Recipe(
                id: 'r1',
                householdId: 'h1',
                title: 'Šargarepa torta',
                originalLocale: 'sr',
                sourceType: RecipeSourceType.manual,
                status: RecipeStatus.tested,
                createdBy: 'u1',
                tags: <String>['dessert'],
              ),
            ]
          : <Recipe>[_pita.copyWith(householdId: 'weekend')],
      query: query,
      tag: tag,
      favoritesOnly: favoritesOnly,
    );
  }
}

Future<ProviderContainer> _pumpSwitchable(
  WidgetTester tester,
  HeldHouseholdRepository repo, {
  bool settle = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...householdSwitchOverrides(repo),
        recipeListProvider.overrideWith2((_) => _HouseholdRecipeList()),
        recipeImageCacheManagerProvider.overrideWithValue(FakeImageCache()),
        appLocaleProvider.overrideWith((Ref ref) => const Locale('sr')),
        tagLabelsProvider('sr').overrideWith(
          (Ref ref) async => const <String, String>{},
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
        home: const RecipeListScreen(),
      ),
    ),
  );
  final ProviderContainer container = ProviderScope.containerOf(
    tester.element(find.byType(RecipeListScreen)),
  );
  container.listen(currentUserIdProvider, (_, _) {});
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return container;
}

Finder _chip(String label) => find.widgetWithText(FilterChip, label);

IconButton _addButton(WidgetTester tester) => tester.widget<IconButton>(
  find.ancestor(of: find.byIcon(Icons.add), matching: find.byType(IconButton)),
);


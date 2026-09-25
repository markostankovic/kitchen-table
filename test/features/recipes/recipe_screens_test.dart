import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/error/app_failure.dart';
import 'package:kitchen_table/core/l10n/app_locale.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations.dart';
import 'package:kitchen_table/core/meal_plan/meal_plan_writer.dart';
import 'package:kitchen_table/core/recipes/widgets/recipe_card.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/core/widgets/app_badge.dart';
import 'package:kitchen_table/core/widgets/app_meta_row.dart';
import 'package:kitchen_table/core/widgets/app_monogram_tile.dart';
import 'package:kitchen_table/features/ingredients/domain/ingredient_match.dart';
import 'package:kitchen_table/features/ingredients/domain/quantity.dart';
import 'package:kitchen_table/features/ingredients/domain/unit.dart';
import 'package:kitchen_table/features/ingredients/domain/unit_catalog.dart';
import 'package:kitchen_table/core/ingredients/ingredient_catalog_providers.dart';
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

  group('recipe detail', () {
    testWidgets('a matched line renders the catalog name, not the raw text',
        (WidgetTester tester) async {
      await _pumpDetail(tester, _detail);

      // D1: the cook typed the genitive `šargarepe`; the catalog says
      // `šargarepa`, and that is what a reader sees. Unit and name are one
      // run of text since Phase 7 part 3 -- `g šargarepa` reads as one
      // phrase, with the quantity alone in its own column.
      expect(find.text('g šargarepa'), findsOneWidget);
      expect(find.text('200'), findsOneWidget);
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

      expect(find.text('kašika ajvar'), findsOneWidget);
      expect(find.textContaining('tbsp'), findsNothing);
      // Grams are spelled the same either way.
      expect(find.text('g šargarepa'), findsOneWidget);
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
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/l10n/app_locale.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations.dart';
import 'package:kitchen_table/core/recipes/widgets/recipe_card.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/core/widgets/app_badge.dart';
import 'package:kitchen_table/core/widgets/app_meta_row.dart';
import 'package:kitchen_table/core/widgets/app_monogram_tile.dart';
import 'package:kitchen_table/features/recipes/domain/recipe.dart';

const Recipe _torta = Recipe(
  id: 'r1',
  householdId: 'h1',
  title: 'Šargarepa torta',
  originalLocale: 'sr',
  sourceType: RecipeSourceType.manual,
  status: RecipeStatus.tested,
  createdBy: 'u1',
);

Future<void> _pump(
  WidgetTester tester,
  Recipe recipe, {
  VoidCallback? onTap,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: appSupportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (BuildContext context) => RecipeCard(
          recipe: recipe,
          l10n: AppLocalizations.of(context),
          onTap: onTap ?? () {},
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('shows the title and opens on tap', (WidgetTester tester) async {
    bool tapped = false;
    await _pump(tester, _torta, onTap: () => tapped = true);

    expect(find.text('Šargarepa torta'), findsOneWidget);
    await tester.tap(find.byType(RecipeCard));
    expect(tapped, isTrue);
  });

  testWidgets('a recipe with no photo gets a monogram of its first letter', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _torta);

    expect(find.byType(AppMonogramTile), findsOneWidget);
    expect(find.text('Š'), findsOneWidget);
  });

  testWidgets('each fact is its own meta item, with no separators between '
      'them', (WidgetTester tester) async {
    await _pump(
      tester,
      _torta.copyWith(servings: 8, prepMinutes: 30, cookMinutes: 45, rating: 4),
    );

    expect(find.byType(AppMetaRow), findsOneWidget);
    expect(find.byType(AppMetaItem), findsNWidgets(4));
    // The ` · `-joined run is the defect the meta row exists to kill.
    expect(find.textContaining('·'), findsNothing);
    expect(find.textContaining('★'), findsNothing);
  });

  testWidgets('only the facts a recipe actually has', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _torta.copyWith(servings: 8));

    expect(find.byType(AppMetaItem), findsOneWidget);
  });

  testWidgets('a draft is badged, a tested recipe is not', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _torta);
    expect(find.byType(AppBadge), findsNothing);

    await _pump(tester, _torta.copyWith(status: RecipeStatus.draft));
    expect(find.widgetWithText(AppBadge, 'Draft'), findsOneWidget);
  });

  // Phase 7 part 3 split the star's two meanings: favourite is a heart,
  // a star is a rating, and nothing carries both jobs any more.
  testWidgets('a favourite gets a heart, in the favorite colour', (
    WidgetTester tester,
  ) async {
    final ThemeData theme = AppTheme.light();
    await _pump(tester, _torta.copyWith(isFavorite: true));

    final Icon heart = tester.widget<Icon>(find.byIcon(Icons.favorite));
    expect(heart.color, theme.colorScheme.tertiary);
    expect(find.byIcon(Icons.star), findsNothing);
  });

  testWidgets('a rating gets a star and a bare number', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _torta.copyWith(rating: 4));

    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.widgetWithText(AppMetaItem, '4'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsNothing);
  });

  testWidgets('a long Serbian title runs to two lines and still holds its '
      'heart', (WidgetTester tester) async {
    await _pump(
      tester,
      _torta.copyWith(
        title: 'Punjene paprike sa pirinčem i mlevenim mesom',
        isFavorite: true,
        servings: 6,
      ),
    );

    final Text title = tester.widget<Text>(
      find.text('Punjene paprike sa pirinčem i mlevenim mesom'),
    );
    expect(title.maxLines, 2);
    expect(title.overflow, TextOverflow.ellipsis);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

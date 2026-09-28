import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/ingredients/widgets/ingredient_match_chip.dart';
import 'package:kitchen_table/core/l10n/app_locale.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/features/ingredients/domain/ingredient_match.dart';
import 'package:kitchen_table/features/ingredients/domain/unit_catalog.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_draft.dart';

/// The chip's status words are UI chrome and follow the *reader*; the name
/// inside a suggestion is whatever the search returned in the *recipe's*
/// locale (D86). Part 6's walk found `Nema poklapanja` under an English
/// reader -- these pin the split.
Future<void> _pump(
  WidgetTester tester, {
  required Locale appLocale,
  required String recipeLocale,
  IngredientMatch? suggestion,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: appLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: appSupportedLocales,
      home: Scaffold(
        body: IngredientMatchChip(
          line: const RecipeDraftLine(localId: 1, rawText: 'šargarepa'),
          units: UnitCatalog.empty(),
          locale: recipeLocale,
          suggestion: suggestion,
          onTap: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an unmatched line on a Serbian recipe reads No match to an '
      'English reader', (WidgetTester tester) async {
    await _pump(tester, appLocale: const Locale('en'), recipeLocale: 'sr');

    expect(find.text('No match'), findsOneWidget);
    expect(find.text('Nema poklapanja'), findsNothing);
  });

  testWidgets('and Nema poklapanja to a Serbian one', (
    WidgetTester tester,
  ) async {
    await _pump(tester, appLocale: srLatn, recipeLocale: 'sr');

    expect(find.text('Nema poklapanja'), findsOneWidget);
  });

  testWidgets('a suggestion wraps the recipe-locale name in the reader\'s '
      'words, with the label in onSurfaceVariant and the icon in outline', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      appLocale: const Locale('en'),
      recipeLocale: 'sr',
      suggestion: const IngredientMatch(
        ingredientId: 'i1',
        displayName: 'šargarepa',
        matchedName: 'šargarepa',
        matchedLocale: 'sr',
        matchMethod: MatchMethod.fuzzy,
        confidence: 0.6,
        autoAccept: false,
      ),
    );

    final String expected = lookupAppLocalizations(const Locale('en'))
        .ingredientSuggestionLabel('šargarepa');
    expect(find.text(expected), findsOneWidget);

    final ColorScheme colors = AppTheme.light().colorScheme;
    final Text label = tester.widget<Text>(find.text(expected));
    expect(label.style?.color, colors.onSurfaceVariant);
    final Icon icon = tester.widget<Icon>(find.byIcon(Icons.help_outline));
    expect(icon.color, colors.outline);
  });
}

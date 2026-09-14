import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/l10n/app_locale.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations.dart';
import 'package:kitchen_table/features/recipes/application/translation_reviewer.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_step.dart';
import 'package:kitchen_table/features/recipes/domain/translation_review_draft.dart';
import 'package:kitchen_table/features/recipes/presentation/translation_review_screen.dart';

/// The notifier is overridden, not mocked -- `recipe_edit_screen_test.dart`'s
/// own house pattern. Only `build` is replaced.
class _StubReviewer extends TranslationReviewer {
  _StubReviewer(this.initial);

  final TranslationReviewDraft initial;

  @override
  Future<TranslationReviewDraft> build(
    String recipeId, {
    required String locale,
  }) async =>
      initial;
}

final TranslationReviewDraft _draft = TranslationReviewDraft(
  locale: 'en',
  sourceLocale: 'sr',
  sourceTitle: 'Šargarepa torta',
  sourceDescription: 'Vlažna torta sa šargarepom.',
  sourceSteps: const <RecipeStep>[
    RecipeStep(position: 0, text: 'Umutiti sastojke.'),
    RecipeStep(position: 1, text: 'Peći 40 minuta.'),
  ],
  title: 'Carrot cake',
  description: 'A moist carrot cake.',
  steps: const <RecipeStep>[
    RecipeStep(position: 0, text: 'Mix the ingredients.'),
    RecipeStep(position: 1, text: 'Bake for 40 minutes.'),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  required TranslationReviewDraft draft,
}) async {
  // The form is taller than the default 800x600 test surface, and a
  // ListView does not build what is below the fold --
  // `recipe_edit_screen_test.dart`'s own fix for the same symptom.
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // The screen reads appLocaleProvider to pick the locale it asks
        // the reviewer family for -- pin it to draft.locale so the two
        // agree, the same fix recipe_screens_test.dart's _pumpDetail needed.
        appLocaleProvider.overrideWith((Ref ref) => Locale(draft.locale)),
        translationReviewerProvider('r1', locale: draft.locale)
            .overrideWith(() => _StubReviewer(draft)),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
        home: TranslationReviewScreen(recipeId: 'r1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('both the source and the translated text are on screen',
      (WidgetTester tester) async {
    await _pump(tester, draft: _draft);

    // Title.
    expect(find.text('Šargarepa torta'), findsOneWidget);
    expect(find.text('Carrot cake'), findsOneWidget);
    // Description.
    expect(find.text('Vlažna torta sa šargarepom.'), findsOneWidget);
    expect(find.text('A moist carrot cake.'), findsOneWidget);
    // Each step, source and translated.
    expect(find.text('Umutiti sastojke.'), findsOneWidget);
    expect(find.text('Mix the ingredients.'), findsOneWidget);
    expect(find.text('Peći 40 minuta.'), findsOneWidget);
    expect(find.text('Bake for 40 minutes.'), findsOneWidget);
  });

  testWidgets('exactly one editable field per source step, and no more',
      (WidgetTester tester) async {
    await _pump(tester, draft: _draft);

    // Title + description + two steps = 4 editable fields. If someone
    // "helpfully" wired in the recipe editor's step section, this count
    // would be higher, or a text field would appear for a step that has
    // no source counterpart.
    expect(find.byType(TextFormField), findsNWidgets(4));
  });

  testWidgets('no add/remove step affordance, no reorder, no ingredients',
      (WidgetTester tester) async {
    await _pump(tester, draft: _draft);

    expect(find.text('Add step'), findsNothing);
    expect(find.text('Add ingredient'), findsNothing);
    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byIcon(Icons.drag_handle), findsNothing);
    expect(find.byType(ReorderableListView), findsNothing);
  });

  testWidgets('a blank title blocks save, and the repository is never reached',
      (WidgetTester tester) async {
    await _pump(tester, draft: _draft);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title').first,
      '   ',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save and approve'));
    await tester.pumpAndSettle();

    // The validator stopped it before save() was ever called; had it not,
    // this test would have thrown reaching an uninitialised Supabase client.
    expect(find.text('Enter a title.'), findsOneWidget);
  });

  testWidgets('a translation with no description shows no description field',
      (WidgetTester tester) async {
    final TranslationReviewDraft withoutDescription = TranslationReviewDraft(
      locale: 'en',
      sourceLocale: 'sr',
      sourceTitle: 'Šargarepa torta',
      title: 'Carrot cake',
    );
    await _pump(tester, draft: withoutDescription);

    // Just the title field -- no description field to edit a null into.
    expect(find.byType(TextFormField), findsOneWidget);
  });
}

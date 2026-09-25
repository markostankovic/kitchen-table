// The confirm screen (D8), driven through the real notifier with the job and
// the catalog stubbed by provider override -- no mocking package (rule 8).
//
// No test presses Save. `save()` writes aliases and calls
// save_imported_recipe, both of which reach the network; the SQL test covers
// the server half and the end-to-end run covers the join.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchen_table/core/ingredients/ingredient_catalog_providers.dart';
import 'package:kitchen_table/core/ingredients/widgets/ingredient_line_field.dart';
import 'package:kitchen_table/core/ingredients/widgets/ingredient_line_row.dart';
import 'package:kitchen_table/core/l10n/app_locale.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations_sr.dart';
import 'package:kitchen_table/core/router/routes.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/core/widgets/app_empty_state.dart';
import 'package:kitchen_table/features/import/application/import_providers.dart';
import 'package:kitchen_table/features/import/data/import_repository.dart';
import 'package:kitchen_table/features/import/domain/import_job.dart';
import 'package:kitchen_table/features/import/domain/parsed_recipe.dart';
import 'package:kitchen_table/features/import/presentation/import_review_screen.dart';
import 'package:kitchen_table/features/ingredients/domain/ingredient_line_parser.dart';
import 'package:kitchen_table/features/ingredients/domain/ingredient_match.dart';
import 'package:kitchen_table/features/ingredients/domain/unit.dart';
import 'package:kitchen_table/features/ingredients/domain/unit_catalog.dart';

const String _jobId = 'job-1';

final UnitCatalog _units = UnitCatalog(
  units: const <Unit>[
    Unit(code: 'g', family: UnitFamily.mass, toBase: 1, isMetric: true),
  ],
  aliases: const <String, String>{'g': 'g'},
  displayNames: const <String, String>{'g|sr': 'g'},
);

ParsedRecipe _parsed() => const ParsedRecipe(
  title: 'Šargarepa torta',
  originalLocale: ParsedLocale.SR,
  ingredients: <ParsedIngredientLine>[
    ParsedIngredientLine(
      rawText: '200 g šargarepe',
      name: 'šargarepe',
      ingredientId: 'ing-1',
      displayName: 'šargarepa',
      matchMethod: ParsedMatchMethod.ALIAS,
      matchConfidence: 1,
      autoAccept: true,
      isOptional: false,
    ),
    ParsedIngredientLine(
      rawText: '1 kesica praška za pecivo',
      name: 'praška za pecivo',
      ingredientId: 'ing-2',
      displayName: 'prašak za pecivo',
      matchMethod: ParsedMatchMethod.LLM,
      matchConfidence: 0.8,
      autoAccept: false,
      isOptional: false,
    ),
    ParsedIngredientLine(
      rawText: 'za posluživanje',
      name: 'za posluživanje',
      autoAccept: false,
      isOptional: false,
    ),
  ],
  steps: <ParsedStep>[ParsedStep(text: 'Zagrejati rernu.')],
);

/// `implements`, not `extends` -- the house style (household_screen_test):
/// anything unstubbed throws, so a test that reaches the network fails loudly.
class _FakeImportRepo implements ImportRepository {
  final List<String> dismissed = <String>[];

  @override
  Future<void> dismiss(String jobId) async => dismissed.add(jobId);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not stubbed: ${invocation.memberName}');
}

const String _landedOnRecipes = 'landed on the recipe list';

Future<void> _pump(
  WidgetTester tester,
  ImportJob job, {
  // The waiting states show a CircularProgressIndicator, which animates
  // forever -- pumpAndSettle would never return.
  bool settle = true,
  Locale? locale,
  // The form is taller than the default 800x600 surface, and a ListView does
  // not build what is below the fold.
  Size surface = const Size(1200, 3000),
  _FakeImportRepo? repo,
}) async {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  // A real router, because Discard ends in `RecipesRoute().go(context)`.
  final GoRouter router = GoRouter(
    initialLocation: '/review',
    routes: <RouteBase>[
      GoRoute(
        path: '/review',
        builder: (_, _) => const ImportReviewScreen(jobId: _jobId),
      ),
      GoRoute(
        path: RecipesRoute.path,
        builder: (_, _) => const Scaffold(body: Text(_landedOnRecipes)),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        importJobProvider.overrideWith(
          (Ref ref, String jobId) => Stream<ImportJob>.value(job),
        ),
        importRepositoryProvider.overrideWithValue(repo ?? _FakeImportRepo()),
        unitCatalogProvider.overrideWith((Ref ref) async => _units),
        lineParserProvider.overrideWith(
          (Ref ref) async => IngredientLineParser(_units),
        ),
        ingredientMatchesProvider.overrideWith(
          (Ref ref, (String, {String locale}) arg) async =>
              const <IngredientMatch>[],
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
        routerConfig: router,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump();
  }
}

IngredientLineRow _rowNamed(WidgetTester tester, String name) => tester
    .widgetList<IngredientLineRow>(find.byType(IngredientLineRow))
    .singleWhere((IngredientLineRow r) => r.name.contains(name));

ImportJob _job(
  ImportJobStatus status, {
  ParsedRecipe? result,
  String? errorMessage,
  String? recipeId,
}) => ImportJob(
  id: _jobId,
  kind: ImportKind.text,
  status: status,
  result: result,
  errorMessage: errorMessage,
  recipeId: recipeId,
);

void main() {
  testWidgets('a queued job shows progress, not an error', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _job(ImportJobStatus.queued), settle: false);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('Queued'), findsOneWidget);
  });

  testWidgets('a processing job says what it is doing', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _job(ImportJobStatus.processing), settle: false);
    expect(find.textContaining('Reading the recipe'), findsOneWidget);
  });

  testWidgets('a failed job shows the server\'s own sentence', (
    WidgetTester tester,
  ) async {
    // import_jobs stores the {error, message} pair so a job can still say why
    // days later. Replacing it with a generic message here would throw away
    // the only thing that explains the failure.
    await _pump(
      tester,
      _job(
        ImportJobStatus.failed,
        errorMessage: 'This household has used its AI allowance.',
      ),
    );

    expect(
      find.text('This household has used its AI allowance.'),
      findsOneWidget,
    );
    expect(find.text('Discard this import'), findsOneWidget);
  });

  testWidgets('a failed job is an empty state in outline, not error', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      _job(ImportJobStatus.failed, errorMessage: 'Could not read it.'),
    );

    // A failed import is not validation, so nothing on it is red.
    final ThemeData theme = AppTheme.light();
    expect(find.byType(AppEmptyState), findsOneWidget);
    final Icon icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
    expect(icon.color, theme.colorScheme.outline);
    expect(icon.color, isNot(theme.colorScheme.error));
  });

  testWidgets('a reviewable job renders every line, matched or not', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _job(ImportJobStatus.needsReview, result: _parsed()));

    // Rule 3: all three lines are on screen, including the one nothing
    // matched and has no quantity or unit.
    expect(
      find.textContaining('šargarepe', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('praška za pecivo', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('za posluživanje', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('→ šargarepa'), findsOneWidget);
    expect(find.text('Save recipe'), findsOneWidget);
  });

  testWidgets('the summary counts matches and flags the LLM line', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _job(ImportJobStatus.needsReview, result: _parsed()));

    // Two of three matched; the LLM one is the single line worth a look,
    // because part 2 never auto-accepts an LLM answer.
    expect(find.text('2 of 3 ingredients matched'), findsOneWidget);
    expect(find.text('1 worth a look before saving'), findsOneWidget);
  });

  testWidgets('a job already saved offers the recipe instead of the form', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      _job(ImportJobStatus.done, result: _parsed(), recipeId: 'r-1'),
    );

    expect(find.textContaining('already been saved'), findsOneWidget);
    expect(find.text('Save recipe'), findsNothing);
  });

  testWidgets('only the matched-without-auto-accept line is flagged; the '
      'unmatched one gets the ring, not the flag', (WidgetTester tester) async {
    await _pump(tester, _job(ImportJobStatus.needsReview, result: _parsed()));

    expect(_rowNamed(tester, 'šargarepe').isFlagged, isFalse);
    expect(_rowNamed(tester, 'praška za pecivo').isFlagged, isTrue);
    final IngredientLineRow unmatched = _rowNamed(tester, 'za posluživanje');
    expect(unmatched.isMatched, isFalse);
    expect(unmatched.isFlagged, isFalse);
    expect(find.byKey(const Key('unmatchedMarker')), findsOneWidget);
  });

  testWidgets('a tapped row opens into the editor, one line at a time', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _job(ImportJobStatus.needsReview, result: _parsed()));

    expect(find.byType(IngredientLineField), findsNothing);

    await tester.tap(find.byType(IngredientLineRow).first);
    await tester.pumpAndSettle();
    expect(find.byType(IngredientLineField), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(IngredientLineField), findsNothing);

    await tester.tap(find.byType(IngredientLineRow).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(IngredientLineRow).at(1));
    await tester.pumpAndSettle();
    expect(find.byType(IngredientLineField), findsOneWidget);
  });

  testWidgets('Add ingredient opens a blank line', (WidgetTester tester) async {
    await _pump(tester, _job(ImportJobStatus.needsReview, result: _parsed()));

    await tester.tap(find.text('Add ingredient'));
    await tester.pumpAndSettle();

    final Finder field = find.byType(IngredientLineField);
    expect(field, findsOneWidget);
    final EditableText text = tester.widget<EditableText>(
      find.descendant(of: field, matching: find.byType(EditableText)).first,
    );
    expect(text.controller.text, isEmpty);

    // The walk's defect: the first keystroke used to collapse the line back
    // into a row, because it was held open only by being blank.
    await tester.enterText(
      find.descendant(of: field, matching: find.byType(EditableText)).first,
      'm',
    );
    await tester.pumpAndSettle();
    expect(find.byType(IngredientLineField), findsOneWidget);
  });

  testWidgets('Method is collapsed on open and expands in place', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _job(ImportJobStatus.needsReview, result: _parsed()));

    expect(find.text('Zagrejati rernu.'), findsNothing);
    expect(find.text('1 step'), findsOneWidget);

    await tester.tap(find.text('Method'));
    await tester.pumpAndSettle();
    expect(find.text('Zagrejati rernu.'), findsOneWidget);
  });

  testWidgets('Discard on a review asks first; Cancel keeps the job, '
      'Discard dismisses it and leaves', (WidgetTester tester) async {
    final _FakeImportRepo repo = _FakeImportRepo();
    await _pump(
      tester,
      _job(ImportJobStatus.needsReview, result: _parsed()),
      repo: repo,
    );

    await tester.tap(find.text('Discard this import'));
    await tester.pumpAndSettle();
    expect(find.text('Discard this import?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo.dismissed, isEmpty);
    expect(find.text('Save recipe'), findsOneWidget);

    await tester.tap(find.text('Discard this import'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(repo.dismissed, <String>[_jobId]);
    expect(find.text(_landedOnRecipes), findsOneWidget);
  });

  testWidgets('Serbian at 360x780 lays out without overflow, both actions '
      'side by side', (WidgetTester tester) async {
    // flutter_test's square-glyph font wraps differently from the device, so
    // this guards overflow, not wrapping -- that is the device walk's job.
    await _pump(
      tester,
      _job(ImportJobStatus.needsReview, result: _parsed()),
      locale: srLatn,
      surface: const Size(360, 780),
    );
    expect(tester.takeException(), isNull);

    final AppLocalizationsSr sr = AppLocalizationsSr();
    expect(find.text(sr.discardImportButton), findsOneWidget);
    expect(find.text(sr.saveRecipeButton), findsOneWidget);
    expect(sr.discardImportButton, 'Odbaci ovaj uvoz');
    expect(sr.saveRecipeButton, 'Sačuvaj recept');
  });
}

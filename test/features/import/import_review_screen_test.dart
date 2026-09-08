// The confirm screen (D8), driven through the real notifier with the job and
// the catalog stubbed by provider override -- no mocking package (rule 8).
//
// No test presses Save. `save()` writes aliases and calls
// save_imported_recipe, both of which reach the network; the SQL test covers
// the server half and the end-to-end run covers the join.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/ingredients/ingredient_catalog_providers.dart';
import 'package:kitchen_table/features/import/application/import_providers.dart';
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

Future<void> _pump(
  WidgetTester tester,
  ImportJob job, {
  // The waiting states show a CircularProgressIndicator, which animates
  // forever -- pumpAndSettle would never return.
  bool settle = true,
}) async {
  // The form is taller than the default 800x600 surface, and a ListView does
  // not build what is below the fold.
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        importJobProvider.overrideWith((Ref ref, String jobId) =>
            Stream<ImportJob>.value(job)),
        unitCatalogProvider.overrideWith((Ref ref) async => _units),
        lineParserProvider
            .overrideWith((Ref ref) async => IngredientLineParser(_units)),
        ingredientMatchesProvider.overrideWith(
          (Ref ref, (String, {String locale}) arg) async =>
              const <IngredientMatch>[],
        ),
      ],
      child: const MaterialApp(home: ImportReviewScreen(jobId: _jobId)),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump();
  }
}

ImportJob _job(ImportJobStatus status,
        {ParsedRecipe? result, String? errorMessage, String? recipeId}) =>
    ImportJob(
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
      _job(ImportJobStatus.failed,
          errorMessage: 'This household has used its AI allowance.'),
    );

    expect(find.text('This household has used its AI allowance.'),
        findsOneWidget);
    expect(find.text('Discard this import'), findsOneWidget);
  });

  testWidgets('a reviewable job renders every line, matched or not', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      _job(ImportJobStatus.needsReview, result: _parsed()),
    );

    // Rule 3: all three lines are on screen as written, including the one
    // nothing matched.
    expect(find.text('200 g šargarepe'), findsOneWidget);
    expect(find.text('1 kesica praška za pecivo'), findsOneWidget);
    expect(find.text('za posluživanje'), findsOneWidget);
    expect(find.text('Save recipe'), findsOneWidget);
  });

  testWidgets('the summary counts matches and flags the LLM line', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      _job(ImportJobStatus.needsReview, result: _parsed()),
    );

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
}

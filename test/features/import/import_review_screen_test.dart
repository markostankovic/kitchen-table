// The confirm screen (D8), driven through the real notifier with the job and
// the catalog stubbed by provider override -- no mocking package (rule 8).
//
// Save is pressed only in the "Saves to" group (phase9-import-save-to), with
// the catalog's alias write-back and save_imported_recipe both faked; the SQL
// test covers the server half and the end-to-end run covers the join.

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
import 'package:kitchen_table/core/supabase/supabase_client.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/core/widgets/app_empty_state.dart';
import 'package:kitchen_table/core/widgets/app_formatting_toolbar.dart';
import 'package:kitchen_table/features/households/application/household_providers.dart';
import 'package:kitchen_table/features/households/domain/household.dart';
import 'package:kitchen_table/features/import/application/import_confirm.dart';
import 'package:kitchen_table/features/import/application/import_providers.dart';
import 'package:kitchen_table/features/import/data/import_repository.dart';
import 'package:kitchen_table/features/import/domain/import_job.dart';
import 'package:kitchen_table/features/import/domain/parsed_recipe.dart';
import 'package:kitchen_table/features/import/presentation/import_review_screen.dart';
import 'package:kitchen_table/features/ingredients/data/ingredient_repository.dart';
import 'package:kitchen_table/features/ingredients/domain/ingredient_line_parser.dart';
import 'package:kitchen_table/features/ingredients/domain/ingredient_match.dart';
import 'package:kitchen_table/features/ingredients/domain/unit.dart';
import 'package:kitchen_table/features/ingredients/domain/unit_catalog.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_draft.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_ingredient.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_step.dart';

import '../../helpers/fake_household_repository.dart';
import '../../helpers/fixed_current_household.dart';

const String _jobId = 'job-1';

const Household _mira = Household(id: 'mira', name: 'Kod Mire', createdBy: 'u1');
const Household _weekend = Household(
  id: 'weekend',
  name: 'Porodica Stanković – vikendica',
  createdBy: 'u1',
);

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

  /// Every save's `targetHouseholdId`, in order.
  final List<String?> savedTargets = <String?>[];

  @override
  Future<void> dismiss(String jobId) async => dismissed.add(jobId);

  @override
  Future<String> saveImported(
    String jobId, {
    required ImportKind kind,
    required String title,
    required String originalLocale,
    required List<RecipeIngredient> ingredients,
    required List<RecipeStep> steps,
    String? description,
    String? notes,
    int? servings,
    int? prepMinutes,
    int? cookMinutes,
    String? sourceUrl,
    String? sourceAttribution,
    List<String> tags = const <String>[],
    String? targetHouseholdId,
  }) async {
    savedTargets.add(targetHouseholdId);
    return 'recipe-1';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not stubbed: ${invocation.memberName}');
}

/// The alias write-back that runs before the save (D42), answered locally.
class _FakeCatalog implements IngredientRepository {
  @override
  Future<bool> linkAlias(
    String ingredientId,
    String aliasName, {
    String locale = 'sr',
  }) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not stubbed: ${invocation.memberName}');
}

const String _landedOnRecipes = 'landed on the recipe list';
const String _landedOnDetail = 'landed on the recipe detail';

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
  // Inside the app shell's Scaffold, as on a device: that one takes the
  // keyboard's inset out of everything below it.
  bool inShell = false,
  // The caller's households, oldest first; the first is current. One by
  // default, which is today's bar.
  List<Household> households = const <Household>[_mira],
}) async {
  final FakeHouseholdRepository householdRepo = FakeHouseholdRepository(
    List<Household>.of(households),
  );
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  // A real router, because Discard ends in `RecipesRoute().go(context)`.
  final GoRouter router = GoRouter(
    initialLocation: '/review',
    routes: <RouteBase>[
      GoRoute(
        path: '/review',
        builder: (_, _) => inShell
            ? const Scaffold(
                body: ImportReviewScreen(jobId: _jobId),
                bottomNavigationBar: SizedBox(height: 80),
              )
            : const ImportReviewScreen(jobId: _jobId),
      ),
      GoRoute(
        path: RecipesRoute.path,
        builder: (_, _) => const Scaffold(body: Text(_landedOnRecipes)),
        routes: <RouteBase>[
          GoRoute(
            path: ':recipeId',
            builder: (_, _) => const Scaffold(body: Text(_landedOnDetail)),
          ),
        ],
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
        ingredientCatalogProvider.overrideWithValue(_FakeCatalog()),
        householdRepositoryProvider.overrideWithValue(householdRepo),
        currentUserIdProvider.overrideWith(
          (Ref ref) => Stream<String?>.value('u1'),
        ),
        currentHouseholdProvider.overrideWith(
          () => FixedCurrentHousehold(
            () => householdRepo.fetchCurrent(userId: 'u1'),
          ),
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
  String householdId = 'mira',
}) => ImportJob(
  id: _jobId,
  householdId: householdId,
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

  testWidgets('Discard while waiting dismisses the job without asking and '
      'leaves', (WidgetTester tester) async {
    // Nothing has been parsed yet, so, as on a failed job, there is nothing
    // for a confirm to protect.
    final _FakeImportRepo repo = _FakeImportRepo();
    await _pump(
      tester,
      _job(ImportJobStatus.processing),
      settle: false,
      repo: repo,
    );

    await tester.tap(find.text('Discard this import'));
    // The spinner is gone once the route changes, so settling ends.
    await tester.pumpAndSettle();
    expect(find.text('Discard this import?'), findsNothing);
    expect(repo.dismissed, <String>[_jobId]);
    expect(find.text(_landedOnRecipes), findsOneWidget);
  });

  testWidgets('Serbian at 360x780 lays out the waiting state without '
      'overflow', (WidgetTester tester) async {
    await _pump(
      tester,
      _job(ImportJobStatus.processing),
      settle: false,
      locale: srLatn,
      surface: const Size(360, 780),
    );
    expect(tester.takeException(), isNull);

    final AppLocalizationsSr sr = AppLocalizationsSr();
    expect(find.text(sr.readingRecipeEllipsis), findsOneWidget);
    expect(find.text(sr.discardImportButton), findsOneWidget);
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
    // The unmatched line names its state in words, not only in the ring's
    // tooltip (which is not in the tree until shown).
    expect(find.text('Not matched to an ingredient'), findsOneWidget);
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

  testWidgets('the attention line and the step count are bodyMedium', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _job(ImportJobStatus.needsReview, result: _parsed()));

    final BuildContext context = tester.element(find.byType(Scaffold).first);
    final double? bodyMedium = Theme.of(context).textTheme.bodyMedium!.fontSize;
    expect(
      tester
          .widget<Text>(find.text('1 worth a look before saving'))
          .style!
          .fontSize,
      bodyMedium,
    );
    expect(
      tester.widget<Text>(find.text('1 step')).style!.fontSize,
      bodyMedium,
    );
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
    // D123 #3 holds with the new words: the trailer names the state, but the
    // line is still not flagged.
    expect(unmatched.trailer, startsWith('Not matched to an ingredient'));
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

    // There is no Done any more (D159): tapping another row closes this one
    // and opens that.
    expect(find.text('Done'), findsNothing);
    await tester.tap(find.byType(IngredientLineRow).at(1));
    await tester.pumpAndSettle();
    expect(find.byType(IngredientLineField), findsOneWidget);
    expect(
      tester
          .widget<IngredientLineField>(find.byType(IngredientLineField))
          .index,
      2,
    );

    // Next on a line commits it and opens a blank one straight under it.
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    final IngredientLineField opened =
        tester.widget<IngredientLineField>(find.byType(IngredientLineField));
    expect(opened.index, 3);
    expect(opened.line.rawText, isEmpty);

    // Next on that blank line closes it, and it goes.
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(find.byType(IngredientLineField), findsNothing);
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

  testWidgets('the Method subline counts steps only, and headings and notes '
      'carry their icon (D153)', (WidgetTester tester) async {
    await _pump(
      tester,
      _job(
        ImportJobStatus.needsReview,
        result: _parsed().copyWith(
          steps: const <ParsedStep>[
            ParsedStep(text: 'Za testo', kind: ParsedStepKind.HEADING),
            ParsedStep(text: 'Zagrejati rernu.'),
            ParsedStep(text: 'Može i dan ranije.', kind: ParsedStepKind.NOTE),
            ParsedStep(text: 'Peći 40 minuta.', kind: ParsedStepKind.STEP),
          ],
        ),
      ),
    );

    expect(find.text('2 steps'), findsOneWidget);

    await tester.tap(find.text('Method'));
    await tester.pumpAndSettle();
    // The heading's, and the ingredient list's Add section.
    expect(find.byIcon(Icons.title), findsNWidgets(2));
    expect(find.byIcon(Icons.sticky_note_2_outlined), findsOneWidget);
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

  testWidgets('Notes is collapsed under Method and says when none was found', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _job(ImportJobStatus.needsReview, result: _parsed()));

    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('None found'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Notes')).dy,
      greaterThan(tester.getTopLeft(find.text('Method')).dy),
    );
  });

  testWidgets('Serbian says Nije pronađena for a missing note', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      _job(ImportJobStatus.needsReview, result: _parsed()),
      locale: const Locale('sr'),
    );

    expect(find.text('Napomena'), findsOneWidget);
    expect(find.text('Nije pronađena'), findsOneWidget);
  });

  testWidgets('a found note shows its first words collapsed; typing updates '
      'the subline and the draft save() sends', (WidgetTester tester) async {
    await _pump(
      tester,
      _job(
        ImportJobStatus.needsReview,
        result: _parsed().copyWith(notes: 'Čuva se\n- tri dana u frižideru'),
      ),
    );

    // Whitespace collapsed to one line, the list marker taken out.
    expect(find.text('Čuva se tri dana u frižideru'), findsOneWidget);

    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    final Finder field = find.descendant(
      of: find.ancestor(
        of: find.text('Notes'),
        matching: find.byType(ExpansionTile),
      ),
      matching: find.byType(TextFormField),
    );
    expect(field, findsOneWidget);

    await tester.enterText(field, 'Najbolja sutradan.');
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(ListTile),
        matching: find.text('Najbolja sutradan.'),
      ),
      findsOneWidget,
    );
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(ImportReviewScreen)),
    );
    expect(
      container.read(importConfirmProvider(_jobId)).value!.draft.notes,
      'Najbolja sutradan.',
    );
  });

  group('the formatting toolbar (D166)', () {
    ImportJob job() => _job(
      ImportJobStatus.needsReview,
      result: _parsed().copyWith(
        notes: 'Čuva se.',
        steps: const <ParsedStep>[
          ParsedStep(text: 'Za testo', kind: ParsedStepKind.HEADING),
          ParsedStep(text: 'Zagrejati rernu.'),
          ParsedStep(text: 'Pazi.', kind: ParsedStepKind.NOTE),
        ],
      ),
    );

    /// Method and Notes open, with the keyboard up for the whole test;
    /// whether the toolbar shows then depends on what has focus.
    Future<void> pumpWithKeyboard(
      WidgetTester tester, {
      bool inShell = false,
      bool keyboard = true,
    }) async {
      await _pump(tester, job(), inShell: inShell);
      if (keyboard) {
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.resetViewInsets);
      }
      await tester.tap(find.text('Method'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Notes'));
      await tester.pumpAndSettle();
    }

    Finder field(String text) => find.ancestor(
      of: find.byWidgetPredicate(
        (Widget w) => w is EditableText && w.controller.text == text,
      ),
      matching: find.byType(TextField),
    );

    Future<void> focus(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.showKeyboard(finder);
      await tester.pumpAndSettle();
    }

    final Finder toolbar = find.byType(AppFormattingToolbar);
    final Finder save = find.widgetWithText(FilledButton, 'Save recipe');

    String? draftText(WidgetTester tester, String start) {
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(ImportReviewScreen)),
      );
      return container
          .read(importConfirmProvider(_jobId))
          .value!
          .draft
          .steps
          .map((RecipeDraftStep s) => s.text)
          .firstWhere((String t) => t.contains(start));
    }

    testWidgets('is hidden while nothing has focus', (
      WidgetTester tester,
    ) async {
      await pumpWithKeyboard(tester);
      expect(toolbar, findsNothing);
      expect(save, findsOneWidget);
    });

    testWidgets('shows for a step, a note row and the end note, in place of '
        'the action bar', (WidgetTester tester) async {
      await pumpWithKeyboard(tester);
      for (final String text in <String>[
        'Zagrejati rernu.',
        'Pazi.',
        'Čuva se.',
      ]) {
        await focus(tester, field(text));
        expect(toolbar, findsOneWidget, reason: text);
        expect(save, findsNothing, reason: text);
      }
    });

    testWidgets('is hidden for a heading and the title', (
      WidgetTester tester,
    ) async {
      await pumpWithKeyboard(tester);
      for (final String text in <String>['Za testo', 'Šargarepa torta']) {
        await focus(tester, field(text));
        expect(toolbar, findsNothing, reason: text);
      }
    });

    testWidgets('does not show without the keyboard', (
      WidgetTester tester,
    ) async {
      await pumpWithKeyboard(tester, keyboard: false);
      await focus(tester, field('Zagrejati rernu.'));
      expect(toolbar, findsNothing);
      expect(save, findsOneWidget);
    });

    testWidgets('hide-keyboard brings the action bar back', (
      WidgetTester tester,
    ) async {
      await pumpWithKeyboard(tester);
      await focus(tester, field('Čuva se.'));
      expect(toolbar, findsOneWidget);

      await tester.tap(find.byTooltip('Hide keyboard'));
      await tester.pumpAndSettle();

      expect(toolbar, findsNothing);
      expect(save, findsOneWidget);
    });

    testWidgets('bold on a selected word reaches the draft', (
      WidgetTester tester,
    ) async {
      await pumpWithKeyboard(tester);
      final Finder step = field('Zagrejati rernu.');
      await focus(tester, step);
      final EditableText editable = tester.widget<EditableText>(
        find.descendant(of: step, matching: find.byType(EditableText)),
      );
      editable.controller.selection = const TextSelection(
        baseOffset: 10,
        extentOffset: 15,
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Bold'));
      await tester.pumpAndSettle();

      expect(draftText(tester, 'Zagrejati'), 'Zagrejati **rernu**.');
      expect(editable.focusNode.hasFocus, isTrue);
      expect(toolbar, findsOneWidget);
    });

    testWidgets('collapsing Method lets go of a focused step, and the '
        'action bar comes back', (WidgetTester tester) async {
      await pumpWithKeyboard(tester);
      await focus(tester, field('Zagrejati rernu.'));
      expect(toolbar, findsOneWidget);

      await tester.tap(find.text('Method'));
      await tester.pumpAndSettle();

      expect(toolbar, findsNothing);
      expect(save, findsOneWidget);
    });

    testWidgets('collapsing Method leaves a focused end note alone', (
      WidgetTester tester,
    ) async {
      await pumpWithKeyboard(tester);
      await focus(tester, field('Čuva se.'));

      await tester.tap(find.text('Method'));
      await tester.pumpAndSettle();

      expect(toolbar, findsOneWidget);
    });

    testWidgets('inside the app shell it sits on the keyboard in place of the '
        'action bar, and the action bar comes back', (
      WidgetTester tester,
    ) async {
      await pumpWithKeyboard(tester, inShell: true);
      await focus(tester, field('Zagrejati rernu.'));

      expect(toolbar, findsOneWidget);
      expect(save, findsNothing);
      // The shell ends at the keyboard's top (3000 - 300).
      expect(tester.getBottomLeft(toolbar).dy, 2700);

      await tester.tap(find.byTooltip('Hide keyboard'));
      await tester.pumpAndSettle();

      expect(toolbar, findsNothing);
      expect(save, findsOneWidget);
    });

    testWidgets('a found note with markup has a plain subline', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _job(
          ImportJobStatus.needsReview,
          result: _parsed().copyWith(notes: '**Poslužite** *toplo*'),
        ),
      );
      expect(find.text('Poslužite toplo'), findsOneWidget);
    });
  });

  group('Saves to (phase9-import-save-to)', () {
    final Finder savesTo = find.textContaining('Saves to', findRichText: true);

    Future<void> pumpReview(
      WidgetTester tester, {
      required List<Household> households,
      _FakeImportRepo? repo,
      String householdId = 'mira',
    }) => _pump(
      tester,
      _job(
        ImportJobStatus.needsReview,
        result: _parsed(),
        householdId: householdId,
      ),
      repo: repo,
      households: households,
    );

    testWidgets('one household: no line, null target, detail, no snackbar', (
      WidgetTester tester,
    ) async {
      final _FakeImportRepo repo = _FakeImportRepo();
      await pumpReview(tester, households: <Household>[_mira], repo: repo);

      expect(savesTo, findsNothing);
      expect(find.text('Change'), findsNothing);

      await tester.tap(find.text('Save recipe'));
      await tester.pumpAndSettle();

      expect(repo.savedTargets, <String?>[null]);
      expect(find.text(_landedOnDetail), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('2+ households name the JOB\'s household, even when it is not '
        'the current one', (WidgetTester tester) async {
      await pumpReview(
        tester,
        households: <Household>[_mira, _weekend],
        householdId: 'weekend',
      );

      expect(
        find.text('Saves to ${_weekend.name}', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('the name is w600 onSurface over an onSurfaceVariant prefix', (
      WidgetTester tester,
    ) async {
      await pumpReview(tester, households: <Household>[_mira, _weekend]);

      final RichText text = tester.widget<RichText>(
        find.text('Saves to Kod Mire', findRichText: true),
      );
      final ColorScheme colors = AppTheme.light().colorScheme;
      final TextSpan root = text.text as TextSpan;
      expect(root.style!.color, colors.onSurfaceVariant);
      final TextSpan line = root.children!.single as TextSpan;
      final TextSpan name = line.children!.single as TextSpan;
      expect(name.text, 'Kod Mire');
      expect(name.style!.color, colors.onSurface);
      expect(name.style!.fontWeight, FontWeight.w600);
    });

    testWidgets('saving unchanged sends null, lands on detail, says where', (
      WidgetTester tester,
    ) async {
      final _FakeImportRepo repo = _FakeImportRepo();
      await pumpReview(
        tester,
        households: <Household>[_mira, _weekend],
        repo: repo,
      );

      await tester.tap(find.text('Save recipe'));
      await tester.pumpAndSettle();

      expect(repo.savedTargets, <String?>[null]);
      expect(find.text(_landedOnDetail), findsOneWidget);
      expect(find.text('Saved to Kod Mire.'), findsOneWidget);
    });

    testWidgets('Change opens Save to without Manage; picking another updates '
        'the line, and Save sends it and lands on Recipes', (
      WidgetTester tester,
    ) async {
      final _FakeImportRepo repo = _FakeImportRepo();
      await pumpReview(
        tester,
        households: <Household>[_mira, _weekend],
        repo: repo,
      );

      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();

      expect(find.text('Save to'), findsOneWidget);
      expect(find.text('Manage households'), findsNothing);

      await tester.tap(find.text(_weekend.name));
      await tester.pumpAndSettle();

      expect(find.text('Save to'), findsNothing);
      expect(
        find.text('Saves to ${_weekend.name}', findRichText: true),
        findsOneWidget,
      );

      await tester.tap(find.text('Save recipe'));
      await tester.pumpAndSettle();

      expect(repo.savedTargets, <String?>['weekend']);
      expect(find.text(_landedOnRecipes), findsOneWidget);
      expect(find.text('Saved to ${_weekend.name}.'), findsOneWidget);
    });

    testWidgets('Serbian at 360dp: the long name wraps, nothing overflows', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _job(
          ImportJobStatus.needsReview,
          result: _parsed(),
          householdId: 'weekend',
        ),
        locale: srLatn,
        surface: const Size(360, 3000),
        households: <Household>[_mira, _weekend],
      );
      expect(tester.takeException(), isNull);

      final AppLocalizationsSr sr = AppLocalizationsSr();
      expect(find.text(sr.importSaveToChange), findsOneWidget);
      final Finder line = find.text(
        '${sr.importSavesToPrefix} ${_weekend.name}',
        findRichText: true,
      );
      expect(line, findsOneWidget);
      // Up to two lines, never one with an ellipsis that eats the name. The
      // test font is one em per glyph, so whether it fits in two is the
      // device walk's to check, not this one's.
      expect(tester.widget<RichText>(line).maxLines, 2);
    });
  });
}

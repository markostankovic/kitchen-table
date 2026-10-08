import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/images/recipe_image_cache.dart';
import 'package:kitchen_table/core/l10n/app_locale.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/core/widgets/app_formatting_toolbar.dart';
import 'package:kitchen_table/features/recipes/application/recipe_editor.dart';
import 'package:kitchen_table/features/recipes/domain/recipe.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_detail.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_draft.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_ingredient.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_step.dart';
import 'package:kitchen_table/features/recipes/presentation/recipe_edit_screen.dart';

import '../../helpers/fake_image_cache.dart';

/// The notifier is overridden, not mocked -- Riverpod's own override
/// mechanism, so CLAUDE.md rule 8 is never triggered. Only `build` is
/// replaced: every mutator under test is the real one, because the behaviour
/// worth asserting is exactly what those do to the draft.
///
/// No test presses Save with a valid form. `save()` is the one method that
/// reaches the repository, and it is covered by the pure draft tests either
/// side of it plus the SQL suite; what matters here is that an invalid form
/// never gets that far.
class _StubEditor extends RecipeEditor {
  _StubEditor(this.initial);

  final RecipeDraft initial;

  @override
  Future<RecipeDraft> build(String? recipeId) async => initial;
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

final RecipeDetail _detail = RecipeDetail(
  recipe: _torta,
  readingLocale: 'sr',
  ingredients: const <RecipeIngredient>[
    RecipeIngredient(position: 0, rawText: '200 g šargarepe'),
    RecipeIngredient(position: 1, rawText: 'so po ukusu'),
  ],
  steps: const <RecipeStep>[
    RecipeStep(position: 0, text: 'Zagrej rernu.'),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  String? recipeId,
  required RecipeDraft draft,
  Locale? locale,
  // The form is taller than the default 800x600 test surface, and a ListView
  // does not build what is below the fold. Without this the ingredient and
  // step lists simply are not there to find.
  Size surface = const Size(1200, 3000),
  // Inside the app shell's Scaffold, as on a device: that one takes the
  // keyboard's inset out of everything below it.
  bool inShell = false,
}) async {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        recipeEditorProvider(recipeId).overrideWith(() => _StubEditor(draft)),
        // Phase 8 part 2: a recipe photo goes through the disk cache, and
        // the real one opens a database through path_provider.
        recipeImageCacheManagerProvider.overrideWithValue(FakeImageCache()),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
        home: inShell
            ? Scaffold(
                body: RecipeEditScreen(recipeId: recipeId),
                bottomNavigationBar: const SizedBox(height: 80),
              )
            : RecipeEditScreen(recipeId: recipeId),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('a new recipe', () {
    testWidgets('opens with one empty ingredient line and one empty step',
        (WidgetTester tester) async {
      await _pump(tester, draft: RecipeDraft.empty());

      expect(find.text('New recipe'), findsOneWidget);
      expect(find.text('2 šolje glatkog brašna'), findsOneWidget);
      expect(find.text('Step 1'), findsOneWidget);
    });

    testWidgets('will not save without a title', (WidgetTester tester) async {
      await _pump(tester, draft: RecipeDraft.empty());

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      // The validator stopped it before the repository was ever reached; had
      // it not, this test would have thrown on an uninitialised client.
      expect(find.text('Enter a title.'), findsOneWidget);
    });

    testWidgets('adding an ingredient adds a field',
        (WidgetTester tester) async {
      await _pump(tester, draft: RecipeDraft.empty());

      // One ingredient row and one step row to start with.
      expect(find.byIcon(Icons.drag_indicator), findsNWidgets(2));

      // A blank line that closes is removed (D159), so the first line needs
      // something in it to survive the new one opening.
      await tester.enterText(
        find.widgetWithText(TextField, '2 šolje glatkog brašna'),
        'so',
      );
      // A frame for the typed text to reach the list, as one always does
      // between a keystroke and a tap on a device.
      await tester.pump();
      await tester.tap(find.widgetWithText(TextButton, 'Add ingredient'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.drag_indicator), findsNWidgets(3));
    });

    testWidgets('shows the Translate action -- there is nothing to conflict '
        'with yet', (WidgetTester tester) async {
      await _pump(tester, draft: RecipeDraft.empty());

      expect(find.byIcon(Icons.translate), findsOneWidget);
    });
  });

  group('headings and notes (D153)', () {
    testWidgets('Heading and Note add their kind, labelled by kind',
        (WidgetTester tester) async {
      await _pump(tester, draft: RecipeDraft.empty());

      await tester.tap(find.widgetWithText(TextButton, 'Heading'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Note'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Step'));
      await tester.pumpAndSettle();

      // Step 1, Heading, Note, then Step 2 -- not Step 4.
      expect(find.text('Step 1'), findsOneWidget);
      expect(find.text('Step 2'), findsOneWidget);
      expect(find.text('Step 4'), findsNothing);
      // Label + button, and the ingredient list's Add section.
      expect(find.byIcon(Icons.title), findsNWidgets(3));
      expect(find.byIcon(Icons.sticky_note_2_outlined), findsNWidgets(2));
      // The label beside its icon, not just the add button.
      expect(find.text('Heading'), findsNWidgets(2));
      expect(find.text('Note'), findsNWidgets(2));
    });

    testWidgets('step labels skip headings and notes',
        (WidgetTester tester) async {
      await _pump(
        tester,
        draft: const RecipeDraft(steps: <RecipeDraftStep>[
          RecipeDraftStep(
              localId: 0, text: 'Za testo', kind: RecipeStepKind.heading),
          RecipeDraftStep(localId: 1, text: 'Umesiti testo.'),
          RecipeDraftStep(
              localId: 2, text: 'Može i dan ranije.', kind: RecipeStepKind.note),
          RecipeDraftStep(localId: 3, text: 'Peći.'),
        ]),
      );

      expect(find.text('Step 1'), findsOneWidget);
      expect(find.text('Step 2'), findsOneWidget);
      expect(find.text('Step 3'), findsNothing);
    });

    testWidgets('removing a heading offers Undo, which puts it back in place',
        (WidgetTester tester) async {
      await _pump(
        tester,
        draft: const RecipeDraft(steps: <RecipeDraftStep>[
          RecipeDraftStep(localId: 0, text: 'Umesiti testo.'),
          RecipeDraftStep(localId: 1, text: 'Fil', kind: RecipeStepKind.heading),
          RecipeDraftStep(localId: 2, text: 'Umutiti fil.'),
        ]),
      );

      final Finder headingRow = find.ancestor(
        of: find.text('Fil'),
        matching: find.byType(Row),
      );
      await tester.tap(find
          .descendant(
            of: headingRow.first,
            matching: find.widgetWithIcon(IconButton, Icons.close),
          )
          .first);
      await tester.pumpAndSettle();

      expect(find.text('Fil'), findsNothing);
      expect(find.text('Heading removed.'), findsOneWidget);

      await tester.tap(find.widgetWithText(SnackBarAction, 'Undo'));
      await tester.pumpAndSettle();

      final Iterable<String> fields = tester
          .widgetList<EditableText>(find.byType(EditableText))
          .map((EditableText e) => e.controller.text)
          .where((String t) => <String>[
                'Umesiti testo.',
                'Fil',
                'Umutiti fil.',
              ].contains(t));
      expect(fields, <String>['Umesiti testo.', 'Fil', 'Umutiti fil.']);
    });

    testWidgets('removing a step or a note offers no Undo',
        (WidgetTester tester) async {
      await _pump(
        tester,
        draft: const RecipeDraft(steps: <RecipeDraftStep>[
          RecipeDraftStep(
              localId: 0, text: 'Pazi.', kind: RecipeStepKind.note),
        ]),
      );

      await tester.tap(find.widgetWithIcon(IconButton, Icons.close).last);
      await tester.pumpAndSettle();

      expect(find.text('Pazi.'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('an existing recipe', () {
    testWidgets('opens with its fields and lines filled in',
        (WidgetTester tester) async {
      await _pump(
        tester,
        recipeId: 'r1',
        draft: RecipeDraft.fromDetail(_detail),
      );

      expect(find.text('Edit recipe'), findsOneWidget);
      expect(find.text('Šargarepa torta'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      // Closed rows, read like the recipe: the ring after an unmatched name
      // is an inline span, so the text is matched by containment.
      expect(find.textContaining('200 g šargarepe'), findsOneWidget);
      expect(find.textContaining('so po ukusu'), findsOneWidget);
      expect(find.byType(TextField).evaluate().length, 8);
      expect(find.text('Zagrej rernu.'), findsOneWidget);
    });

    testWidgets(
        'the tags field shows the typed spelling, never a translated one '
        '(Phase 6, part 1a: round-tripping through translation would '
        'silently rewrite what the cook typed)', (WidgetTester tester) async {
      await _pump(
        tester,
        recipeId: 'r1',
        draft: RecipeDraft.fromDetail(_detail)
            .copyWith(tags: <String>['Posno', 'Brzo']),
      );

      expect(find.text('Posno, Brzo'), findsOneWidget);
    });

    testWidgets('removing a line removes that line and no other',
        (WidgetTester tester) async {
      await _pump(
        tester,
        recipeId: 'r1',
        draft: RecipeDraft.fromDetail(_detail),
      );

      // Lines open one at a time; the open one's ✕ removes it.
      await tester.tap(find.textContaining('200 g šargarepe'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithIcon(IconButton, Icons.close).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('200 g šargarepe'), findsNothing);
      expect(find.textContaining('so po ukusu'), findsOneWidget);
      expect(find.text('Zagrej rernu.'), findsOneWidget);
    });

    testWidgets('an sr draft with no translations shows Translate to '
        'English', (WidgetTester tester) async {
      await _pump(
        tester,
        recipeId: 'r1',
        draft: RecipeDraft.fromDetail(_detail),
      );

      expect(find.byIcon(Icons.translate), findsOneWidget);
      expect(find.byTooltip('Translate to English'), findsOneWidget);
    });

    testWidgets('an sr draft already translated into English does not show '
        'the action -- the D85 guard', (WidgetTester tester) async {
      await _pump(
        tester,
        recipeId: 'r1',
        draft: RecipeDraft.fromDetail(_detail).copyWith(
          translatedLocales: <String>['en'],
        ),
      );

      expect(find.byIcon(Icons.translate), findsNothing);
    });

    testWidgets('the Translate action does not fire on an invalid form',
        (WidgetTester tester) async {
      await _pump(
        tester,
        recipeId: 'r1',
        draft: RecipeDraft.fromDetail(_detail).copyWith(title: ''),
      );

      // The validator stops it before the repository is ever reached; had it
      // not, this test would have thrown on an uninitialised client.
      await tester.tap(find.byIcon(Icons.translate));
      await tester.pumpAndSettle();

      expect(find.text('Enter a title.'), findsOneWidget);
    });
  });

  group('the end note (D153)', () {
    testWidgets('its heading, helper and field follow the add row', (
      WidgetTester tester,
    ) async {
      await _pump(tester, draft: RecipeDraft.empty());

      expect(find.text('Notes'), findsOneWidget);
      expect(
        find.text('Optional. Serving, storage, variations, tips.'),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.text('Notes')).dy,
        greaterThan(
          tester.getBottomLeft(find.widgetWithText(TextButton, 'Note')).dy,
        ),
      );
      final TextField field = tester.widget<TextField>(
        find.byType(TextField).last,
      );
      expect(field.minLines, 3);
      expect(field.maxLines, isNull);
    });

    testWidgets('typing reaches the draft save() sends', (
      WidgetTester tester,
    ) async {
      await _pump(tester, draft: RecipeDraft.empty());

      await tester.enterText(
        find.byType(TextFormField).last,
        'Čuva se tri dana.',
      );
      await tester.pump();

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(RecipeEditScreen)),
      );
      expect(
        container.read(recipeEditorProvider(null)).value!.notes,
        'Čuva se tri dana.',
      );
    });

    testWidgets('an existing recipe\'s note pre-fills the field', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        recipeId: 'r1',
        draft: RecipeDraft.fromDetail(
          _detail.copyWith(recipe: _torta.copyWith(notes: 'Bolja sutradan.')),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(TextFormField).last,
          matching: find.text('Bolja sutradan.'),
        ),
        findsOneWidget,
      );
    });
  });

  group('photo', () {
    testWidgets('a recipe with no photo offers Camera and Gallery, no Remove',
        (WidgetTester tester) async {
      await _pump(tester, draft: RecipeDraft.empty());

      // FilledButton.tonalIcon builds a private subclass, so match by `is`
      // rather than widgetWithText's runtimeType.
      for (final String label in <String>['Camera', 'Gallery']) {
        expect(
          find.ancestor(
            of: find.text(label),
            matching: find.byWidgetPredicate((Widget w) => w is FilledButton),
          ),
          findsOneWidget,
        );
      }
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      expect(find.byTooltip('Remove photo'), findsNothing);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('a recipe that already has a photo shows it and offers '
        'Remove', (WidgetTester tester) async {
      final Recipe withPhoto = _torta.copyWith(
        imagePath: 'h1/existing.jpg',
        imageUrl: 'https://example.test/existing.jpg',
      );
      await _pump(
        tester,
        recipeId: 'r1',
        draft: RecipeDraft.fromDetail(_detail.copyWith(recipe: withPhoto)),
      );

      expect(find.byTooltip('Remove photo'), findsOneWidget);
      final CachedNetworkImage image =
          tester.widget(find.byType(CachedNetworkImage));
      expect(image.imageUrl, 'https://example.test/existing.jpg');
      expect(image.cacheKey, 'h1/existing.jpg');
    });

    testWidgets('tapping Remove clears the preview and the Remove button',
        (WidgetTester tester) async {
      final Recipe withPhoto = _torta.copyWith(
        imagePath: 'h1/existing.jpg',
        imageUrl: 'https://example.test/existing.jpg',
      );
      await _pump(
        tester,
        recipeId: 'r1',
        draft: RecipeDraft.fromDetail(_detail.copyWith(recipe: withPhoto)),
      );

      await tester.tap(find.byTooltip('Remove photo'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Remove photo'), findsNothing);
      expect(find.byType(Image), findsNothing);
    });
  });

  group('form vocabulary', () {
    testWidgets('fits a 360dp phone in Serbian -- the numbers row and the '
        'segmented buttons are the risk', (WidgetTester tester) async {
      await _pump(
        tester,
        recipeId: 'r1',
        draft: RecipeDraft.fromDetail(_detail),
        locale: srLatn,
        surface: const Size(360, 780),
      );
      expect(tester.takeException(), isNull);

      // All three number fields share one line even if a label wraps.
      final Finder numbers = find.byWidgetPredicate((Widget w) =>
          w is TextField && w.keyboardType == TextInputType.number);
      expect(numbers, findsNWidgets(3));
      final Set<double> tops = <double>{
        for (final Element e in numbers.evaluate())
          tester.getTopLeft(find.byWidget(e.widget)).dy,
      };
      expect(tops, hasLength(1));
    });

    testWidgets('every field types in the sans bodyMedium, never Literata',
        (WidgetTester tester) async {
      await _pump(
        tester,
        recipeId: 'r1',
        draft: RecipeDraft.fromDetail(_detail),
      );

      final ThemeData theme = AppTheme.light();
      final Iterable<TextField> fields =
          tester.widgetList<TextField>(find.byType(TextField));
      // Title, description, three numbers, tags, one step, the end note. The
      // two ingredient lines are closed rows; an open one types in bodyLarge
      // (D158), the one exception, and ingredient_line_field_test covers it.
      expect(fields, hasLength(8));
      for (final TextField field in fields) {
        expect(field.style, isNotNull);
        expect(field.style!.fontFamily, isNot('Literata'));
        expect(field.style!.fontSize, theme.textTheme.bodyMedium!.fontSize);
      }
    });
  });

  group('the formatting toolbar (D166)', () {
    const RecipeDraft draft = RecipeDraft(
      title: 'Knedle',
      description: 'Sa šljivama.',
      notes: 'Čuva se.',
      steps: <RecipeDraftStep>[
        RecipeDraftStep(localId: 0, text: 'Testo', kind: RecipeStepKind.heading),
        RecipeDraftStep(localId: 1, text: 'Umesiti testo.'),
        RecipeDraftStep(localId: 2, text: 'Pazi.', kind: RecipeStepKind.note),
      ],
    );

    /// The keyboard is up for the whole test; whether the toolbar shows
    /// then depends on what has focus.
    Future<void> pumpWithKeyboard(
      WidgetTester tester, {
      bool inShell = false,
    }) async {
      await _pump(tester, draft: draft, inShell: inShell);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
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

    testWidgets('is hidden while nothing has focus', (
      WidgetTester tester,
    ) async {
      await pumpWithKeyboard(tester);
      expect(toolbar, findsNothing);
    });

    testWidgets('is hidden for the title, the tags and a heading', (
      WidgetTester tester,
    ) async {
      await pumpWithKeyboard(tester);
      for (final Finder finder in <Finder>[
        field('Knedle'),
        find.widgetWithText(TextField, 'Separated by commas'),
        field('Testo'),
      ]) {
        await focus(tester, finder);
        expect(toolbar, findsNothing, reason: finder.toString());
      }
    });

    testWidgets('shows for the description, a step, a note and the end note',
        (WidgetTester tester) async {
      await pumpWithKeyboard(tester);
      for (final String text in <String>[
        'Sa šljivama.',
        'Umesiti testo.',
        'Pazi.',
        'Čuva se.',
      ]) {
        await focus(tester, field(text));
        expect(toolbar, findsOneWidget, reason: text);
      }
    });

    testWidgets('does not show without the keyboard', (
      WidgetTester tester,
    ) async {
      await _pump(tester, draft: draft);
      await focus(tester, field('Umesiti testo.'));
      expect(toolbar, findsNothing);
    });

    testWidgets('bold on a selected word reaches the draft, and the field '
        'keeps focus and selection', (WidgetTester tester) async {
      await pumpWithKeyboard(tester);
      final Finder step = field('Umesiti testo.');
      await focus(tester, step);
      final EditableText editable = tester.widget<EditableText>(
        find.descendant(of: step, matching: find.byType(EditableText)),
      );
      editable.controller.selection = const TextSelection(
        baseOffset: 8,
        extentOffset: 13,
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Bold'));
      await tester.pumpAndSettle();

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(RecipeEditScreen)),
      );
      expect(
        container
            .read(recipeEditorProvider(null))
            .value!
            .steps
            .firstWhere((RecipeDraftStep s) => s.localId == 1)
            .text,
        'Umesiti **testo**.',
      );
      expect(editable.focusNode.hasFocus, isTrue);
      expect(
        editable.controller.selection,
        const TextSelection(baseOffset: 10, extentOffset: 15),
      );
      expect(toolbar, findsOneWidget);
    });

    testWidgets('inside the app shell it still shows, sits on the keyboard '
        'in place of the save bar, and the save bar comes back', (
      WidgetTester tester,
    ) async {
      await pumpWithKeyboard(tester, inShell: true);
      await focus(tester, field('Umesiti testo.'));

      expect(toolbar, findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Save'), findsNothing);
      // The shell ends at the keyboard's top (3000 - 300).
      expect(tester.getBottomLeft(toolbar).dy, 2700);

      await tester.tap(find.byTooltip('Hide keyboard'));
      await tester.pumpAndSettle();

      expect(toolbar, findsNothing);
      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
    });

    testWidgets('hide-keyboard takes the toolbar away', (
      WidgetTester tester,
    ) async {
      await pumpWithKeyboard(tester);
      await focus(tester, field('Sa šljivama.'));
      expect(toolbar, findsOneWidget);

      await tester.tap(find.byTooltip('Hide keyboard'));
      await tester.pumpAndSettle();

      expect(toolbar, findsNothing);
    });
  });
}

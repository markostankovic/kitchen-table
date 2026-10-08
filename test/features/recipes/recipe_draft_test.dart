import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/features/ingredients/domain/ingredient_match.dart';
import 'package:kitchen_table/features/ingredients/domain/quantity.dart';
import 'package:kitchen_table/features/recipes/domain/recipe.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_detail.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_draft.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_ingredient.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_step.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_translation.dart';

/// The editor's logic lives on [RecipeDraft] as pure functions precisely so it
/// can be tested here, with no Supabase client and no widget tree.

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

RecipeDraft _withLines(List<String> texts) => RecipeDraft(
      lines: <RecipeDraftLine>[
        for (final (int index, String text) in texts.indexed)
          RecipeDraftLine(localId: index, rawText: text),
      ],
    );

void main() {
  group('saving', () {
    test('blank lines are dropped, and the rest are renumbered', () {
      final RecipeDraft draft =
          _withLines(<String>['200 g šargarepe', '   ', 'so po ukusu', '']);

      final List<RecipeIngredient> lines = draft.toIngredients();

      expect(lines.map((RecipeIngredient l) => l.rawText),
          <String>['200 g šargarepe', 'so po ukusu']);
      // Positions are contiguous from zero even though line 1 was dropped.
      expect(lines.map((RecipeIngredient l) => l.position), <int>[0, 1]);
    });

    test('an all-blank line list saves as no lines rather than as a bad row',
        () {
      // recipe_ingredients.raw_text carries length(trim(raw_text)) > 0, so
      // sending the editor's spare empty field would fail the whole
      // transaction.
      expect(RecipeDraft.empty().toIngredients(), isEmpty);
      expect(RecipeDraft.empty().toSteps(), isEmpty);
    });

    test('raw text is trimmed but otherwise untouched', () {
      final List<RecipeIngredient> lines =
          _withLines(<String>['  2 šolje glatkog brašna, prosejano  '])
              .toIngredients();

      expect(lines.single.rawText, '2 šolje glatkog brašna, prosejano');
    });

    test('blank steps are dropped and the rest renumbered', () {
      final RecipeDraft draft = RecipeDraft(
        steps: const <RecipeDraftStep>[
          RecipeDraftStep(localId: 0, text: 'Zagrej rernu.'),
          RecipeDraftStep(localId: 1, text: '  '),
          RecipeDraftStep(localId: 2, text: 'Umuti jaja.'),
        ],
      );

      final List<RecipeStep> steps = draft.toSteps();

      expect(steps.map((RecipeStep s) => s.text),
          <String>['Zagrej rernu.', 'Umuti jaja.']);
      expect(steps.map((RecipeStep s) => s.position), <int>[0, 1]);
    });

    test('structured fields survive the trip to a RecipeIngredient', () {
      final DateTime matchedAt = DateTime.utc(2026, 9, 7, 12);
      final RecipeDraft draft = RecipeDraft(
        lines: <RecipeDraftLine>[
          RecipeDraftLine(
            localId: 0,
            rawText: '200 g šargarepe',
            ingredientId: 'i1',
            quantity: Quantity.whole(200),
            unitCode: 'g',
            matchMethod: MatchMethod.manual,
            matchConfidence: 1,
            matchedAt: matchedAt,
          ),
        ],
      );

      final RecipeIngredient line = draft.toIngredients().single;

      expect(line.ingredientId, 'i1');
      expect(line.quantity, Quantity.whole(200));
      expect(line.unitCode, 'g');
      expect(line.matchMethod, MatchMethod.manual);
      expect(line.matchedAt, matchedAt);
    });
  });

  group('editing lines', () {
    test('a reorder moves the line, using onReorderItem indices', () {
      // ReorderableListView.onReorderItem hands over a newIndex that is
      // already adjusted for the lifted child, so dragging the first line to
      // the end of three reports (0, 2).
      final RecipeDraft draft = _withLines(<String>['a', 'b', 'c'])
          .reorderLines(0, 2);

      expect(draft.lines.map((RecipeDraftLine l) => l.rawText),
          <String>['b', 'c', 'a']);
    });

    test('a reorder upwards moves the line', () {
      final RecipeDraft draft = _withLines(<String>['a', 'b', 'c'])
          .reorderLines(2, 0);

      expect(draft.lines.map((RecipeDraftLine l) => l.rawText),
          <String>['c', 'a', 'b']);
    });

    test('a new line never reuses a live id after a removal', () {
      // Ids key the widgets. Allocating from the list length would hand out 1
      // again here, and the new empty row would inherit the removed row's
      // editing state.
      final RecipeDraft draft =
          _withLines(<String>['a', 'b', 'c']).removeLine(1).addLine();

      final List<int> ids =
          draft.lines.map((RecipeDraftLine l) => l.localId).toList();
      expect(ids, <int>[0, 2, 3]);
      expect(ids.toSet().length, ids.length);
    });

    test('insertLineAfter puts a blank line right after the id, in its '
        'section, with a fresh id', () {
      final RecipeDraft draft = RecipeDraft(
        lines: const <RecipeDraftLine>[
          RecipeDraftLine(localId: 0, rawText: 'a', section: 'Za testo'),
          RecipeDraftLine(localId: 4, rawText: 'b', section: 'Za testo'),
          RecipeDraftLine(localId: 2, rawText: 'c', section: 'Fil'),
        ],
      ).insertLineAfter(0);

      expect(draft.lines.map((RecipeDraftLine l) => l.rawText),
          <String>['a', '', 'b', 'c']);
      final RecipeDraftLine inserted = draft.lines[1];
      // Typing on inside a section stays in it (D156's runs).
      expect(inserted.section, 'Za testo');
      // Above the high-water mark, not the list length.
      expect(inserted.localId, 5);
    });

    test('insertLineAfter after the last line, or a line with no section',
        () {
      final RecipeDraft draft =
          _withLines(<String>['a', 'b']).insertLineAfter(1);

      expect(draft.lines.map((RecipeDraftLine l) => l.rawText),
          <String>['a', 'b', '']);
      expect(draft.lines.last.section, isNull);
    });

    test('insertLineAfter an unknown id appends, like addLine', () {
      final RecipeDraft draft =
          _withLines(<String>['a', 'b']).insertLineAfter(99);

      expect(draft.lines.map((RecipeDraftLine l) => l.rawText),
          <String>['a', 'b', '']);
      expect(draft.lines.last.localId, 2);
    });

    test('replacing a line leaves its neighbours alone', () {
      final RecipeDraft draft = _withLines(<String>['a', 'b', 'c']);

      final RecipeDraft next = draft.replaceLine(
        draft.lines[1].copyWith(ingredientId: 'i1', displayName: 'brašno'),
      );

      expect(next.lines[0].ingredientId, isNull);
      expect(next.lines[1].ingredientId, 'i1');
      expect(next.lines[2].ingredientId, isNull);
    });

    test('editing one line does not disturb another line’s match decision',
        () {
      // D7: a manual link is a human decision and nothing incidental may
      // overwrite it.
      final RecipeDraft draft = RecipeDraft(
        lines: const <RecipeDraftLine>[
          RecipeDraftLine(
            localId: 0,
            rawText: 'šargarepa',
            ingredientId: 'i1',
            matchMethod: MatchMethod.manual,
          ),
          RecipeDraftLine(localId: 1, rawText: ''),
        ],
      );

      final RecipeDraft next = draft.setLineText(1, 'so');

      expect(next.lines[0].ingredientId, 'i1');
      expect(next.lines[0].isManual, isTrue);
      expect(next.lines[1].rawText, 'so');
    });
  });

  group('loading and folding back', () {
    test('fromDetail carries the recipe and its children', () {
      final RecipeDetail detail = RecipeDetail(
        recipe: _torta,
        readingLocale: 'sr',
        ingredients: const <RecipeIngredient>[
          RecipeIngredient(
            position: 0,
            rawText: '200 g šargarepe',
            ingredientId: 'i1',
            displayName: 'šargarepa',
          ),
        ],
        steps: const <RecipeStep>[
          RecipeStep(position: 0, text: 'Zagrej rernu.'),
        ],
      );

      final RecipeDraft draft = RecipeDraft.fromDetail(detail);

      expect(draft.recipeId, 'r1');
      expect(draft.title, 'Šargarepa torta');
      expect(draft.servings, 8);
      expect(draft.originalLocale, 'sr');
      expect(draft.lines.single.rawText, '200 g šargarepe');
      expect(draft.lines.single.displayName, 'šargarepa');
      expect(draft.steps.single.text, 'Zagrej rernu.');
      // Local ids are handed out on load, since the server rows have none the
      // widget layer can use.
      expect(draft.lines.single.localId, 0);
    });

    test('toRecipe folds the edits onto the row without losing its owner', () {
      final RecipeDraft draft = RecipeDraft.fromDetail(
        const RecipeDetail(recipe: _torta, readingLocale: 'sr'),
      ).copyWith(title: 'Torta od šargarepe', servings: 12);

      final Recipe updated = draft.toRecipe();

      expect(updated.id, 'r1');
      expect(updated.title, 'Torta od šargarepe');
      expect(updated.servings, 12);
      // Not the editor's to change, and never sent in an update payload.
      expect(updated.householdId, 'h1');
      expect(updated.createdBy, 'u1');
      expect(updated.sourceType, RecipeSourceType.manual);
    });

    test('toRecipe refuses a draft that has never been saved', () {
      // There is no household id or author to preserve yet -- that draft has
      // to go through RecipeRepository.create instead.
      expect(RecipeDraft.empty().toRecipe, throwsStateError);
    });

    test('a new draft has no recipe id until it is given one', () {
      expect(RecipeDraft.empty().recipeId, isNull);
      expect(
        RecipeDraft.empty().copyWith(source: _torta).recipeId,
        'r1',
      );
    });

    test('imagePath survives fromDetail and reaches toRecipe unchanged', () {
      final Recipe withPhoto =
          _torta.copyWith(imagePath: 'h1/123.jpg', imageUrl: 'https://x/1');
      final RecipeDraft draft =
          RecipeDraft.fromDetail(
              RecipeDetail(recipe: withPhoto, readingLocale: 'sr'));

      expect(draft.imagePath, 'h1/123.jpg');

      final Recipe updated = draft.toRecipe();
      expect(updated.imagePath, 'h1/123.jpg');
    });

    test('clearing imagePath reaches toRecipe as null -- removing a photo '
        'must actually reach the wire', () {
      final Recipe withPhoto = _torta.copyWith(imagePath: 'h1/123.jpg');
      final RecipeDraft draft = RecipeDraft.fromDetail(
        RecipeDetail(recipe: withPhoto, readingLocale: 'sr'),
      ).copyWith(imagePath: null);

      final Recipe updated = draft.toRecipe();
      expect(updated.imagePath, isNull);
    });
  });

  group('headings, notes and the end note (D153)', () {
    // Today's editor shows none of these; they must ride through a save
    // untouched or the first edit of an imported recipe would wipe them.
    const List<RecipeStep> structured = <RecipeStep>[
      RecipeStep(position: 0, text: 'Za testo', kind: RecipeStepKind.heading),
      RecipeStep(position: 1, text: 'Umesiti testo.', timerSeconds: 600),
      RecipeStep(position: 2, text: 'Može i dan ranije.', kind: RecipeStepKind.note),
      RecipeStep(position: 3, text: 'Peći.'),
    ];

    test('fromDetail then toSteps round-trips kinds and positions', () {
      final RecipeDraft draft = RecipeDraft.fromDetail(RecipeDetail(
        recipe: _torta,
        readingLocale: 'sr',
        steps: structured,
      ));

      expect(draft.toSteps(), structured);
    });

    test('a blank heading or note is dropped like a blank step', () {
      const RecipeDraft draft = RecipeDraft(steps: <RecipeDraftStep>[
        RecipeDraftStep(localId: 0, text: '  ', kind: RecipeStepKind.heading),
        RecipeDraftStep(localId: 1, text: 'Umesiti testo.'),
        RecipeDraftStep(localId: 2, text: '', kind: RecipeStepKind.note),
      ]);

      final List<RecipeStep> steps = draft.toSteps();

      expect(steps.single.text, 'Umesiti testo.');
      expect(steps.single.position, 0);
    });

    test('a timer is not emitted on a heading or a note', () {
      // recipe_steps refuses one there; a stale value must not fail a save.
      const RecipeDraft draft = RecipeDraft(steps: <RecipeDraftStep>[
        RecipeDraftStep(
            localId: 0,
            text: 'Za testo',
            timerSeconds: 60,
            kind: RecipeStepKind.heading),
        RecipeDraftStep(
            localId: 1,
            text: 'Pazi.',
            timerSeconds: 60,
            kind: RecipeStepKind.note),
        RecipeDraftStep(localId: 2, text: 'Peći.', timerSeconds: 60),
      ]);

      expect(draft.toSteps().map((RecipeStep s) => s.timerSeconds),
          <int?>[null, null, 60]);
    });

    test('addStep adds the kind it is given, a step by default', () {
      final RecipeDraft draft = const RecipeDraft()
          .addStep()
          .addStep(kind: RecipeStepKind.heading)
          .addStep(kind: RecipeStepKind.note);

      expect(draft.steps.map((RecipeDraftStep s) => s.kind), <RecipeStepKind>[
        RecipeStepKind.step,
        RecipeStepKind.heading,
        RecipeStepKind.note,
      ]);
      expect(draft.steps.map((RecipeDraftStep s) => s.localId), <int>[0, 1, 2]);
    });

    test('insertStep puts a row back at its index', () {
      const RecipeDraft draft = RecipeDraft(steps: <RecipeDraftStep>[
        RecipeDraftStep(localId: 0, text: 'Umesiti testo.'),
        RecipeDraftStep(localId: 1, text: 'Peći.'),
      ]);

      final RecipeDraft next =
          draft.insertStep(1, kind: RecipeStepKind.heading, text: 'Fil');

      expect(next.steps.map((RecipeDraftStep s) => s.text),
          <String>['Umesiti testo.', 'Fil', 'Peći.']);
      expect(next.steps[1].kind, RecipeStepKind.heading);
    });

    test('insertStep clamps the index to the list', () {
      const RecipeDraft draft = RecipeDraft(steps: <RecipeDraftStep>[
        RecipeDraftStep(localId: 0, text: 'Peći.'),
      ]);

      expect(
        draft
            .insertStep(9, kind: RecipeStepKind.heading, text: 'Kraj')
            .steps
            .last
            .text,
        'Kraj',
      );
      expect(
        draft
            .insertStep(-3, kind: RecipeStepKind.heading, text: 'Početak')
            .steps
            .first
            .text,
        'Početak',
      );
    });

    test('insertStep allocates a fresh id even when the removed row held '
        'the max', () {
      const RecipeDraft draft = RecipeDraft(steps: <RecipeDraftStep>[
        RecipeDraftStep(localId: 0, text: 'Umesiti testo.'),
        RecipeDraftStep(localId: 1, text: 'Fil', kind: RecipeStepKind.heading),
      ]);

      // Remove the max-id heading, add a step (which takes id 1 again),
      // then Undo: the heading must not come back as id 1 too.
      final RecipeDraft next = draft
          .removeStep(1)
          .addStep()
          .insertStep(1, kind: RecipeStepKind.heading, text: 'Fil');

      final List<int> ids =
          next.steps.map((RecipeDraftStep s) => s.localId).toList();
      expect(ids.toSet().length, ids.length);
      expect(next.steps[1].localId, 2);
    });

    test('notes survive fromDetail and reach toRecipe unchanged', () {
      final RecipeDraft draft = RecipeDraft.fromDetail(RecipeDetail(
        recipe: _torta.copyWith(notes: '- Čuva se dva dana.'),
        readingLocale: 'sr',
      ));

      expect(draft.notes, '- Čuva se dva dana.');
      expect(draft.toRecipe().notes, '- Čuva se dva dana.');
    });
  });

  group('editing sections', () {
    // a, b in Testo; c continues it with no section of its own (D156); d, e
    // in Fil.
    RecipeDraft sectioned() => const RecipeDraft(
          lines: <RecipeDraftLine>[
            RecipeDraftLine(localId: 0, rawText: 'a', section: 'Testo'),
            RecipeDraftLine(localId: 1, rawText: 'b', section: 'Testo'),
            RecipeDraftLine(localId: 2, rawText: 'c'),
            RecipeDraftLine(localId: 3, rawText: 'd', section: 'Fil'),
            RecipeDraftLine(localId: 4, rawText: 'e', section: 'Fil'),
          ],
        );

    List<String?> sections(RecipeDraft d) =>
        d.lines.map((RecipeDraftLine l) => l.section).toList();
    List<String> texts(RecipeDraft d) =>
        d.lines.map((RecipeDraftLine l) => l.rawText).toList();

    test('a rename writes every line of the run, the null continuation too',
        () {
      final RecipeDraft draft = sectioned()
          .setSections(<int, String?>{0: 'Kore', 1: 'Kore', 2: 'Kore'});

      expect(sections(draft), <String?>['Kore', 'Kore', 'Kore', 'Fil', 'Fil']);
    });

    test('a blank name is stored as null, a name being typed as typed', () {
      final RecipeDraft draft =
          sectioned().setSections(<int, String?>{0: '  ', 1: 'Fil '});

      expect(sections(draft), <String?>[null, 'Fil ', null, 'Fil', 'Fil']);
    });

    test('removing the first section leaves its lines headingless', () {
      final RecipeDraft draft = sectioned()
          .setSections(<int, String?>{0: null, 1: null, 2: null});

      expect(sections(draft), <String?>[null, null, null, 'Fil', 'Fil']);
    });

    test('removing a middle section joins its lines to the group above', () {
      // The line above Fil's heading is c, whose own section is null but
      // which reads as Testo: the editor passes the group's name, so the
      // run joins Testo rather than becoming a null continuation.
      final RecipeDraft draft =
          sectioned().setSections(<int, String?>{3: 'Testo', 4: 'Testo'});

      expect(texts(draft), <String>['a', 'b', 'c', 'd', 'e']);
      expect(sections(draft),
          <String?>['Testo', 'Testo', null, 'Testo', 'Testo']);
    });

    test('Undo restores a mixed map, ignoring ids that have gone', () {
      final RecipeDraft removed = sectioned()
          .setSections(<int, String?>{0: null, 1: null, 2: null})
          .removeLine(1);

      final RecipeDraft undone = removed.setSections(
        <int, String?>{0: 'Testo', 1: 'Testo', 2: null},
      );

      expect(texts(undone), <String>['a', 'c', 'd', 'e']);
      expect(sections(undone), <String?>['Testo', null, 'Fil', 'Fil']);
    });

    test('a line moved into a group takes its section', () {
      // a dropped between Fil's heading and d.
      final RecipeDraft draft = sectioned().moveLine(0, 2, section: 'Fil');

      expect(texts(draft), <String>['b', 'c', 'a', 'd', 'e']);
      expect(sections(draft), <String?>['Testo', null, 'Fil', 'Fil', 'Fil']);
    });

    test('a line moved above the first heading takes null', () {
      final RecipeDraft draft = sectioned().moveLine(4, 0, section: null);

      expect(texts(draft), <String>['e', 'a', 'b', 'c', 'd']);
      expect(sections(draft),
          <String?>[null, 'Testo', 'Testo', null, 'Fil']);
    });

    test('a run moves up, keeping its sections', () {
      final RecipeDraft draft = sectioned().moveLines(3, 5, 0);

      expect(texts(draft), <String>['d', 'e', 'a', 'b', 'c']);
      expect(sections(draft),
          <String?>['Fil', 'Fil', 'Testo', 'Testo', null]);
    });

    test('a run moves down', () {
      final RecipeDraft draft = sectioned().moveLines(0, 3, 5);

      expect(texts(draft), <String>['d', 'e', 'a', 'b', 'c']);
    });

    test('a run moved onto itself is a no-op', () {
      final RecipeDraft draft = sectioned();

      expect(identical(draft.moveLines(0, 3, 0), draft), isTrue);
      expect(identical(draft.moveLines(0, 3, 3), draft), isTrue);
      expect(identical(draft.moveLines(3, 5, 4), draft), isTrue);
    });

    test('a run moves to the end', () {
      final RecipeDraft draft = const RecipeDraft(
        lines: <RecipeDraftLine>[
          RecipeDraftLine(localId: 0, rawText: 'a', section: 'Testo'),
          RecipeDraftLine(localId: 1, rawText: 'b', section: 'Fil'),
          RecipeDraftLine(localId: 2, rawText: 'c', section: 'Krem'),
        ],
      ).moveLines(0, 1, 3);

      expect(texts(draft), <String>['b', 'c', 'a']);
    });

    test('a saved section is trimmed, and a blank one saves as null', () {
      final RecipeDraft draft = const RecipeDraft(
        lines: <RecipeDraftLine>[
          RecipeDraftLine(localId: 0, rawText: 'a', section: 'Fil '),
          RecipeDraftLine(localId: 1, rawText: 'b', section: '  '),
        ],
      );

      expect(
        draft.toIngredients().map((RecipeIngredient l) => l.section),
        <String?>['Fil', null],
      );
    });
  });

  group('canTranslateInto -- the one definition D85 depends on', () {
    test('false when the target is the recipe\'s own original locale', () {
      expect(
        canTranslateInto(
          originalLocale: 'sr',
          target: 'sr',
          existingLocales: <String>[],
        ),
        isFalse,
      );
    });

    test('false once a translation exists for the target, whether it was '
        'reviewed or not -- D85 makes no distinction', () {
      expect(
        canTranslateInto(
          originalLocale: 'sr',
          target: 'en',
          existingLocales: <String>['en'], // unreviewed machine pass
        ),
        isFalse,
      );
      expect(
        canTranslateInto(
          originalLocale: 'sr',
          target: 'en',
          existingLocales: <String>['en'], // stands in for a reviewed one too
        ),
        isFalse,
      );
    });

    test('true otherwise', () {
      expect(
        canTranslateInto(
          originalLocale: 'sr',
          target: 'en',
          existingLocales: <String>[],
        ),
        isTrue,
      );
    });
  });

  group('translating from the editor', () {
    test('translationTargetLocale is the other language, following '
        'originalLocale rather than a reader\'s ambient locale', () {
      expect(
        const RecipeDraft(originalLocale: 'sr').translationTargetLocale,
        'en',
      );
      expect(
        const RecipeDraft(originalLocale: 'en').translationTargetLocale,
        'sr',
      );
    });

    test('translationTargetLocale flips when setLocale flips originalLocale',
        () {
      final RecipeDraft draft = const RecipeDraft(originalLocale: 'sr')
          .copyWith(originalLocale: 'en');
      expect(draft.translationTargetLocale, 'sr');
    });

    test('fromDetail carries which locales already have a translation', () {
      final RecipeDetail detail = RecipeDetail(
        recipe: _torta,
        readingLocale: 'sr',
        translations: const <RecipeTranslation>[
          RecipeTranslation(locale: 'en', title: 'Carrot cake'),
        ],
      );

      final RecipeDraft draft = RecipeDraft.fromDetail(detail);

      expect(draft.translatedLocales, <String>['en']);
      expect(draft.canTranslate, isFalse);
    });

    test('canTranslate is true for a brand-new, never-saved draft', () {
      expect(RecipeDraft.empty().copyWith(originalLocale: 'sr').canTranslate,
          isTrue);
    });

    test('withTranslatedLocale is idempotent', () {
      final RecipeDraft once =
          RecipeDraft.empty().withTranslatedLocale('en');
      final RecipeDraft twice = once.withTranslatedLocale('en');

      expect(once.translatedLocales, <String>['en']);
      expect(twice.translatedLocales, <String>['en']);
    });
  });
}

// ParsedRecipe -> RecipeDraft, the seam between what the server read and what
// the confirm screen edits.
//
// Pure domain, so no ProviderScope and no stubbing. What is worth asserting is
// the three rules that are easy to break silently: rule 3 (rawText survives
// every line), D7 (match provenance is carried, not flattened), and the
// autoAccept decision -- which, if it went the other way, would throw away the
// whole of part 2's LLM tier.

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/features/import/domain/parsed_recipe.dart';
import 'package:kitchen_table/features/import/domain/parsed_recipe_draft.dart';
import 'package:kitchen_table/features/ingredients/domain/ingredient_match.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_draft.dart';

ParsedIngredientLine _line({
  required String rawText,
  String? name,
  String? ingredientId,
  String? displayName,
  ParsedMatchMethod? matchMethod,
  double? matchConfidence,
  bool autoAccept = false,
  ParsedQuantity? quantity,
  String? unitCode,
  String? note,
  String? section,
  bool isOptional = false,
}) =>
    ParsedIngredientLine(
      rawText: rawText,
      name: name,
      ingredientId: ingredientId,
      displayName: displayName,
      matchMethod: matchMethod,
      matchConfidence: matchConfidence,
      autoAccept: autoAccept,
      quantity: quantity,
      unitCode: unitCode,
      note: note,
      section: section,
      isOptional: isOptional,
    );

ParsedRecipe _recipe(List<ParsedIngredientLine> lines,
        {List<ParsedStep> steps = const <ParsedStep>[]}) =>
    ParsedRecipe(
      title: 'zzz Šargarepa torta',
      originalLocale: ParsedLocale.SR,
      ingredients: lines,
      steps: steps,
    );

void main() {
  test('rawText survives every line (rule 3)', () {
    final ParsedRecipe parsed = _recipe(<ParsedIngredientLine>[
      _line(rawText: '200 g šargarepe', name: 'šargarepe'),
      _line(rawText: 'za posluživanje', name: 'za posluživanje'),
      _line(rawText: '   '),
    ]);

    final ImportReview review = draftFromParsed(parsed);

    expect(
      review.draft.lines.map((RecipeDraftLine l) => l.rawText),
      <String>['200 g šargarepe', 'za posluživanje', '   '],
    );
  });

  test('an auto-accepted match arrives applied and unmarked', () {
    final ParsedRecipe parsed = _recipe(<ParsedIngredientLine>[
      _line(
        rawText: '200 g šargarepe',
        name: 'šargarepe',
        ingredientId: 'ing-1',
        displayName: 'šargarepa',
        matchMethod: ParsedMatchMethod.ALIAS,
        matchConfidence: 1,
        autoAccept: true,
      ),
    ]);

    final ImportReview review = draftFromParsed(parsed);
    final RecipeDraftLine line = review.draft.lines.single;

    expect(line.isMatched, isTrue);
    expect(line.displayName, 'šargarepa');
    expect(line.matchMethod, MatchMethod.alias);
    expect(line.matchedAt, isNotNull);
    expect(review.needsAttention, isEmpty);
  });

  test('an LLM match is KEPT and marked, not discarded', () {
    // The decision this whole mapping turns on. Part 2 never sets autoAccept
    // on an LLM answer, deliberately -- so dropping every non-auto-accepted
    // match would throw away the entire tier 4 result and leave the cook
    // retyping what the model already worked out.
    final ParsedRecipe parsed = _recipe(<ParsedIngredientLine>[
      _line(
        rawText: '1 kesica praška za pecivo',
        name: 'praška za pecivo',
        ingredientId: 'ing-2',
        displayName: 'prašak za pecivo',
        matchMethod: ParsedMatchMethod.LLM,
        matchConfidence: 0.82,
        autoAccept: false,
      ),
    ]);

    final ImportReview review = draftFromParsed(parsed);
    final RecipeDraftLine line = review.draft.lines.single;

    expect(line.ingredientId, 'ing-2');
    expect(line.matchMethod, MatchMethod.llm, reason: 'provenance is D7');
    expect(line.matchConfidence, 0.82);
    expect(review.needsAttention, <int>{0},
        reason: 'the cook is asked to look, not left to retype');
  });

  test('an unmatched line is neither matched nor flagged', () {
    // Nothing was proposed, so there is nothing to second-guess. Flagging it
    // would make the summary count lines that need typing as lines that need
    // checking.
    final ParsedRecipe parsed = _recipe(<ParsedIngredientLine>[
      _line(rawText: 'za posluživanje', name: 'za posluživanje'),
    ]);

    final ImportReview review = draftFromParsed(parsed);

    expect(review.draft.lines.single.isMatched, isFalse);
    expect(review.draft.lines.single.matchedAt, isNull);
    expect(review.needsAttention, isEmpty);
  });

  test('quantities come across as exact fractions, ranges included (rule 5)',
      () {
    final ParsedRecipe parsed = _recipe(<ParsedIngredientLine>[
      _line(
        rawText: '1 1/2 šolje mleka',
        quantity: const ParsedQuantity(num: 3, den: 2),
      ),
      _line(
        rawText: '2-3 kašike ulja',
        quantity: const ParsedQuantity(num: 2, den: 1, maxNum: 3, maxDen: 1),
      ),
    ]);

    final ImportReview review = draftFromParsed(parsed);

    expect(review.draft.lines[0].quantity!.numerator, 3);
    expect(review.draft.lines[0].quantity!.denominator, 2);
    expect(review.draft.lines[0].quantity!.isRange, isFalse);

    expect(review.draft.lines[1].quantity!.isRange, isTrue);
    expect(review.draft.lines[1].quantity!.maxNumerator, 3);
  });

  test('locale, section, note and optional are carried through', () {
    final ParsedRecipe parsed = ParsedRecipe(
      title: 'zzz Pita',
      originalLocale: ParsedLocale.EN,
      ingredients: <ParsedIngredientLine>[
        _line(
          rawText: '100 g kajmaka (opciono)',
          name: 'kajmaka',
          note: 'opciono',
          isOptional: true,
          section: 'Za fil',
        ),
      ],
      steps: const <ParsedStep>[],
    );

    final ImportReview review = draftFromParsed(parsed);
    final RecipeDraftLine line = review.draft.lines.single;

    expect(review.draft.originalLocale, 'en');
    expect(line.section, 'Za fil');
    expect(line.note, 'opciono');
    expect(line.isOptional, isTrue);
  });

  test('localIds are unique, so a reorder key cannot collide', () {
    final ParsedRecipe parsed = _recipe(<ParsedIngredientLine>[
      _line(rawText: 'a'),
      _line(rawText: 'b'),
      _line(rawText: 'c'),
    ]);

    final ImportReview review = draftFromParsed(parsed);
    final Set<int> ids =
        review.draft.lines.map((RecipeDraftLine l) => l.localId).toSet();

    expect(ids.length, 3);
  });

  test('an empty import still opens with something to type into', () {
    // RecipeDraft.empty() seeds one blank line and one blank step for the same
    // reason: a screen with nothing on it offers the cook no way in.
    final ImportReview review =
        draftFromParsed(_recipe(const <ParsedIngredientLine>[]));

    expect(review.draft.lines, hasLength(1));
    expect(review.draft.lines.single.rawText, '');
    expect(review.draft.steps, hasLength(1));
  });

  test('the draft has no source, so nothing can mistake it for saved', () {
    // source is what RecipeDraft uses to decide update-vs-create (D37). An
    // import never takes that path -- save_imported_recipe creates the row --
    // and a non-null source here would be a claim that a recipe already exists.
    final ImportReview review =
        draftFromParsed(_recipe(<ParsedIngredientLine>[_line(rawText: 'a')]));

    expect(review.draft.source, isNull);
    expect(review.draft.recipeId, isNull);
  });

  test('steps keep their text and timer', () {
    final ImportReview review = draftFromParsed(
      _recipe(
        <ParsedIngredientLine>[_line(rawText: 'a')],
        steps: const <ParsedStep>[
          ParsedStep(text: 'Zagrejati rernu.'),
          ParsedStep(text: 'Peći.', timerSeconds: 2400),
        ],
      ),
    );

    expect(review.draft.steps.map((RecipeDraftStep s) => s.text),
        <String>['Zagrejati rernu.', 'Peći.']);
    expect(review.draft.steps[1].timerSeconds, 2400);
  });
}

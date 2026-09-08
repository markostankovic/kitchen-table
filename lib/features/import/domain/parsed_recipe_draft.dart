/// `ParsedRecipe` -> `RecipeDraft`: the seam between what the server read and
/// what the confirm screen edits.
///
/// A cross-feature import into `domain/` only, which `tool/check_layers.dart`
/// allows. The alternative -- a third recipe-shaped model owned by `import/` --
/// would mean the confirm screen could not reuse the 1c line editor, which is
/// the whole reason D43 moved that editor to `core/`.
///
/// Pure Dart (rule 7).
library;

import '../../ingredients/domain/ingredient_match.dart';
import '../../ingredients/domain/quantity.dart';
import '../../recipes/domain/recipe_draft.dart';
import 'parsed_recipe.dart';

/// The lines whose match a human should look at before saving.
///
/// A line is on this list when the server proposed an ingredient but did not
/// mark it auto-accept -- a fuzzy hit below the 0.75 line, or anything the LLM
/// tier chose, which never auto-accepts by design.
///
/// The alternative was to drop those matches entirely and show the lines as
/// unmatched. That would be safer-looking and worse: it would throw away the
/// whole of tier 4, which is the expensive tier, and leave the cook retyping
/// what the model already worked out. D8 asks for a human to review an import,
/// not for the machine's work to be hidden from them.
typedef ImportReview = ({RecipeDraft draft, Set<int> needsAttention});

ImportReview draftFromParsed(ParsedRecipe parsed) {
  final List<RecipeDraftLine> lines = <RecipeDraftLine>[];
  final Set<int> needsAttention = <int>{};

  for (final (int index, ParsedIngredientLine line)
      in parsed.ingredients.indexed) {
    // localId from the enumerate index, as RecipeDraft.fromDetail does. The
    // draft's own allocator is private and only ever hands out ids above the
    // high-water mark, which is what a later addLine() will do.
    lines.add(
      RecipeDraftLine(
        localId: index,
        // Rule 3, first and unconditionally.
        rawText: line.rawText,
        section: line.section,
        ingredientId: line.ingredientId,
        displayName: line.displayName,
        quantity: _toQuantity(line.quantity),
        unitCode: line.unitCode,
        note: line.note,
        isOptional: line.isOptional,
        matchMethod: _toMatchMethod(line.matchMethod),
        matchConfidence: line.matchConfidence,
        // Set only where there is a match to have been made, so a line the
        // cook never touched does not claim a timestamp.
        matchedAt: line.ingredientId == null ? null : DateTime.now(),
      ),
    );

    if (line.ingredientId != null && !line.autoAccept) {
      needsAttention.add(index);
    }
  }

  // A recipe with no ingredients would otherwise open with nothing to type
  // into. RecipeDraft.empty() seeds one blank line for the same reason.
  if (lines.isEmpty) {
    lines.add(const RecipeDraftLine(localId: 0, rawText: ''));
  }

  final List<RecipeDraftStep> steps = <RecipeDraftStep>[
    for (final (int index, ParsedStep step) in parsed.steps.indexed)
      RecipeDraftStep(
        localId: index,
        text: step.text,
        timerSeconds: step.timerSeconds,
      ),
  ];

  return (
    draft: RecipeDraft(
      // `source` stays null. The recipe does not exist yet, and
      // save_imported_recipe is what creates it -- so unlike the manual editor
      // there is no id to keep between two round trips (D44 replaces D37's
      // two-step for this path).
      title: parsed.title,
      description: parsed.description,
      servings: parsed.servings,
      prepMinutes: parsed.prepMinutes,
      cookMinutes: parsed.cookMinutes,
      originalLocale: _toLocale(parsed.originalLocale),
      lines: List<RecipeDraftLine>.unmodifiable(lines),
      steps: List<RecipeDraftStep>.unmodifiable(
        steps.isEmpty
            ? <RecipeDraftStep>[const RecipeDraftStep(localId: 0, text: '')]
            : steps,
      ),
    ),
    needsAttention: Set<int>.unmodifiable(needsAttention),
  );
}

/// Locale codes are `sr` and `en`, nothing else (CLAUDE.md conventions).
String _toLocale(ParsedLocale locale) => switch (locale) {
      ParsedLocale.SR => 'sr',
      ParsedLocale.EN => 'en',
    };

/// D7's vocabulary, minus `manual`.
///
/// `ParsedMatchMethod` has no `manual` value and must not gain one: a machine
/// pass cannot produce a human decision, and only the confirm screen promotes
/// a line to `manual`.
MatchMethod? _toMatchMethod(ParsedMatchMethod? method) => switch (method) {
      null => null,
      ParsedMatchMethod.EXACT => MatchMethod.exact,
      ParsedMatchMethod.ALIAS => MatchMethod.alias,
      ParsedMatchMethod.FUZZY => MatchMethod.fuzzy,
      ParsedMatchMethod.LLM => MatchMethod.llm,
    };

/// Integer fractions, never floats (rule 5). The server sends the pair it
/// parsed; this only chooses between the two constructors.
Quantity? _toQuantity(ParsedQuantity? quantity) {
  if (quantity == null) return null;
  final int? maxNum = quantity.maxNum;
  final int? maxDen = quantity.maxDen;
  if (maxNum != null && maxDen != null) {
    return Quantity.range(
      numerator: quantity.num,
      denominator: quantity.den,
      maxNumerator: maxNum,
      maxDenominator: maxDen,
    );
  }
  return Quantity.fraction(quantity.num, quantity.den);
}

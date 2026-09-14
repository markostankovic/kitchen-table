// Phase 3 part 2 shipped RecipeDetail's translation getters
// (canTranslate/displayTitle/displayDescription/displaySteps/
// isShowingMachineTranslation) with no Dart test anywhere -- this file is
// that backfill, alongside the two getters part 3 adds (canReview,
// isReviewedTranslation). Pure unit tests: no Supabase client, no widget
// tree, `RecipeDraft`'s own precedent for how this project tests domain
// logic in isolation.

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/features/recipes/data/dto/recipe_dto.dart';
import 'package:kitchen_table/features/recipes/domain/recipe.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_detail.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_step.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_translation.dart';

const Recipe _torta = Recipe(
  id: 'r1',
  householdId: 'h1',
  title: 'Šargarepa torta',
  description: 'Vlažna torta sa šargarepom.',
  originalLocale: 'sr',
  sourceType: RecipeSourceType.manual,
  status: RecipeStatus.draft,
  createdBy: 'u1',
  servings: 8,
);

const List<RecipeStep> _originalSteps = <RecipeStep>[
  RecipeStep(position: 0, text: 'Umutiti sastojke.'),
  RecipeStep(position: 1, text: 'Peći 40 minuta.'),
];

RecipeTranslation _machineTranslation({String? description = 'A moist carrot cake.'}) =>
    RecipeTranslation(
      locale: 'en',
      title: 'Carrot cake',
      description: description,
      steps: const <RecipeStep>[
        RecipeStep(position: 0, text: 'Mix the ingredients.'),
        RecipeStep(position: 1, text: 'Bake for 40 minutes.'),
      ],
    );

RecipeTranslation _reviewedTranslation() => _machineTranslation().copyWith(
      isMachineGenerated: false,
      reviewedBy: 'u2',
      reviewedAt: DateTime.utc(2026, 9, 14),
    );

void main() {
  group('reading the recipe\'s own language', () {
    final RecipeDetail detail = RecipeDetail(
      recipe: _torta,
      readingLocale: 'sr',
      steps: _originalSteps,
      translations: <RecipeTranslation>[_machineTranslation()],
    );

    test('there is no "translation" even though one exists for another locale', () {
      expect(detail.translation, isNull);
    });

    test('canTranslate is false -- there is nothing to translate INTO', () {
      expect(detail.canTranslate, isFalse);
    });

    test('canReview is false -- there is nothing in this locale to review', () {
      expect(detail.canReview, isFalse);
    });

    test('isShowingMachineTranslation and isReviewedTranslation are both false', () {
      expect(detail.isShowingMachineTranslation, isFalse);
      expect(detail.isReviewedTranslation, isFalse);
    });

    test('every display getter falls back to the original', () {
      expect(detail.displayTitle, _torta.title);
      expect(detail.displayDescription, _torta.description);
      expect(detail.displaySteps, _originalSteps);
    });
  });

  group('reading a foreign locale with no translation yet', () {
    final RecipeDetail detail = RecipeDetail(
      recipe: _torta,
      readingLocale: 'en',
      steps: _originalSteps,
    );

    test('canTranslate is true', () => expect(detail.canTranslate, isTrue));
    test('canReview is false -- there is nothing to review', () {
      expect(detail.canReview, isFalse);
    });
    test('display getters still fall back to the original', () {
      expect(detail.displayTitle, _torta.title);
      expect(detail.displaySteps, _originalSteps);
    });
  });

  group('reading a foreign locale with a machine translation', () {
    final RecipeDetail detail = RecipeDetail(
      recipe: _torta,
      readingLocale: 'en',
      steps: _originalSteps,
      translations: <RecipeTranslation>[_machineTranslation()],
    );

    test('canTranslate is false -- one already exists', () {
      expect(detail.canTranslate, isFalse);
    });
    test('canReview is true', () => expect(detail.canReview, isTrue));
    test('isShowingMachineTranslation is true, isReviewedTranslation is false', () {
      expect(detail.isShowingMachineTranslation, isTrue);
      expect(detail.isReviewedTranslation, isFalse);
    });
    test('display getters read from the translation', () {
      expect(detail.displayTitle, 'Carrot cake');
      expect(detail.displayDescription, 'A moist carrot cake.');
      expect(detail.displaySteps, detail.translation!.steps);
    });

    test(
        'a translation with a NULL description shows nothing, never the '
        'original -- the case displayDescription was written for', () {
      final RecipeDetail withoutDescription = RecipeDetail(
        recipe: _torta,
        readingLocale: 'en',
        steps: _originalSteps,
        translations: <RecipeTranslation>[
          _machineTranslation(description: null),
        ],
      );
      expect(withoutDescription.displayDescription, isNull);
    });

    test('canTranslate and canReview are never both true', () {
      expect(detail.canTranslate && detail.canReview, isFalse);
    });
  });

  group('reading a foreign locale with a REVIEWED translation', () {
    final RecipeDetail detail = RecipeDetail(
      recipe: _torta,
      readingLocale: 'en',
      steps: _originalSteps,
      translations: <RecipeTranslation>[_reviewedTranslation()],
    );

    test('isShowingMachineTranslation is false -- the chip disappears', () {
      expect(detail.isShowingMachineTranslation, isFalse);
    });
    test('isReviewedTranslation is true', () {
      expect(detail.isReviewedTranslation, isTrue);
    });
    test('canReview stays true -- a reviewed translation is still reviewable', () {
      expect(detail.canReview, isTrue);
    });
    test('canTranslate stays false -- retranslating is not offered', () {
      expect(detail.canTranslate, isFalse);
    });
  });

  group('recipeTranslationFromWire', () {
    test('decodes provenance and sorts a shuffled steps array by position', () {
      final RecipeTranslation translation = recipeTranslationFromWire(<String, dynamic>{
        'locale': 'en',
        'title': 'Carrot cake',
        'description': null,
        'steps': <Map<String, dynamic>>[
          <String, dynamic>{'position': 1, 'text': 'Bake for 40 minutes.'},
          <String, dynamic>{'position': 0, 'text': 'Mix the ingredients.'},
        ],
        'is_machine_generated': false,
        'reviewed_by': 'u2',
        'reviewed_at': '2026-09-14T00:00:00Z',
      });

      expect(translation.isMachineGenerated, isFalse);
      expect(translation.reviewedBy, 'u2');
      expect(translation.reviewedAt, isNotNull);
      expect(
        translation.steps.map((RecipeStep s) => s.position),
        <int>[0, 1],
      );
      expect(translation.steps.first.text, 'Mix the ingredients.');
    });

    test('defaults is_machine_generated to true and provenance to null when absent', () {
      final RecipeTranslation translation = recipeTranslationFromWire(<String, dynamic>{
        'locale': 'en',
        'title': 'Carrot cake',
        'description': null,
        'steps': <Map<String, dynamic>>[],
      });

      expect(translation.isMachineGenerated, isTrue);
      expect(translation.reviewedBy, isNull);
      expect(translation.reviewedAt, isNull);
    });
  });
}

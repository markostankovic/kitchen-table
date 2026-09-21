import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/text/text_normalizer.dart';
import 'recipe.dart';

part 'recipe_tag.freezed.dart';

/// A tag in a household's vocabulary, collapsed through [TextNormalizer] so
/// `Posno` and `posno` are one chip (Phase 5, part 2).
///
/// [key] is what filters compare against -- the normalized spelling, so it
/// never depends on which recipe happened to introduce the tag. [label] is
/// what the chip actually displays -- one original spelling, picked
/// deterministically (see [vocabularyOf]) so the chip row never flickers
/// between two spellings depending on recipe order.
///
/// Pure Dart (rule 7): no Flutter import.
@freezed
abstract class RecipeTag with _$RecipeTag {
  const RecipeTag._();

  const factory RecipeTag({required String key, required String label}) =
      _RecipeTag;

  /// The household's tag vocabulary, derived from [recipes]' own `tags`.
  ///
  /// Groups by [TextNormalizer.normalize], picks the alphabetically-first
  /// original spelling as the group's [label], drops entries whose
  /// normalized key is empty (a blank or whitespace-only tag), and returns
  /// sorted by [key] so the chip order never depends on recipe order.
  static List<RecipeTag> vocabularyOf(List<Recipe> recipes) {
    final Map<String, List<String>> byKey = <String, List<String>>{};

    for (final Recipe recipe in recipes) {
      for (final String tag in recipe.tags) {
        final String key = TextNormalizer.normalize(tag);
        if (key.isEmpty) continue;
        byKey.putIfAbsent(key, () => <String>[]).add(tag);
      }
    }

    final List<RecipeTag> vocabulary = byKey.entries
        .map(
          (MapEntry<String, List<String>> e) => RecipeTag(
            key: e.key,
            label: (List<String>.of(e.value)..sort()).first,
          ),
        )
        .toList(growable: false)
      ..sort((RecipeTag a, RecipeTag b) => a.key.compareTo(b.key));

    return vocabulary;
  }

  /// Each tag relabelled with its spelling in the reader's locale, falling
  /// back to the label as typed when the household has no pair for it
  /// (Phase 6, part 1a). [key] is untouched -- only [label] changes -- so a
  /// translated chip still filters exactly like the as-typed one did.
  ///
  /// Order is unchanged (still sorted by [key], [vocabularyOf]'s own
  /// invariant), so the chip row never reorders when a reader switches
  /// language.
  static List<RecipeTag> relabelled(
    List<RecipeTag> vocabulary,
    Map<String, String> labelsByKey,
  ) => vocabulary
      .map(
        (RecipeTag tag) =>
            tag.copyWith(label: labelsByKey[tag.key] ?? tag.label),
      )
      .toList(growable: false);
}

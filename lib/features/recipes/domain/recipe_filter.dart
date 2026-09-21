import '../../../core/text/text_normalizer.dart';
import 'recipe.dart';

/// The recipe list's search/filter predicate, extracted from
/// `RecipeRepository._filtered` so the semantics are testable without a
/// database (Phase 6, part 2).
///
/// Pure Dart (rule 7): no Flutter import, no Supabase import.
abstract final class RecipeFilter {
  /// [spellingsByKey] maps a tag key to every known normalized spelling of
  /// that tag (its own, plus each locale's row in `recipe_tag_names`).
  /// Empty is a valid, graceful degradation: matching falls back to the
  /// spellings the recipes themselves carry.
  static List<Recipe> apply(
    List<Recipe> recipes, {
    String query = '',
    String tag = '',
    bool favoritesOnly = false,
    Map<String, Set<String>> spellingsByKey = const <String, Set<String>>{},
  }) {
    final String term = TextNormalizer.normalize(query);
    final String tagKey = TextNormalizer.normalize(tag);
    if (term.isEmpty && tagKey.isEmpty && !favoritesOnly) return recipes;

    return recipes
        .where(
          (Recipe r) =>
              (term.isEmpty || _matches(r, term, spellingsByKey)) &&
              (tagKey.isEmpty ||
                  r.tags.any(
                    (String t) => TextNormalizer.normalize(t) == tagKey,
                  )) &&
              (!favoritesOnly || r.isFavorite),
        )
        .toList(growable: false);
  }

  /// A title-or-tag hit for [term]: the title matches, or any of [recipe]'s
  /// tags matches under its own spelling or any known translated spelling.
  static bool _matches(
    Recipe recipe,
    String term,
    Map<String, Set<String>> spellingsByKey,
  ) {
    if (TextNormalizer.normalize(recipe.title).contains(term)) return true;

    for (final String t in recipe.tags) {
      final String key = TextNormalizer.normalize(t);
      if (key.contains(term)) return true;
      final Set<String>? spellings = spellingsByKey[key];
      if (spellings != null && spellings.any((String s) => s.contains(term))) {
        return true;
      }
    }
    return false;
  }
}

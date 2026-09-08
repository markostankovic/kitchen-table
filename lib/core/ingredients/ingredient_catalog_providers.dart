/// The ingredient catalog, reachable from every feature (D43).
///
/// Lives in `core/` for the same reason `currentUserIdProvider` does: more than
/// one feature needs it, and `tool/check_layers.dart` allows a cross-feature
/// import only into `domain/`. Phase 1c hit that wall and chose to duplicate
/// the datasource rather than relax the rule (D33), with a note saying a third
/// caller should reopen the decision. Phase 1d's import confirm screen is the
/// third caller, so the duplicate is gone and this is the one copy.
///
/// `core/` is outside the feature rule entirely -- `_layerOf` and `_featureOf`
/// in the checker only match `lib/features/<x>/<layer>/` -- which is what lets
/// this file reach into `features/ingredients/data/`. It deliberately does not
/// name a Supabase type, so `supabase_flutter` stays confined to `data/` and
/// `core/supabase/` (rule 1).
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/ingredients/data/ingredient_repository.dart';
import '../../features/ingredients/domain/ingredient_line_parser.dart';
import '../../features/ingredients/domain/ingredient_match.dart';
import '../../features/ingredients/domain/unit_catalog.dart';
import '../supabase/supabase_client.dart';

part 'ingredient_catalog_providers.g.dart';

@Riverpod(keepAlive: true)
IngredientRepository ingredientCatalog(Ref ref) =>
    IngredientRepository(ref.watch(supabaseClientProvider));

/// The unit lexicon, fetched once per session.
///
/// `keepAlive` because it is roughly 120 immutable rows that only a migration
/// changes, and every ingredient line in the app parses against it.
@Riverpod(keepAlive: true)
Future<UnitCatalog> unitCatalog(Ref ref) =>
    ref.watch(ingredientCatalogProvider).fetchUnitCatalog();

/// Tier 1, ready to use: the pure parser with its lexicon already injected, so
/// no screen has to know that parsing depends on a fetch (D31).
@Riverpod(keepAlive: true)
Future<IngredientLineParser> lineParser(Ref ref) async =>
    IngredientLineParser(await ref.watch(unitCatalogProvider.future));

/// Tiers 2 and 3, for the line editor's autocomplete. Callers debounce.
///
/// Not `keepAlive`: one entry per query string, and the family would grow
/// without bound as somebody types.
@riverpod
Future<List<IngredientMatch>> ingredientMatches(
  Ref ref,
  String query, {
  String locale = 'sr',
}) =>
    ref.watch(ingredientCatalogProvider).search(query, locale: locale);

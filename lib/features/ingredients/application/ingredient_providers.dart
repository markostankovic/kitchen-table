import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/supabase/supabase_client.dart';
import '../data/ingredient_repository.dart';
import '../domain/ingredient_line_parser.dart';
import '../domain/ingredient_match.dart';
import '../domain/unit_catalog.dart';

part 'ingredient_providers.g.dart';

@Riverpod(keepAlive: true)
IngredientRepository ingredientRepository(Ref ref) =>
    IngredientRepository(ref.watch(supabaseClientProvider));

/// The unit lexicon, fetched once.
///
/// `keepAlive` is justified: it is roughly 120 immutable rows that only a
/// migration ever changes, and it is read on every ingredient line the user
/// touches. Re-fetching it whenever the last listener drops would mean a round
/// trip every time the line editor is reopened, for data that cannot have
/// changed.
@Riverpod(keepAlive: true)
Future<UnitCatalog> unitCatalog(Ref ref) =>
    ref.watch(ingredientRepositoryProvider).fetchUnitCatalog();

/// Tier 1, ready to use.
///
/// The parser itself is pure and takes its lexicon by injection; this is the
/// one place the two are put together, so no screen has to know that parsing
/// depends on a fetch at all.
@Riverpod(keepAlive: true)
Future<IngredientLineParser> ingredientLineParser(Ref ref) async =>
    IngredientLineParser(await ref.watch(unitCatalogProvider.future));

/// Tiers 2 and 3, for autocomplete.
///
/// Not `keepAlive`: one entry per query string, and the family would otherwise
/// grow without bound as somebody types. Callers debounce.
@riverpod
Future<List<IngredientMatch>> ingredientSearch(
  Ref ref,
  String query, {
  String locale = 'sr',
}) =>
    ref.watch(ingredientRepositoryProvider).search(query, locale: locale);

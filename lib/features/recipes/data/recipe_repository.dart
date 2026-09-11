/// Recipe data access, composed from a Remote half (Supabase) and a Local
/// half (the Drift cache) -- `docs/ARCHITECTURE.md`'s "Offline (Phase 2)"
/// split, the third outing after the shopping list and the unit catalog
/// (Phase 2 part 6a).
///
/// This file itself imports neither `supabase_flutter` nor `drift`: rule 1's
/// "the only place `supabase_flutter` may be imported" now belongs to
/// [RemoteRecipeDataSource], and [LocalRecipeDataSource] is the drift half.
/// This class only orchestrates the two.
library;

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';

import '../../../core/error/app_failure.dart';
import '../../../core/text/text_normalizer.dart';
import '../domain/recipe.dart';
import '../domain/recipe_detail.dart';
import '../domain/recipe_ingredient.dart';
import '../domain/recipe_step.dart';
import 'dto/recipe_dto.dart';
import 'local_recipe_datasource.dart';
import 'remote_recipe_datasource.dart';

class RecipeRepository {
  const RecipeRepository(this._remote, this._local);

  final RemoteRecipeDataSource _remote;
  final LocalRecipeDataSource _local;

  /// The household's recipes, cache immediately then the network -- the same
  /// shape `ShoppingListRepository.watchLatest` established (D67), widened
  /// from one row to many.
  ///
  /// [query] is matched locally, against [TextNormalizer]-normalised titles,
  /// on BOTH the cached emission and the post-sync emission -- there is no
  /// separate server-side search any more. This produces identical results
  /// to the old `ilike '%term%'` search (both sides compare the same
  /// `normalize_text()`-derived value, rule 6), and it means every recipe
  /// the household owns is a full sync away from being searchable offline,
  /// not just the ones a query happened to match while still connected.
  ///
  /// A cache hit outlives a [NetworkFailure]; a cold cache does not -- an
  /// honest "no connection, and nothing saved yet" beats an empty list that
  /// implies the household has no recipes at all (matches
  /// `ShoppingListRepository.watchLatest`'s own rule).
  Stream<List<Recipe>> watchList({
    required String householdId,
    String query = '',
    void Function()? onReachable,
    void Function()? onUnreachable,
  }) async* {
    final List<Recipe> cached =
        await _local.readAll(householdId: householdId);
    // A cold cache is empty, not null -- skip the emission the same way
    // `ShoppingListRepository.watchLatest` skips a null one, so a
    // NetworkFailure on a truly cold cache errors the stream outright
    // rather than emitting an empty list moment before it.
    if (cached.isNotEmpty) yield _filtered(cached, query);

    try {
      final DateTime? since = await _local.readRecipesWatermark(householdId);
      final List<Map<String, dynamic>> changed = await _remote
          .fetchChangedSince(householdId: householdId, since: since);

      if (changed.isNotEmpty) {
        await _applyRecipeDelta(householdId, changed, since);
      }

      onReachable?.call();
      final List<Recipe> fresh =
          await _local.readAll(householdId: householdId);
      yield _filtered(fresh, query);
    } on NetworkFailure {
      onUnreachable?.call();
      if (cached.isNotEmpty) return;
      throw const NetworkFailure(
        message: 'No connection, and no saved recipes on this phone yet.',
      );
    }
  }

  /// One recipe with its lines and steps, with ingredient names resolved
  /// from the catalog in [locale].
  ///
  /// Network-first, the cache only as a [NetworkFailure] fallback -- D70's
  /// read order, not D67's (D74). A single recipe is fetched on demand
  /// exactly when the cook opens it, where showing a stale copy first and a
  /// fresh one a moment later buys little; being correct with no network at
  /// all is what Phase 2's Done-when actually asks for, and network-first
  /// with a cache fallback gives that in one emission, matching
  /// `IngredientRepository.fetchUnitCatalog()`'s own shape.
  ///
  /// The two paths resolve display names two different ways on purpose.
  /// Online, this is still the `ingredient_display_names` RPC -- unchanged
  /// -- and a successful read also triggers a best-effort background sync
  /// of the global name cache, so OTHER ingredients (ones this recipe never
  /// mentions) are covered for a later offline read, per the roadmap's
  /// "every ingredient renders offline, including ones never viewed."
  /// Offline, resolution reads whatever that sync has already collected,
  /// through [DisplayNameChain] (D72/D73) -- the two must agree, and
  /// `test/fixtures/display_names.json` is what proves it.
  Future<RecipeDetail> fetchDetail(String id, {String locale = 'sr'}) async {
    try {
      final Map<String, dynamic> row = await _remote.fetchOne(id);

      final List<Recipe> withImage =
          await _withImageUrls(<Recipe>[recipeFromWire(row)]);
      final List<RecipeIngredient> lines = recipeIngredientsFromWire(row);
      final List<RecipeStep> steps = recipeStepsFromWire(row);
      final List<RecipeIngredient> resolved = await _resolveOnline(
        lines,
        locale,
      );

      // Warms the cache for a later offline read of THIS recipe, even if
      // the household-wide list sync (`watchList`) has never run -- a
      // recipe opened straight from a deep link, say.
      await _local.upsertMany(
        householdId: row['household_id'] as String,
        rows: <Map<String, dynamic>>[row],
      );

      // Best-effort, awaited but never allowed to fail this already-
      // successful read: extends the global name cache so ids this recipe
      // never mentions are ALSO resolvable offline later.
      await _syncNamesBestEffort();

      return RecipeDetail(
        recipe: withImage.single,
        ingredients: resolved,
        steps: steps,
      );
    } on NetworkFailure {
      final Map<String, dynamic>? cached = await _local.readOne(id);
      if (cached == null || !_hasEmbeddedLines(cached)) rethrow;

      final Recipe recipe = recipeFromWire(cached); // imageUrl stays null
      final List<RecipeIngredient> lines = recipeIngredientsFromWire(cached);
      final List<RecipeStep> steps = recipeStepsFromWire(cached);
      final List<RecipeIngredient> resolved = await _resolveOffline(
        lines,
        locale,
      );

      return RecipeDetail(recipe: recipe, ingredients: resolved, steps: steps);
    }
  }

  /// A single best-available answer from [watchList] -- the fresh network
  /// result when reachable, the cached one otherwise (or a [NetworkFailure]
  /// with neither). For a caller that wants one list rather than two
  /// emissions, such as the meal plan's recipe picker (`core/recipes/`),
  /// which has no screen-level "showing your saved copy" line to drive.
  Future<List<Recipe>> searchOnce({
    required String householdId,
    String query = '',
  }) => watchList(householdId: householdId, query: query).last;

  /// Every ingredient line of several recipes at once, with catalog names,
  /// pantry flags and categories resolved -- the shopping list's read path.
  ///
  /// Unchanged in behaviour from before the Remote/Local split: `generate()`
  /// always ends in an online `save()` RPC, so this has never needed a
  /// cache and still goes straight to the network.
  ///
  /// `ingredients(...)` is embedded server-side rather than fetched
  /// separately because `is_pantry_staple` and `category` are global
  /// catalog columns readable by any authenticated caller (migration 4).
  ///
  /// Returns lines carrying [RecipeIngredient.recipeId], which [fetchDetail]
  /// leaves null: the caller has to know which recipe a line came from in
  /// order to scale it by the servings of the entry that planned it.
  Future<List<RecipeIngredient>> fetchLinesForRecipes(
    List<String> recipeIds, {
    String locale = 'sr',
  }) async {
    final List<Map<String, dynamic>> rows =
        await _remote.fetchLinesForRecipesRaw(recipeIds);
    final List<RecipeIngredient> lines =
        rows.map(recipeIngredientFromWire).toList(growable: false);
    return _resolveOnline(lines, locale);
  }

  /// Creates a recipe and returns the row that was written.
  ///
  /// Unlike `create_household`, this is a plain insert: `recipes` has an
  /// INSERT policy and there is nothing to make atomic, so an RPC would be
  /// ceremony.
  ///
  /// The whole row comes back rather than just the id because the caller
  /// needs the fields it did not send -- `household_id`, `created_by` -- in
  /// order to issue an update afterwards. A first save is this call
  /// followed by `saveLines`, and if the second half fails the editor
  /// retries against the recipe this returned instead of creating a second
  /// one (D37).
  Future<Recipe> create({
    required String householdId,
    required String title,
    required String originalLocale,
    String? description,
    int? servings,
    int? prepMinutes,
    int? cookMinutes,
    List<String> tags = const <String>[],
    RecipeSourceType sourceType = RecipeSourceType.manual,
    RecipeStatus status = RecipeStatus.draft,
    String? sourceUrl,
    String? sourceAttribution,
    String? imagePath,
  }) async {
    final Map<String, dynamic> row = await _remote.create(
      householdId: householdId,
      title: title,
      originalLocale: originalLocale,
      description: description,
      servings: servings,
      prepMinutes: prepMinutes,
      cookMinutes: cookMinutes,
      tags: tags,
      sourceTypeWire: sourceType.wireValue,
      statusName: status.name,
      sourceUrl: sourceUrl,
      sourceAttribution: sourceAttribution,
      imagePath: imagePath,
    );

    final List<Recipe> withImage =
        await _withImageUrls(<Recipe>[recipeFromWire(row)]);
    return withImage.single;
  }

  /// Saves the editable fields of an existing recipe.
  ///
  /// `household_id`, `created_by` and `created_at` are deliberately not in
  /// the payload: none of them is editable, and sending them would let a
  /// bug move a recipe between households through a policy that only checks
  /// the row's current owner.
  Future<void> update(Recipe recipe) => _remote.update(
    id: recipe.id,
    title: recipe.title,
    description: recipe.description,
    servings: recipe.servings,
    prepMinutes: recipe.prepMinutes,
    cookMinutes: recipe.cookMinutes,
    originalLocale: recipe.originalLocale,
    sourceUrl: recipe.sourceUrl,
    sourceAttribution: recipe.sourceAttribution,
    statusName: recipe.status.name,
    tags: recipe.tags,
    imagePath: recipe.imagePath,
  );

  /// Replaces a recipe's ingredient lines and steps.
  ///
  /// Goes through `replace_recipe_lines` because this is four statements and
  /// PostgREST offers the client no transaction. A half-applied save would
  /// delete the old lines and fail to write the new ones (D36).
  Future<void> saveLines(
    String recipeId, {
    required List<RecipeIngredient> ingredients,
    required List<RecipeStep> steps,
  }) => _remote.saveLines(
    recipeId,
    ingredientLines: ingredients.map(_ingredientPayload).toList(growable: false),
    stepPayloads: steps.map(_stepPayload).toList(growable: false),
  );

  /// Uploads a picked photo to the `recipe-images` bucket and returns the
  /// object path.
  Future<String> uploadImage(
    Uint8List bytes, {
    required String householdId,
    required String contentType,
    required String extension,
  }) => _remote.uploadImage(
    bytes,
    householdId: householdId,
    contentType: contentType,
    extension: extension,
  );

  /// Removes a photo from the `recipe-images` bucket. Best-effort by
  /// design -- see `RecipeEditor.save()` (D48).
  Future<void> deleteImage(String path) => _remote.deleteImage(path);

  /// Soft-deletes a recipe. There is no hard delete (rule 4). The cache
  /// eviction itself waits for the next `watchList` sync to see the
  /// tombstone -- writes are online-only (D12) and nothing here needs to
  /// race that.
  Future<void> softDelete(String id) => _remote.softDelete(id);

  // ---------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------

  List<Recipe> _filtered(List<Recipe> recipes, String query) {
    final String term = TextNormalizer.normalize(query);
    if (term.isEmpty) return recipes;
    return recipes
        .where(
          (Recipe r) => TextNormalizer.normalize(r.title).contains(term),
        )
        .toList(growable: false);
  }

  bool _hasEmbeddedLines(Map<String, dynamic> row) =>
      row.containsKey('recipe_ingredients');

  Future<void> _applyRecipeDelta(
    String householdId,
    List<Map<String, dynamic>> changed,
    DateTime? since,
  ) async {
    DateTime maxUpdated = since ?? DateTime.utc(1970);
    final List<Map<String, dynamic>> alive = <Map<String, dynamic>>[];
    final List<String> tombstoned = <String>[];

    for (final Map<String, dynamic> row in changed) {
      final DateTime updatedAt =
          DateTime.parse(row['updated_at'] as String).toUtc();
      if (updatedAt.isAfter(maxUpdated)) maxUpdated = updatedAt;

      if (row['deleted_at'] != null) {
        tombstoned.add(row['id'] as String);
      } else {
        alive.add(row);
      }
    }

    if (alive.isNotEmpty) {
      await _local.upsertMany(householdId: householdId, rows: alive);
    }
    for (final String id in tombstoned) {
      await _local.evict(id);
    }
    await _local.advanceRecipesWatermark(householdId, maxUpdated);
  }

  Future<List<RecipeIngredient>> _resolveOnline(
    List<RecipeIngredient> lines,
    String locale,
  ) async {
    final List<String> ids = _ingredientIds(lines);
    if (ids.isEmpty) return lines;
    final Map<String, String> names =
        await _remote.fetchDisplayNames(ids, locale);
    return _withNames(lines, names);
  }

  Future<List<RecipeIngredient>> _resolveOffline(
    List<RecipeIngredient> lines,
    String locale,
  ) async {
    final List<String> ids = _ingredientIds(lines);
    if (ids.isEmpty) return lines;
    final Map<String, String> names =
        await _local.resolveDisplayNames(ids, locale);
    return _withNames(lines, names);
  }

  List<String> _ingredientIds(List<RecipeIngredient> lines) => lines
      .map((RecipeIngredient line) => line.ingredientId)
      .whereType<String>()
      .toSet()
      .toList(growable: false);

  List<RecipeIngredient> _withNames(
    List<RecipeIngredient> lines,
    Map<String, String> names,
  ) =>
      lines
          .map(
            (RecipeIngredient line) =>
                line.copyWith(displayName: names[line.ingredientId ?? '']),
          )
          .toList(growable: false);

  /// Delta-syncs the global ingredient name cache. Best-effort and never
  /// allowed to fail the read it rides in on (D69's philosophy, applied to
  /// a background warm rather than a cache read/write) -- logged under this
  /// class's name on `RecipeEditor`'s own precedent for a cleanup that must
  /// not undo an otherwise-successful operation (D48).
  Future<void> _syncNamesBestEffort() async {
    try {
      final DateTime? since = await _local.readNamesWatermark();
      final List<Map<String, dynamic>> rows =
          await _remote.fetchNamesSince(since);
      if (rows.isEmpty) return;

      DateTime maxUpdated = since ?? DateTime.utc(1970);
      final List<Map<String, dynamic>> alive = <Map<String, dynamic>>[];
      final List<String> tombstoned = <String>[];

      for (final Map<String, dynamic> row in rows) {
        final DateTime updatedAt =
            DateTime.parse(row['updated_at'] as String).toUtc();
        if (updatedAt.isAfter(maxUpdated)) maxUpdated = updatedAt;

        if (row['deleted_at'] != null) {
          tombstoned.add(row['id'] as String);
        } else {
          alive.add(row);
        }
      }

      if (alive.isNotEmpty) await _local.upsertNames(alive);
      for (final String id in tombstoned) {
        await _local.evictName(id);
      }
      await _local.advanceNamesWatermark(maxUpdated);
    } on Object catch (error, stackTrace) {
      developer.log(
        'Could not sync the ingredient name catalog',
        name: 'RecipeRepository',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Fills in [Recipe.imageUrl] for every recipe with an [Recipe.imagePath],
  /// in one round trip. Never called for a recipe served from the cache --
  /// a cached recipe keeps `imagePath` and a null `imageUrl`, a state the
  /// UI already renders as a placeholder (signing can fail online too).
  Future<List<Recipe>> _withImageUrls(List<Recipe> recipes) async {
    final List<String> paths = recipes
        .map((Recipe r) => r.imagePath)
        .whereType<String>()
        .toSet()
        .toList(growable: false);

    if (paths.isEmpty) return recipes;

    final Map<String, String> urls = await _remote.signImageUrls(paths);

    return recipes
        .map((Recipe r) => r.copyWith(imageUrl: urls[r.imagePath ?? '']))
        .toList(growable: false);
  }

  Map<String, dynamic> _ingredientPayload(RecipeIngredient line) =>
      <String, dynamic>{
        'raw_text': line.rawText,
        'section': line.section,
        'ingredient_id': line.ingredientId,
        'qty_num': line.quantity?.numerator,
        'qty_den': line.quantity?.denominator,
        'qty_max_num': line.quantity?.maxNumerator,
        'qty_max_den': line.quantity?.maxDenominator,
        'unit_code': line.unitCode,
        'note': line.note,
        'is_optional': line.isOptional,
        'match_method': line.matchMethod?.name,
        'match_confidence': line.matchConfidence,
        'matched_at': line.matchedAt?.toUtc().toIso8601String(),
      };

  Map<String, dynamic> _stepPayload(RecipeStep step) => <String, dynamic>{
        'text': step.text,
        'timer_seconds': step.timerSeconds,
      };
}

/// Recipe data access to Supabase -- the Remote half of `RecipeRepository`'s
/// split (Phase 2 part 6a, on `RemoteShoppingListDataSource`'s precedent,
/// D64). The only place in this feature that touches Supabase or Storage
/// (CLAUDE.md rule 1).
library;

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/supabase/supabase_failure.dart';
import 'dto/recipe_dto.dart';

/// The `recipe-images` bucket is private (D48), so a recipe's `image_path`
/// alone is not fetchable -- every online read signs it. An hour outlives
/// any single screen, and a cached recipe simply carries no signed URL at
/// all offline (`RecipeRepository`'s own doc comment).
const int _signedUrlTtlSeconds = 3600;

class RemoteRecipeDataSource {
  const RemoteRecipeDataSource(this._client);

  final SupabaseClient _client;

  /// Every recipe row in [householdId] with `updated_at` after [since],
  /// including embedded lines and steps -- or every row at all when [since]
  /// is null, the delta fetch's own "no watermark yet" case (D72).
  ///
  /// No `deleted_at` filter (D23): a row the server has soft-deleted still
  /// comes back here so the caller can evict it from the cache, exactly the
  /// argument `search()` and `fetchDetail()` make for filtering the
  /// tombstone out for the SCREEN rather than the RLS policy.
  Future<List<Map<String, dynamic>>> fetchChangedSince({
    required String householdId,
    DateTime? since,
  }) =>
      runGuarded(() async {
        final PostgrestFilterBuilder<List<Map<String, dynamic>>> filter = _client
            .from('recipes')
            .select('$recipeColumns, $recipeDetailEmbed')
            .eq('household_id', householdId);

        final List<Map<String, dynamic>> rows = since == null
            ? await filter
            : await filter.gt('updated_at', since.toUtc().toIso8601String());

        return rows;
      });

  /// One recipe, by id, including embedded lines and steps -- `fetchDetail`'s
  /// online path. `deleted_at is null` is filtered here, unlike
  /// [fetchChangedSince]: a single detail read is for a screen, not a sync,
  /// and a tombstoned recipe should read as not found, the same as `search()`
  /// filtering it out of the list.
  Future<Map<String, dynamic>> fetchOne(String id) => runGuarded(() async {
        return _client
            .from('recipes')
            .select('$recipeColumns, $recipeDetailEmbed')
            .eq('id', id)
            .isFilter('deleted_at', null)
            .single();
      });

  /// Global ingredient names changed since [since] -- household-scoped
  /// aliases are never fetched here, only `household_id is null` rows
  /// (D72): the fallback chain never considers a household alias
  /// (migration 4), so caching one would cache data [DisplayNameChain] is
  /// defined to ignore.
  ///
  /// No `deleted_at` filter for the same reason as [fetchChangedSince]: a
  /// retired name still needs to reach the caller so it can be evicted.
  Future<List<Map<String, dynamic>>> fetchNamesSince(DateTime? since) =>
      runGuarded(() async {
        final PostgrestFilterBuilder<List<Map<String, dynamic>>> filter = _client
            .from('ingredient_names')
            .select(
              'id, ingredient_id, name, locale, is_display_name, '
              'created_at, updated_at, deleted_at',
            )
            .isFilter('household_id', null);

        final List<Map<String, dynamic>> rows = since == null
            ? await filter
            : await filter.gt('updated_at', since.toUtc().toIso8601String());

        return rows;
      });

  /// Every ingredient line of several recipes at once, with catalog names,
  /// pantry flags and categories resolved -- the shopping list's read path.
  /// Unchanged from before the Remote/Local split: `generate()` always runs
  /// online (it ends in a `save()` RPC), so this has never needed a cache.
  Future<List<Map<String, dynamic>>> fetchLinesForRecipesRaw(
    List<String> recipeIds,
  ) =>
      runGuarded(() async {
        if (recipeIds.isEmpty) return const <Map<String, dynamic>>[];

        return _client
            .from('recipe_ingredients')
            .select('''
id, recipe_id, position, section, raw_text, ingredient_id,
qty_num, qty_den, qty_max_num, qty_max_den,
unit_code, note, is_optional,
match_method, match_confidence, matched_at,
ingredients(is_pantry_staple, category)''')
            .inFilter('recipe_id', recipeIds)
            .order('position');
      });

  /// Display names for [ids] in [locale], in one round trip -- the online
  /// path unchanged since before this part. Offline resolution goes through
  /// the cache and [DisplayNameChain] instead; this RPC is never called
  /// without a network to call it on.
  Future<Map<String, String>> fetchDisplayNames(
    List<String> ids,
    String locale,
  ) =>
      runGuarded(() async {
        if (ids.isEmpty) return const <String, String>{};

        final List<Map<String, dynamic>> rows = await _client
            .rpc<List<dynamic>>(
              'ingredient_display_names',
              params: <String, dynamic>{'ids': ids, 'loc': locale},
            )
            .then((List<dynamic> rows) => rows.cast<Map<String, dynamic>>());

        return <String, String>{
          for (final Map<String, dynamic> row in rows)
            if (row['display_name'] != null)
              row['ingredient_id'] as String: row['display_name'] as String,
        };
      });

  /// Fills in a signed URL for every recipe with an `image_path`, in one
  /// round trip.
  ///
  /// `createSignedUrlsResult`, not the deprecated `createSignedUrls`: it
  /// returns one [SignedUrlResult] per path rather than throwing on the
  /// first one that fails, so a recipe whose object has gone missing
  /// renders without a picture instead of failing the whole list -- rule
  /// 3's instinct applied to a photo instead of an ingredient line.
  Future<Map<String, String>> signImageUrls(List<String> paths) async {
    if (paths.isEmpty) return const <String, String>{};

    final List<SignedUrlResult> results = await _client.storage
        .from('recipe-images')
        .createSignedUrlsResult(paths, _signedUrlTtlSeconds);

    return <String, String>{
      for (final SignedUrlResult result in results)
        if (result is SignedUrlSuccess) result.path: result.signedUrl,
    };
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
  Future<Map<String, dynamic>> create({
    required String householdId,
    required String title,
    required String originalLocale,
    String? description,
    int? servings,
    int? prepMinutes,
    int? cookMinutes,
    List<String> tags = const <String>[],
    required String sourceTypeWire,
    required String statusName,
    String? sourceUrl,
    String? sourceAttribution,
    String? imagePath,
  }) =>
      runGuarded(() async {
        final String? userId = _client.auth.currentUser?.id;
        if (userId == null) {
          throw const UnauthorizedFailure(
              message: 'You are not signed in any more.');
        }

        return _client
            .from('recipes')
            .insert(<String, dynamic>{
              'household_id': householdId,
              'title': title.trim(),
              'description': _blankToNull(description),
              'servings': servings,
              'prep_minutes': prepMinutes,
              'cook_minutes': cookMinutes,
              'original_locale': originalLocale,
              'source_type': sourceTypeWire,
              'source_url': _blankToNull(sourceUrl),
              'source_attribution': _blankToNull(sourceAttribution),
              'status': statusName,
              'tags': tags,
              'created_by': userId,
              'image_path': imagePath,
            })
            .select(recipeColumns)
            .single();
      });

  /// Saves the editable fields of an existing recipe.
  ///
  /// `household_id`, `created_by` and `created_at` are deliberately not in
  /// the payload: none of them is editable, and sending them would let a
  /// bug move a recipe between households through a policy that only checks
  /// the row's current owner.
  Future<void> update({
    required String id,
    required String title,
    String? description,
    int? servings,
    int? prepMinutes,
    int? cookMinutes,
    required String originalLocale,
    String? sourceUrl,
    String? sourceAttribution,
    required String statusName,
    List<String> tags = const <String>[],
    String? imagePath,
  }) =>
      runGuarded(() async {
        await _client.from('recipes').update(<String, dynamic>{
          'title': title.trim(),
          'description': _blankToNull(description),
          'servings': servings,
          'prep_minutes': prepMinutes,
          'cook_minutes': cookMinutes,
          'original_locale': originalLocale,
          'source_url': _blankToNull(sourceUrl),
          'source_attribution': _blankToNull(sourceAttribution),
          'status': statusName,
          'tags': tags,
          'image_path': imagePath,
        }).eq('id', id);
      });

  /// Replaces a recipe's ingredient lines and steps.
  ///
  /// Goes through `replace_recipe_lines` because this is four statements and
  /// PostgREST offers the client no transaction. A half-applied save would
  /// delete the old lines and fail to write the new ones (D36).
  Future<void> saveLines(
    String recipeId, {
    required List<Map<String, dynamic>> ingredientLines,
    required List<Map<String, dynamic>> stepPayloads,
  }) =>
      runGuarded(() async {
        await _client.rpc<void>(
          'replace_recipe_lines',
          params: <String, dynamic>{
            'recipe': recipeId,
            'ingredient_lines': ingredientLines,
            'steps': stepPayloads,
          },
        );
      });

  /// Uploads a picked photo to the `recipe-images` bucket and returns the
  /// object path.
  ///
  /// Only the upload -- writing that path onto the recipe row is
  /// `RecipeEditor.save()`'s job, and it is the one that decides WHEN this
  /// runs (D48: only as part of a save, never at pick time, so an abandoned
  /// editor leaves no orphan object).
  Future<String> uploadImage(
    Uint8List bytes, {
    required String householdId,
    required String contentType,
    required String extension,
  }) =>
      runGuarded(() async {
        final String path =
            '$householdId/${DateTime.now().microsecondsSinceEpoch}.$extension';

        await _client.storage.from('recipe-images').uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(contentType: contentType),
            );

        return path;
      });

  /// Removes a photo from the `recipe-images` bucket.
  ///
  /// Called after replacing or clearing a recipe's photo, once the row that
  /// pointed at it no longer does. Best-effort by design: the caller
  /// swallows a failure here rather than surface it, because the recipe
  /// itself already saved successfully and a leftover blob is not the
  /// cook's problem (D48).
  Future<void> deleteImage(String path) => runGuarded(() async {
        await _client.storage.from('recipe-images').remove(<String>[path]);
      });

  /// Soft-deletes a recipe. There is no hard delete (rule 4).
  Future<void> softDelete(String id) => runGuarded(() async {
        // The timestamp comes from the client because PostgREST cannot send
        // `now()` in an update payload. Only ordering against other client
        // writes could be affected, and nothing orders by deleted_at.
        await _client.from('recipes').update(<String, dynamic>{
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', id);
      });

  static String? _blankToNull(String? value) {
    final String? trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}

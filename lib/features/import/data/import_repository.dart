/// Import job access: create one, poll it, save what it found, or throw it
/// away.
///
/// The only place in this feature that touches Supabase (CLAUDE.md rule 1).
///
/// Note what is NOT here: no household lookup. Every method that needs the
/// household takes it as `householdId`, read by the caller from
/// `currentHouseholdIdProvider` (D52), and the import functions check the
/// caller belongs to it (D168). Polling needs none: `import_jobs_select` is
/// `is_household_member(household_id)` (D39), so a row this client can read
/// is already a row it is allowed to read.
library;

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/supabase/supabase_failure.dart';
import '../../recipes/domain/recipe_ingredient.dart';
import '../../recipes/domain/recipe_step.dart';
import '../domain/import_job.dart';
import '../domain/parsed_recipe.dart';

const String _jobColumns =
    'id, household_id, kind, status, result, error_code, error_message, '
    'recipe_id';

class ImportRepository {
  const ImportRepository(this._client);

  final SupabaseClient _client;

  /// Starts an import from pasted text and returns the job id.
  ///
  /// An Edge Function because it holds the model API key (rule 2) and because
  /// reading a page of prose cannot fit inside the request that started it.
  /// It answers 202 with the id and does the work afterwards, so this returns
  /// almost immediately and the caller polls (D14).
  Future<String> createFromText(
    String text, {
    required String householdId,
    String? sourceUrl,
  }) =>
      runGuarded(() async {
        final FunctionResponse res = await _client.functions.invoke(
          'import-text',
          body: <String, dynamic>{
            'householdId': householdId,
            'text': text,
            if (sourceUrl != null && sourceUrl.trim().isNotEmpty)
              'sourceUrl': sourceUrl.trim(),
          },
        );

        final Object? data = res.data;
        if (data is! Map<String, dynamic>) {
          throw const UnknownFailure(
              message: 'The server sent an unexpected reply.',
              code: FailureCode.unexpectedServerReply);
        }
        // camelCase, because this is a hand-built Edge Function body rather
        // than a Postgres row -- the split HouseholdRepository documents.
        return data['jobId'] as String;
      });

  /// Starts an import from a web page and returns the job id.
  ///
  /// The URL is vetted server-side before a job row exists, so an unusable
  /// link comes back as a synchronous `invalid_url` or `url_not_allowed`
  /// rather than as a job that fails a moment later (D45).
  Future<String> createFromUrl(String url, {required String householdId}) =>
      runGuarded(() async {
        final FunctionResponse res = await _client.functions.invoke(
          'import-url',
          body: <String, dynamic>{
            'householdId': householdId,
            'url': url.trim(),
          },
        );

        final Object? data = res.data;
        if (data is! Map<String, dynamic>) {
          throw const UnknownFailure(
              message: 'The server sent an unexpected reply.',
              code: FailureCode.unexpectedServerReply);
        }
        return data['jobId'] as String;
      });

  Future<ImportJob> fetch(String jobId) => runGuarded(() async {
        final Map<String, dynamic> row = await _client
            .from('import_jobs')
            .select(_jobColumns)
            .eq('id', jobId)
            .isFilter('deleted_at', null)
            .single();

        return _toJob(row);
      });

  /// Writes the reviewed recipe, its lines and its steps, and marks the job
  /// done -- one round trip, one transaction (D44).
  ///
  /// Not `create()` then `saveLines()` like the manual editor. That path is
  /// safe because the draft keeps the id it was given, so a failed second step
  /// is fixed by pressing Save again; an import has a third step and no such
  /// anchor, and a retry would create a second recipe from the same import.
  ///
  /// The recipe goes to the job's household unless [targetHouseholdId] names
  /// another, which the server accepts only when the caller is a member of it
  /// (D175). The key is sent only when non-null, so an unchanged save sends
  /// exactly the payload it always has -- PostgREST rejects an argument name
  /// the function doesn't have, even with a null value, and a database without
  /// the new parameter must keep taking it.
  Future<String> saveImported(
    String jobId, {
    required ImportKind kind,
    required String title,
    required String originalLocale,
    required List<RecipeIngredient> ingredients,
    required List<RecipeStep> steps,
    String? description,
    String? notes,
    int? servings,
    int? prepMinutes,
    int? cookMinutes,
    String? sourceUrl,
    String? sourceAttribution,
    List<String> tags = const <String>[],
    String? targetHouseholdId,
  }) =>
      runGuarded(() async {
        final dynamic id = await _client.rpc<dynamic>(
          'save_imported_recipe',
          params: <String, dynamic>{
            'job': jobId,
            'recipe': <String, dynamic>{
              'title': title.trim(),
              'description': description,
              'notes': notes,
              'servings': servings,
              'prep_minutes': prepMinutes,
              'cook_minutes': cookMinutes,
              'original_locale': originalLocale,
              'source_type': kind.sourceTypeFor(sourceUrl),
              'source_url': sourceUrl,
              'source_attribution': sourceAttribution,
              'tags': tags,
            },
            'ingredient_lines':
                ingredients.map(_ingredientPayload).toList(growable: false),
            'steps': steps.map(_stepPayload).toList(growable: false),
            'target_household': ?targetHouseholdId,
          },
        );
        return id as String;
      });

  /// Soft-deletes a job, which is how a failed one leaves the queue (rule 4).
  Future<void> dismiss(String jobId) => runGuarded(() async {
        await _client.rpc<void>(
          'dismiss_import_job',
          params: <String, dynamic>{'job': jobId},
        );
      });

  /// Uploads a photographed page and returns its object path.
  ///
  /// The path is `{household_id}/{uuid}.{ext}`, and that prefix is the access
  /// control rather than a filing convention -- every policy on the
  /// `import-uploads` bucket reads it (D46), so an upload into a household
  /// the caller is not in is refused by Storage. Pass the same [householdId]
  /// to [createFromPhoto], which checks the prefix against it.
  Future<String> uploadImportPhoto(
    Uint8List bytes, {
    required String householdId,
    required String contentType,
    required String extension,
  }) =>
      runGuarded(() async {
        final String path =
            '$householdId/${DateTime.now().microsecondsSinceEpoch}.$extension';

        await _client.storage.from('import-uploads').uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(contentType: contentType),
            );

        return path;
      });

  /// Starts an import from a photograph already in Storage.
  Future<String> createFromPhoto(
    String storagePath, {
    required String householdId,
  }) =>
      runGuarded(() async {
        final FunctionResponse res = await _client.functions.invoke(
          'import-photo',
          body: <String, dynamic>{
            'householdId': householdId,
            'storagePath': storagePath,
          },
        );

        final Object? data = res.data;
        if (data is! Map<String, dynamic>) {
          throw const UnknownFailure(
              message: 'The server sent an unexpected reply.',
              code: FailureCode.unexpectedServerReply);
        }
        return data['jobId'] as String;
      });

  ImportJob _toJob(Map<String, dynamic> row) {
    final Object? result = row['result'];
    return ImportJob(
      id: row['id'] as String,
      householdId: row['household_id'] as String,
      kind: ImportKind.fromWire(row['kind'] as String),
      status: ImportJobStatus.fromWire(row['status'] as String),
      // jsonb arrives already decoded. The generated fromJson is the only
      // reader of this shape -- schema.ts is its definition and `make types`
      // is what keeps the two in step (D18).
      result: result is Map<String, dynamic>
          ? ParsedRecipe.fromJson(result)
          : null,
      errorCode: row['error_code'] as String?,
      errorMessage: row['error_message'] as String?,
      recipeId: row['recipe_id'] as String?,
    );
  }

  /// The snake_case keys `replace_recipe_lines` reads, reached through
  /// `save_imported_recipe`. Deliberately the same shape
  /// `RecipeRepository._ingredientPayload` sends, because it is the same
  /// function on the other end.
  Map<String, dynamic> _ingredientPayload(RecipeIngredient line) =>
      <String, dynamic>{
        'section': line.section,
        'raw_text': line.rawText,
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
        'matched_at': line.matchedAt?.toIso8601String(),
      };

  Map<String, dynamic> _stepPayload(RecipeStep step) => <String, dynamic>{
        'text': step.text,
        'timer_seconds': step.timerSeconds,
        'kind': step.kind.name,
      };
}

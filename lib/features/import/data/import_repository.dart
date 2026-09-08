/// Import job access: create one, poll it, save what it found, or throw it
/// away.
///
/// The only place in this feature that touches Supabase (CLAUDE.md rule 1).
///
/// Note what is NOT here: no household lookup. `import-text` resolves the
/// household server-side from the caller's membership, and
/// `import_jobs_select` is `is_household_member(household_id)` (D39), so a row
/// this client can read is already a row it is allowed to read. That is why
/// `RecipeRepository._currentHouseholdId` did not have to be copied a third
/// time.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/supabase/supabase_failure.dart';
import '../../recipes/domain/recipe_ingredient.dart';
import '../../recipes/domain/recipe_step.dart';
import '../domain/import_job.dart';
import '../domain/parsed_recipe.dart';

const String _jobColumns =
    'id, kind, status, result, error_code, error_message, recipe_id';

class ImportRepository {
  const ImportRepository(this._client);

  final SupabaseClient _client;

  /// Starts an import from pasted text and returns the job id.
  ///
  /// An Edge Function because it holds the model API key (rule 2) and because
  /// reading a page of prose cannot fit inside the request that started it.
  /// It answers 202 with the id and does the work afterwards, so this returns
  /// almost immediately and the caller polls (D14).
  Future<String> createFromText(String text, {String? sourceUrl}) =>
      runGuarded(() async {
        final FunctionResponse res = await _client.functions.invoke(
          'import-text',
          body: <String, dynamic>{
            'text': text,
            if (sourceUrl != null && sourceUrl.trim().isNotEmpty)
              'sourceUrl': sourceUrl.trim(),
          },
        );

        final Object? data = res.data;
        if (data is! Map<String, dynamic>) {
          throw const UnknownFailure(
              message: 'The server sent an unexpected reply.');
        }
        // camelCase, because this is a hand-built Edge Function body rather
        // than a Postgres row -- the split HouseholdRepository documents.
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
  Future<String> saveImported(
    String jobId, {
    required String title,
    required String originalLocale,
    required List<RecipeIngredient> ingredients,
    required List<RecipeStep> steps,
    String? description,
    int? servings,
    int? prepMinutes,
    int? cookMinutes,
    String? sourceUrl,
    String? sourceAttribution,
    List<String> tags = const <String>[],
  }) =>
      runGuarded(() async {
        final dynamic id = await _client.rpc<dynamic>(
          'save_imported_recipe',
          params: <String, dynamic>{
            'job': jobId,
            'recipe': <String, dynamic>{
              'title': title.trim(),
              'description': description,
              'servings': servings,
              'prep_minutes': prepMinutes,
              'cook_minutes': cookMinutes,
              'original_locale': originalLocale,
              // The D41 mapping: import_jobs.kind has three values and
              // recipes.source_type has four. A paste that carried a URL came
              // off the web; one that did not is somebody typing.
              'source_type': sourceUrl == null || sourceUrl.trim().isEmpty
                  ? 'manual'
                  : 'url_import',
              'source_url': sourceUrl,
              'source_attribution': sourceAttribution,
              'tags': tags,
            },
            'ingredient_lines':
                ingredients.map(_ingredientPayload).toList(growable: false),
            'steps': steps.map(_stepPayload).toList(growable: false),
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

  ImportJob _toJob(Map<String, dynamic> row) {
    final Object? result = row['result'];
    return ImportJob(
      id: row['id'] as String,
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
      };
}

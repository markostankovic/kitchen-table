import 'package:freezed_annotation/freezed_annotation.dart';

import 'parsed_recipe.dart';

part 'import_job.freezed.dart';

/// Where an import came from.
///
/// The three values `import_jobs.kind` allows. They do not map one-for-one
/// onto `recipes.source_type`, which has four: `url` becomes `url_import`,
/// `photo` becomes `ocr`, and `text` becomes `url_import` when the paste
/// carried a source URL and `manual` when it did not.
enum ImportKind {
  url,
  photo,
  text;

  String get wireValue => name;

  static ImportKind fromWire(String value) => switch (value) {
        'url' => ImportKind.url,
        'photo' => ImportKind.photo,
        'text' => ImportKind.text,
        _ => throw ArgumentError.value(value, 'kind', 'unknown import kind'),
      };
}

/// A job's position in the queue (D14).
///
/// `queued` and `processing` are the two the client polls through.
/// `needsReview` is where the confirm screen takes over -- and `done` is only
/// ever reached through `save_imported_recipe`, because D8 puts a human
/// between an import and a saved recipe.
enum ImportJobStatus {
  queued,
  processing,
  needsReview,
  failed,
  done;

  String get wireValue => switch (this) {
        ImportJobStatus.queued => 'queued',
        ImportJobStatus.processing => 'processing',
        ImportJobStatus.needsReview => 'needs_review',
        ImportJobStatus.failed => 'failed',
        ImportJobStatus.done => 'done',
      };

  static ImportJobStatus fromWire(String value) => switch (value) {
        'queued' => ImportJobStatus.queued,
        'processing' => ImportJobStatus.processing,
        'needs_review' => ImportJobStatus.needsReview,
        'failed' => ImportJobStatus.failed,
        'done' => ImportJobStatus.done,
        _ => throw ArgumentError.value(value, 'status', 'unknown job status'),
      };

  /// Whether the server is still working. The poller stops when this is false.
  bool get isPending =>
      this == ImportJobStatus.queued || this == ImportJobStatus.processing;
}

/// One import, as the client sees it.
///
/// No `householdId`: the server resolves the household from the caller's
/// membership when the job is created, and `import_jobs_select` is
/// `is_household_member(household_id)`, so a row the client can read is
/// already a row it is allowed to read. Carrying the id would only invite
/// somebody to filter on it and believe the filter was the security.
///
/// Pure Dart (rule 7).
@freezed
abstract class ImportJob with _$ImportJob {
  const ImportJob._();

  const factory ImportJob({
    required String id,
    required ImportKind kind,
    required ImportJobStatus status,
    ParsedRecipe? result,
    String? errorCode,
    String? errorMessage,
    String? recipeId,
  }) = _ImportJob;

  /// The draft is ready for a human.
  bool get isReviewable =>
      status == ImportJobStatus.needsReview && result != null;
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe.freezed.dart';
part 'recipe.g.dart';

/// Where a recipe came from.
///
/// Only [manual] is reachable in Phase 1c. The rest exist because
/// `docs/ROADMAP.md`'s standing rules turn on this value -- anything
/// AI-produced stays [RecipeStatus.draft] until a human marks it tested, and
/// every import displays its attribution.
enum RecipeSourceType {
  manual,
  urlImport,
  ocr,
  aiGenerated;

  /// The `recipes.source_type` check-constraint vocabulary. The enum names are
  /// Dart's, the wire values are the database's, and they are not the same
  /// spelling -- so the mapping is written once, here, rather than in each
  /// repository method that touches it.
  String get wireValue => switch (this) {
        RecipeSourceType.manual => 'manual',
        RecipeSourceType.urlImport => 'url_import',
        RecipeSourceType.ocr => 'ocr',
        RecipeSourceType.aiGenerated => 'ai_generated',
      };

  static RecipeSourceType fromWire(String value) => switch (value) {
        'manual' => RecipeSourceType.manual,
        'url_import' => RecipeSourceType.urlImport,
        'ocr' => RecipeSourceType.ocr,
        'ai_generated' => RecipeSourceType.aiGenerated,
        _ => throw ArgumentError.value(value, 'source_type', 'unknown'),
      };
}

/// Whether a human has actually cooked this and vouched for it.
///
/// The standing rule is that anything AI-produced is [draft] until somebody
/// says otherwise. Manual entry may start either way.
enum RecipeStatus { draft, tested }

/// A recipe, in its original language.
///
/// Other locales live in `recipe_translations` (Phase 3), and ingredient lines
/// are never translated per recipe -- they render from the catalog, which is
/// the point of D1.
///
/// [deletedAt] crosses into the domain for the same reason it does on
/// `Household`: RLS returns soft-deleted rows (D23) so the Phase 2 cache can
/// evict them. Normal reads filter in `data/`.
///
/// Pure Dart (rule 7).
@freezed
abstract class Recipe with _$Recipe {
  const factory Recipe({
    required String id,
    required String householdId,
    required String title,
    required String originalLocale,
    required RecipeSourceType sourceType,
    required RecipeStatus status,
    required String createdBy,
    String? description,
    int? servings,
    int? prepMinutes,
    int? cookMinutes,
    String? sourceUrl,
    String? sourceAttribution,

    /// A Supabase Storage object path. Always null in Phase 1c -- the bucket
    /// and the picker are Phase 2 (D35). The field ships now so that slice
    /// adds a screen rather than a migration.
    String? imagePath,
    @Default(<String>[]) List<String> tags,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _Recipe;

  factory Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);
}

import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe_image_upload.freezed.dart';

/// A photo picked for a recipe, not yet uploaded.
///
/// Deliberately not part of [RecipeDraft]: the draft is what gets read back
/// from and written to `recipes`, and picked-but-unsaved bytes are neither.
/// The edit screen holds one of these locally and hands it to
/// `RecipeEditor.save()`, which uploads it -- and only it -- as the first step
/// of a save (D48). Abandoning the editor before saving therefore never writes
/// to Storage.
///
/// `dart:typed_data` only, no `dart:io` and no Flutter import -- pure Dart
/// (rule 7), same as every other domain type.
@freezed
abstract class RecipeImageUpload with _$RecipeImageUpload {
  const factory RecipeImageUpload({
    required Uint8List bytes,
    required String contentType,
    required String extension,
  }) = _RecipeImageUpload;
}

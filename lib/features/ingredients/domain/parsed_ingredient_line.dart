import 'package:freezed_annotation/freezed_annotation.dart';

import 'quantity.dart';

part 'parsed_ingredient_line.freezed.dart';
part 'parsed_ingredient_line.g.dart';

/// One ingredient line, after tier 1 of the matcher.
///
/// [rawText] is required and never null -- that is CLAUDE.md rule 3, and it is
/// the whole reason a failed parse is a supported state rather than an error.
/// Every other field is an enhancement on top of it. If the parser recognises
/// nothing, the line still renders exactly as the cook wrote it.
///
/// [name] is the LITERAL remainder of the line, not a de-inflected lemma:
/// `2 šolje glatkog brašna` yields `glatkog brašna`, in the genitive. Turning
/// that into `glatko brašno` would be stemming, which D6 rejects. Resolving it
/// to an ingredient is tier 2's job, and the seeded aliases plus the trigram
/// tier are what make the inflected form land.
///
/// Pure Dart (rule 7).
@freezed
abstract class ParsedIngredientLine with _$ParsedIngredientLine {
  const factory ParsedIngredientLine({
    required String rawText,
    Quantity? quantity,

    /// A `units.code`, never a display name.
    String? unitCode,

    /// What is left after the quantity and unit, with notes removed.
    String? name,

    /// Everything after the first comma, plus any parenthesised text.
    String? note,

    /// `opciono`, `po želji`, `optional`, `to taste`.
    @Default(false) bool isOptional,
  }) = _ParsedIngredientLine;

  factory ParsedIngredientLine.fromJson(Map<String, dynamic> json) =>
      _$ParsedIngredientLineFromJson(json);
}

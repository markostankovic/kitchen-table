// GENERATED CODE -- DO NOT EDIT BY HAND.
//
// Source of truth: supabase/functions/_shared/schema.ts (Zod).
// Regenerate with `make types`. Hand-edits are lost on the next run, and a
// hand-mirrored parse contract drifts silently -- rename a field on the server
// and this file quietly reads null (D18).
//
// ignore_for_file: constant_identifier_names

// To parse this JSON data, do
//
//     final parsedRecipe = parsedRecipeFromJson(jsonString);

import 'package:freezed_annotation/freezed_annotation.dart';

import 'dart:convert';

part 'parsed_recipe.freezed.dart';
part 'parsed_recipe.g.dart';

ParsedRecipe parsedRecipeFromJson(String str) =>
    ParsedRecipe.fromJson(json.decode(str) as Map<String, dynamic>);

String parsedRecipeToJson(ParsedRecipe data) => json.encode(data.toJson());

@freezed
abstract class ParsedRecipe with _$ParsedRecipe {
  const factory ParsedRecipe({
    @JsonKey(name: "cookMinutes") int? cookMinutes,

    ///A headnote or short introduction, if the source has one.
    @JsonKey(name: "description") String? description,
    @JsonKey(name: "ingredients")
    required List<ParsedIngredientLine> ingredients,

    ///The language the recipe is written in. 'sr' for Serbian (in either script), 'en' for
    ///English.
    @JsonKey(name: "originalLocale") required ParsedLocale originalLocale,
    @JsonKey(name: "prepMinutes") int? prepMinutes,
    @JsonKey(name: "servings") int? servings,

    ///Book title, author, page, or site name -- whatever credits the source. Null if the source
    ///does not say.
    @JsonKey(name: "sourceAttribution") String? sourceAttribution,
    @JsonKey(name: "sourceUrl") String? sourceUrl,
    @JsonKey(name: "steps") required List<ParsedStep> steps,
    @JsonKey(name: "title") required String title,
  }) = _ParsedRecipe;

  factory ParsedRecipe.fromJson(Map<String, dynamic> json) =>
      _$ParsedRecipeFromJson(json);
}

@freezed
abstract class ParsedIngredientLine with _$ParsedIngredientLine {
  const factory ParsedIngredientLine({
    @JsonKey(name: "autoAccept") required bool autoAccept,
    @JsonKey(name: "displayName") String? displayName,
    @JsonKey(name: "ingredientId") String? ingredientId,
    @JsonKey(name: "isOptional") required bool isOptional,
    @JsonKey(name: "matchConfidence") double? matchConfidence,
    @JsonKey(name: "matchMethod") ParsedMatchMethod? matchMethod,

    ///The literal remainder after quantity and unit -- inflected as written, because the parser
    ///does not de-inflect (D6).
    @JsonKey(name: "name") String? name,
    @JsonKey(name: "note") String? note,
    @JsonKey(name: "quantity") ParsedQuantity? quantity,

    ///The ingredient line exactly as it appears, including quantity and unit. Do not reformat,
    ///translate, or split it.
    @JsonKey(name: "rawText") required String rawText,

    ///The heading this line sits under, if the list has headings, e.g. 'Za fil' or 'For the
    ///sauce'. Null when the list is flat.
    @JsonKey(name: "section") String? section,

    ///A units.code. Null when no unit was recognised.
    @JsonKey(name: "unitCode") String? unitCode,
  }) = _ParsedIngredientLine;

  factory ParsedIngredientLine.fromJson(Map<String, dynamic> json) =>
      _$ParsedIngredientLineFromJson(json);
}

enum ParsedMatchMethod {
  @JsonValue("alias")
  ALIAS,
  @JsonValue("exact")
  EXACT,
  @JsonValue("fuzzy")
  FUZZY,
  @JsonValue("llm")
  LLM,
}

final parsedMatchMethodValues = EnumValues({
  "alias": ParsedMatchMethod.ALIAS,
  "exact": ParsedMatchMethod.EXACT,
  "fuzzy": ParsedMatchMethod.FUZZY,
  "llm": ParsedMatchMethod.LLM,
});

@freezed
abstract class ParsedQuantity with _$ParsedQuantity {
  const factory ParsedQuantity({
    @JsonKey(name: "den") required int den,
    @JsonKey(name: "maxDen") int? maxDen,
    @JsonKey(name: "maxNum") int? maxNum,
    @JsonKey(name: "num") required int num,
  }) = _ParsedQuantity;

  factory ParsedQuantity.fromJson(Map<String, dynamic> json) =>
      _$ParsedQuantityFromJson(json);
}

///The language the recipe is written in. 'sr' for Serbian (in either script), 'en' for
///English.
enum ParsedLocale {
  @JsonValue("en")
  EN,
  @JsonValue("sr")
  SR,
}

final parsedLocaleValues = EnumValues({
  "en": ParsedLocale.EN,
  "sr": ParsedLocale.SR,
});

@freezed
abstract class ParsedStep with _$ParsedStep {
  const factory ParsedStep({
    ///One preparation step, in the recipe's original language.
    @JsonKey(name: "text") required String text,

    ///Duration in seconds if the step names an explicit time, else null.
    @JsonKey(name: "timerSeconds") int? timerSeconds,
  }) = _ParsedStep;

  factory ParsedStep.fromJson(Map<String, dynamic> json) =>
      _$ParsedStepFromJson(json);
}

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}

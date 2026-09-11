// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe_ingredient.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecipeIngredient {

 int get position;/// HARD RULE (rule 3). What the cook typed, always.
 String get rawText;/// Null for a saved-but-unsaved line, or one that has never been written.
 String? get id;/// A heading within the list -- 'Za fil', 'For the sauce'.
 String? get section;/// Null means the line resolved to nothing in the catalog. Normal, not an
/// error.
 String? get ingredientId;/// The catalog's name for [ingredientId] in the reader's locale, resolved
/// at read time by `ingredient_display_names`. Not persisted on the line
/// -- the whole point of D1 is that this is looked up rather than copied,
/// so one recipe written in Serbian and one in English render the same
/// word.
 String? get displayName;/// An exact integer fraction, never a float (rule 5).
 Quantity? get quantity;/// A `units.code`, never a display name.
 String? get unitCode; String? get note; bool get isOptional;/// Match provenance (D7). A [MatchMethod.manual] link is a human decision
/// and is never overwritten by a later machine pass.
 MatchMethod? get matchMethod; double? get matchConfidence; DateTime? get matchedAt;/// Which recipe this line belongs to.
///
/// Null when the line is read as part of one recipe's own detail, where
/// the answer is the recipe being looked at. Set when lines for several
/// recipes arrive together, which is what the shopping list does -- it has
/// to scale each line by the servings of the entry that planned it, and
/// that is a per-recipe fact.
 String? get recipeId;/// The catalog's `is_pantry_staple` and `category` for [ingredientId],
/// resolved at read time and never written back -- the same arrangement
/// as [displayName] above, and as `MealPlanEntry.recipeTitle` (D53).
///
/// Only the shopping list reads these. A recipe does not care whether an
/// ingredient is a cupboard staple; a list of things to buy is the only
/// place the question means anything.
 bool get isPantryStaple; String? get category;
/// Create a copy of RecipeIngredient
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeIngredientCopyWith<RecipeIngredient> get copyWith => _$RecipeIngredientCopyWithImpl<RecipeIngredient>(this as RecipeIngredient, _$identity);

  /// Serializes this RecipeIngredient to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RecipeIngredient;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipeIngredient&&(identical(other.position, _this.position) || other.position == _this.position)&&(identical(other.rawText, _this.rawText) || other.rawText == _this.rawText)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.section, _this.section) || other.section == _this.section)&&(identical(other.ingredientId, _this.ingredientId) || other.ingredientId == _this.ingredientId)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.quantity, _this.quantity) || other.quantity == _this.quantity)&&(identical(other.unitCode, _this.unitCode) || other.unitCode == _this.unitCode)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.isOptional, _this.isOptional) || other.isOptional == _this.isOptional)&&(identical(other.matchMethod, _this.matchMethod) || other.matchMethod == _this.matchMethod)&&(identical(other.matchConfidence, _this.matchConfidence) || other.matchConfidence == _this.matchConfidence)&&(identical(other.matchedAt, _this.matchedAt) || other.matchedAt == _this.matchedAt)&&(identical(other.recipeId, _this.recipeId) || other.recipeId == _this.recipeId)&&(identical(other.isPantryStaple, _this.isPantryStaple) || other.isPantryStaple == _this.isPantryStaple)&&(identical(other.category, _this.category) || other.category == _this.category));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RecipeIngredient;
  return Object.hash(runtimeType,_this.position,_this.rawText,_this.id,_this.section,_this.ingredientId,_this.displayName,_this.quantity,_this.unitCode,_this.note,_this.isOptional,_this.matchMethod,_this.matchConfidence,_this.matchedAt,_this.recipeId,_this.isPantryStaple,_this.category);
}

@override
String toString() {
  final _this = this as RecipeIngredient;
  return 'RecipeIngredient(position: ${_this.position}, rawText: ${_this.rawText}, id: ${_this.id}, section: ${_this.section}, ingredientId: ${_this.ingredientId}, displayName: ${_this.displayName}, quantity: ${_this.quantity}, unitCode: ${_this.unitCode}, note: ${_this.note}, isOptional: ${_this.isOptional}, matchMethod: ${_this.matchMethod}, matchConfidence: ${_this.matchConfidence}, matchedAt: ${_this.matchedAt}, recipeId: ${_this.recipeId}, isPantryStaple: ${_this.isPantryStaple}, category: ${_this.category})';
}


}

/// @nodoc
abstract mixin class $RecipeIngredientCopyWith<$Res>  {
  factory $RecipeIngredientCopyWith(RecipeIngredient value, $Res Function(RecipeIngredient) _then) = _$RecipeIngredientCopyWithImpl;
@useResult
$Res call({
 int position, String rawText, String? id, String? section, String? ingredientId, String? displayName, Quantity? quantity, String? unitCode, String? note, bool isOptional, MatchMethod? matchMethod, double? matchConfidence, DateTime? matchedAt, String? recipeId, bool isPantryStaple, String? category
});


$QuantityCopyWith<$Res>? get quantity;

}
/// @nodoc
class _$RecipeIngredientCopyWithImpl<$Res>
    implements $RecipeIngredientCopyWith<$Res> {
  _$RecipeIngredientCopyWithImpl(this._self, this._then);

  final RecipeIngredient _self;
  final $Res Function(RecipeIngredient) _then;

/// Create a copy of RecipeIngredient
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? position = null,Object? rawText = null,Object? id = freezed,Object? section = freezed,Object? ingredientId = freezed,Object? displayName = freezed,Object? quantity = freezed,Object? unitCode = freezed,Object? note = freezed,Object? isOptional = null,Object? matchMethod = freezed,Object? matchConfidence = freezed,Object? matchedAt = freezed,Object? recipeId = freezed,Object? isPantryStaple = null,Object? category = freezed,}) {
  return _then(RecipeIngredient(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,rawText: null == rawText ? _self.rawText : rawText // ignore: cast_nullable_to_non_nullable
as String,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,section: freezed == section ? _self.section : section // ignore: cast_nullable_to_non_nullable
as String?,ingredientId: freezed == ingredientId ? _self.ingredientId : ingredientId // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as Quantity?,unitCode: freezed == unitCode ? _self.unitCode : unitCode // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,isOptional: null == isOptional ? _self.isOptional : isOptional // ignore: cast_nullable_to_non_nullable
as bool,matchMethod: freezed == matchMethod ? _self.matchMethod : matchMethod // ignore: cast_nullable_to_non_nullable
as MatchMethod?,matchConfidence: freezed == matchConfidence ? _self.matchConfidence : matchConfidence // ignore: cast_nullable_to_non_nullable
as double?,matchedAt: freezed == matchedAt ? _self.matchedAt : matchedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,recipeId: freezed == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String?,isPantryStaple: null == isPantryStaple ? _self.isPantryStaple : isPantryStaple // ignore: cast_nullable_to_non_nullable
as bool,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of RecipeIngredient
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuantityCopyWith<$Res>? get quantity {
    if (_self.quantity == null) {
    return null;
  }

  return $QuantityCopyWith<$Res>(_self.quantity!, (value) {
    return _then(_self.copyWith(quantity: value));
  });
}
}


/// Adds pattern-matching-related methods to [RecipeIngredient].
extension RecipeIngredientPatterns on RecipeIngredient {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecipeIngredient value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecipeIngredient() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecipeIngredient value)  $default,){
final _that = this;
switch (_that) {
case _RecipeIngredient():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecipeIngredient value)?  $default,){
final _that = this;
switch (_that) {
case _RecipeIngredient() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int position,  String rawText,  String? id,  String? section,  String? ingredientId,  String? displayName,  Quantity? quantity,  String? unitCode,  String? note,  bool isOptional,  MatchMethod? matchMethod,  double? matchConfidence,  DateTime? matchedAt,  String? recipeId,  bool isPantryStaple,  String? category)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecipeIngredient() when $default != null:
return $default(_that.position,_that.rawText,_that.id,_that.section,_that.ingredientId,_that.displayName,_that.quantity,_that.unitCode,_that.note,_that.isOptional,_that.matchMethod,_that.matchConfidence,_that.matchedAt,_that.recipeId,_that.isPantryStaple,_that.category);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int position,  String rawText,  String? id,  String? section,  String? ingredientId,  String? displayName,  Quantity? quantity,  String? unitCode,  String? note,  bool isOptional,  MatchMethod? matchMethod,  double? matchConfidence,  DateTime? matchedAt,  String? recipeId,  bool isPantryStaple,  String? category)  $default,) {final _that = this;
switch (_that) {
case _RecipeIngredient():
return $default(_that.position,_that.rawText,_that.id,_that.section,_that.ingredientId,_that.displayName,_that.quantity,_that.unitCode,_that.note,_that.isOptional,_that.matchMethod,_that.matchConfidence,_that.matchedAt,_that.recipeId,_that.isPantryStaple,_that.category);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int position,  String rawText,  String? id,  String? section,  String? ingredientId,  String? displayName,  Quantity? quantity,  String? unitCode,  String? note,  bool isOptional,  MatchMethod? matchMethod,  double? matchConfidence,  DateTime? matchedAt,  String? recipeId,  bool isPantryStaple,  String? category)?  $default,) {final _that = this;
switch (_that) {
case _RecipeIngredient() when $default != null:
return $default(_that.position,_that.rawText,_that.id,_that.section,_that.ingredientId,_that.displayName,_that.quantity,_that.unitCode,_that.note,_that.isOptional,_that.matchMethod,_that.matchConfidence,_that.matchedAt,_that.recipeId,_that.isPantryStaple,_that.category);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecipeIngredient extends RecipeIngredient {
  const _RecipeIngredient({required this.position, required this.rawText, this.id, this.section, this.ingredientId, this.displayName, this.quantity, this.unitCode, this.note, this.isOptional = false, this.matchMethod, this.matchConfidence, this.matchedAt, this.recipeId, this.isPantryStaple = false, this.category}): super._();
  factory _RecipeIngredient.fromJson(Map<String, dynamic> json) => _$RecipeIngredientFromJson(json);

@override final  int position;
/// HARD RULE (rule 3). What the cook typed, always.
@override final  String rawText;
/// Null for a saved-but-unsaved line, or one that has never been written.
@override final  String? id;
/// A heading within the list -- 'Za fil', 'For the sauce'.
@override final  String? section;
/// Null means the line resolved to nothing in the catalog. Normal, not an
/// error.
@override final  String? ingredientId;
/// The catalog's name for [ingredientId] in the reader's locale, resolved
/// at read time by `ingredient_display_names`. Not persisted on the line
/// -- the whole point of D1 is that this is looked up rather than copied,
/// so one recipe written in Serbian and one in English render the same
/// word.
@override final  String? displayName;
/// An exact integer fraction, never a float (rule 5).
@override final  Quantity? quantity;
/// A `units.code`, never a display name.
@override final  String? unitCode;
@override final  String? note;
@override@JsonKey() final  bool isOptional;
/// Match provenance (D7). A [MatchMethod.manual] link is a human decision
/// and is never overwritten by a later machine pass.
@override final  MatchMethod? matchMethod;
@override final  double? matchConfidence;
@override final  DateTime? matchedAt;
/// Which recipe this line belongs to.
///
/// Null when the line is read as part of one recipe's own detail, where
/// the answer is the recipe being looked at. Set when lines for several
/// recipes arrive together, which is what the shopping list does -- it has
/// to scale each line by the servings of the entry that planned it, and
/// that is a per-recipe fact.
@override final  String? recipeId;
/// The catalog's `is_pantry_staple` and `category` for [ingredientId],
/// resolved at read time and never written back -- the same arrangement
/// as [displayName] above, and as `MealPlanEntry.recipeTitle` (D53).
///
/// Only the shopping list reads these. A recipe does not care whether an
/// ingredient is a cupboard staple; a list of things to buy is the only
/// place the question means anything.
@override@JsonKey() final  bool isPantryStaple;
@override final  String? category;

/// Create a copy of RecipeIngredient
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeIngredientCopyWith<_RecipeIngredient> get copyWith => __$RecipeIngredientCopyWithImpl<_RecipeIngredient>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecipeIngredientToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipeIngredient&&(identical(other.position, position) || other.position == position)&&(identical(other.rawText, rawText) || other.rawText == rawText)&&(identical(other.id, id) || other.id == id)&&(identical(other.section, section) || other.section == section)&&(identical(other.ingredientId, ingredientId) || other.ingredientId == ingredientId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitCode, unitCode) || other.unitCode == unitCode)&&(identical(other.note, note) || other.note == note)&&(identical(other.isOptional, isOptional) || other.isOptional == isOptional)&&(identical(other.matchMethod, matchMethod) || other.matchMethod == matchMethod)&&(identical(other.matchConfidence, matchConfidence) || other.matchConfidence == matchConfidence)&&(identical(other.matchedAt, matchedAt) || other.matchedAt == matchedAt)&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId)&&(identical(other.isPantryStaple, isPantryStaple) || other.isPantryStaple == isPantryStaple)&&(identical(other.category, category) || other.category == category));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,position,rawText,id,section,ingredientId,displayName,quantity,unitCode,note,isOptional,matchMethod,matchConfidence,matchedAt,recipeId,isPantryStaple,category);
}

@override
String toString() {
    return 'RecipeIngredient(position: $position, rawText: $rawText, id: $id, section: $section, ingredientId: $ingredientId, displayName: $displayName, quantity: $quantity, unitCode: $unitCode, note: $note, isOptional: $isOptional, matchMethod: $matchMethod, matchConfidence: $matchConfidence, matchedAt: $matchedAt, recipeId: $recipeId, isPantryStaple: $isPantryStaple, category: $category)';
}


}

/// @nodoc
abstract mixin class _$RecipeIngredientCopyWith<$Res> implements $RecipeIngredientCopyWith<$Res> {
  factory _$RecipeIngredientCopyWith(_RecipeIngredient value, $Res Function(_RecipeIngredient) _then) = __$RecipeIngredientCopyWithImpl;
@override @useResult
$Res call({
 int position, String rawText, String? id, String? section, String? ingredientId, String? displayName, Quantity? quantity, String? unitCode, String? note, bool isOptional, MatchMethod? matchMethod, double? matchConfidence, DateTime? matchedAt, String? recipeId, bool isPantryStaple, String? category
});


@override $QuantityCopyWith<$Res>? get quantity;

}
/// @nodoc
class __$RecipeIngredientCopyWithImpl<$Res>
    implements _$RecipeIngredientCopyWith<$Res> {
  __$RecipeIngredientCopyWithImpl(this._self, this._then);

  final _RecipeIngredient _self;
  final $Res Function(_RecipeIngredient) _then;

/// Create a copy of RecipeIngredient
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? position = null,Object? rawText = null,Object? id = freezed,Object? section = freezed,Object? ingredientId = freezed,Object? displayName = freezed,Object? quantity = freezed,Object? unitCode = freezed,Object? note = freezed,Object? isOptional = null,Object? matchMethod = freezed,Object? matchConfidence = freezed,Object? matchedAt = freezed,Object? recipeId = freezed,Object? isPantryStaple = null,Object? category = freezed,}) {
  return _then(_RecipeIngredient(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,rawText: null == rawText ? _self.rawText : rawText // ignore: cast_nullable_to_non_nullable
as String,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,section: freezed == section ? _self.section : section // ignore: cast_nullable_to_non_nullable
as String?,ingredientId: freezed == ingredientId ? _self.ingredientId : ingredientId // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as Quantity?,unitCode: freezed == unitCode ? _self.unitCode : unitCode // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,isOptional: null == isOptional ? _self.isOptional : isOptional // ignore: cast_nullable_to_non_nullable
as bool,matchMethod: freezed == matchMethod ? _self.matchMethod : matchMethod // ignore: cast_nullable_to_non_nullable
as MatchMethod?,matchConfidence: freezed == matchConfidence ? _self.matchConfidence : matchConfidence // ignore: cast_nullable_to_non_nullable
as double?,matchedAt: freezed == matchedAt ? _self.matchedAt : matchedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,recipeId: freezed == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String?,isPantryStaple: null == isPantryStaple ? _self.isPantryStaple : isPantryStaple // ignore: cast_nullable_to_non_nullable
as bool,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of RecipeIngredient
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuantityCopyWith<$Res>? get quantity {
    if (_self.quantity == null) {
    return null;
  }

  return $QuantityCopyWith<$Res>(_self.quantity!, (value) {
    return _then(_self.copyWith(quantity: value));
  });
}
}

// dart format on

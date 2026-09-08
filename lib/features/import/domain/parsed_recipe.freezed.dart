// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'parsed_recipe.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ParsedRecipe {

@JsonKey(name: "cookMinutes") int? get cookMinutes;///A headnote or short introduction, if the source has one.
@JsonKey(name: "description") String? get description;@JsonKey(name: "ingredients") List<ParsedIngredientLine> get ingredients;///The language the recipe is written in. 'sr' for Serbian (in either script), 'en' for
///English.
@JsonKey(name: "originalLocale") ParsedLocale get originalLocale;@JsonKey(name: "prepMinutes") int? get prepMinutes;@JsonKey(name: "servings") int? get servings;///Book title, author, page, or site name -- whatever credits the source. Null if the source
///does not say.
@JsonKey(name: "sourceAttribution") String? get sourceAttribution;@JsonKey(name: "sourceUrl") String? get sourceUrl;@JsonKey(name: "steps") List<ParsedStep> get steps;@JsonKey(name: "title") String get title;
/// Create a copy of ParsedRecipe
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParsedRecipeCopyWith<ParsedRecipe> get copyWith => _$ParsedRecipeCopyWithImpl<ParsedRecipe>(this as ParsedRecipe, _$identity);

  /// Serializes this ParsedRecipe to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ParsedRecipe;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParsedRecipe&&(identical(other.cookMinutes, _this.cookMinutes) || other.cookMinutes == _this.cookMinutes)&&(identical(other.description, _this.description) || other.description == _this.description)&&const DeepCollectionEquality().equals(other.ingredients, _this.ingredients)&&(identical(other.originalLocale, _this.originalLocale) || other.originalLocale == _this.originalLocale)&&(identical(other.prepMinutes, _this.prepMinutes) || other.prepMinutes == _this.prepMinutes)&&(identical(other.servings, _this.servings) || other.servings == _this.servings)&&(identical(other.sourceAttribution, _this.sourceAttribution) || other.sourceAttribution == _this.sourceAttribution)&&(identical(other.sourceUrl, _this.sourceUrl) || other.sourceUrl == _this.sourceUrl)&&const DeepCollectionEquality().equals(other.steps, _this.steps)&&(identical(other.title, _this.title) || other.title == _this.title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ParsedRecipe;
  return Object.hash(runtimeType,_this.cookMinutes,_this.description,const DeepCollectionEquality().hash(_this.ingredients),_this.originalLocale,_this.prepMinutes,_this.servings,_this.sourceAttribution,_this.sourceUrl,const DeepCollectionEquality().hash(_this.steps),_this.title);
}

@override
String toString() {
  final _this = this as ParsedRecipe;
  return 'ParsedRecipe(cookMinutes: ${_this.cookMinutes}, description: ${_this.description}, ingredients: ${_this.ingredients}, originalLocale: ${_this.originalLocale}, prepMinutes: ${_this.prepMinutes}, servings: ${_this.servings}, sourceAttribution: ${_this.sourceAttribution}, sourceUrl: ${_this.sourceUrl}, steps: ${_this.steps}, title: ${_this.title})';
}


}

/// @nodoc
abstract mixin class $ParsedRecipeCopyWith<$Res>  {
  factory $ParsedRecipeCopyWith(ParsedRecipe value, $Res Function(ParsedRecipe) _then) = _$ParsedRecipeCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "cookMinutes") int? cookMinutes,@JsonKey(name: "description") String? description,@JsonKey(name: "ingredients") List<ParsedIngredientLine> ingredients,@JsonKey(name: "originalLocale") ParsedLocale originalLocale,@JsonKey(name: "prepMinutes") int? prepMinutes,@JsonKey(name: "servings") int? servings,@JsonKey(name: "sourceAttribution") String? sourceAttribution,@JsonKey(name: "sourceUrl") String? sourceUrl,@JsonKey(name: "steps") List<ParsedStep> steps,@JsonKey(name: "title") String title
});




}
/// @nodoc
class _$ParsedRecipeCopyWithImpl<$Res>
    implements $ParsedRecipeCopyWith<$Res> {
  _$ParsedRecipeCopyWithImpl(this._self, this._then);

  final ParsedRecipe _self;
  final $Res Function(ParsedRecipe) _then;

/// Create a copy of ParsedRecipe
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cookMinutes = freezed,Object? description = freezed,Object? ingredients = null,Object? originalLocale = null,Object? prepMinutes = freezed,Object? servings = freezed,Object? sourceAttribution = freezed,Object? sourceUrl = freezed,Object? steps = null,Object? title = null,}) {
  return _then(ParsedRecipe(
cookMinutes: freezed == cookMinutes ? _self.cookMinutes : cookMinutes // ignore: cast_nullable_to_non_nullable
as int?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,ingredients: null == ingredients ? _self.ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as List<ParsedIngredientLine>,originalLocale: null == originalLocale ? _self.originalLocale : originalLocale // ignore: cast_nullable_to_non_nullable
as ParsedLocale,prepMinutes: freezed == prepMinutes ? _self.prepMinutes : prepMinutes // ignore: cast_nullable_to_non_nullable
as int?,servings: freezed == servings ? _self.servings : servings // ignore: cast_nullable_to_non_nullable
as int?,sourceAttribution: freezed == sourceAttribution ? _self.sourceAttribution : sourceAttribution // ignore: cast_nullable_to_non_nullable
as String?,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<ParsedStep>,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ParsedRecipe].
extension ParsedRecipePatterns on ParsedRecipe {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParsedRecipe value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParsedRecipe() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParsedRecipe value)  $default,){
final _that = this;
switch (_that) {
case _ParsedRecipe():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParsedRecipe value)?  $default,){
final _that = this;
switch (_that) {
case _ParsedRecipe() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "cookMinutes")  int? cookMinutes, @JsonKey(name: "description")  String? description, @JsonKey(name: "ingredients")  List<ParsedIngredientLine> ingredients, @JsonKey(name: "originalLocale")  ParsedLocale originalLocale, @JsonKey(name: "prepMinutes")  int? prepMinutes, @JsonKey(name: "servings")  int? servings, @JsonKey(name: "sourceAttribution")  String? sourceAttribution, @JsonKey(name: "sourceUrl")  String? sourceUrl, @JsonKey(name: "steps")  List<ParsedStep> steps, @JsonKey(name: "title")  String title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParsedRecipe() when $default != null:
return $default(_that.cookMinutes,_that.description,_that.ingredients,_that.originalLocale,_that.prepMinutes,_that.servings,_that.sourceAttribution,_that.sourceUrl,_that.steps,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "cookMinutes")  int? cookMinutes, @JsonKey(name: "description")  String? description, @JsonKey(name: "ingredients")  List<ParsedIngredientLine> ingredients, @JsonKey(name: "originalLocale")  ParsedLocale originalLocale, @JsonKey(name: "prepMinutes")  int? prepMinutes, @JsonKey(name: "servings")  int? servings, @JsonKey(name: "sourceAttribution")  String? sourceAttribution, @JsonKey(name: "sourceUrl")  String? sourceUrl, @JsonKey(name: "steps")  List<ParsedStep> steps, @JsonKey(name: "title")  String title)  $default,) {final _that = this;
switch (_that) {
case _ParsedRecipe():
return $default(_that.cookMinutes,_that.description,_that.ingredients,_that.originalLocale,_that.prepMinutes,_that.servings,_that.sourceAttribution,_that.sourceUrl,_that.steps,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "cookMinutes")  int? cookMinutes, @JsonKey(name: "description")  String? description, @JsonKey(name: "ingredients")  List<ParsedIngredientLine> ingredients, @JsonKey(name: "originalLocale")  ParsedLocale originalLocale, @JsonKey(name: "prepMinutes")  int? prepMinutes, @JsonKey(name: "servings")  int? servings, @JsonKey(name: "sourceAttribution")  String? sourceAttribution, @JsonKey(name: "sourceUrl")  String? sourceUrl, @JsonKey(name: "steps")  List<ParsedStep> steps, @JsonKey(name: "title")  String title)?  $default,) {final _that = this;
switch (_that) {
case _ParsedRecipe() when $default != null:
return $default(_that.cookMinutes,_that.description,_that.ingredients,_that.originalLocale,_that.prepMinutes,_that.servings,_that.sourceAttribution,_that.sourceUrl,_that.steps,_that.title);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ParsedRecipe implements ParsedRecipe {
  const _ParsedRecipe({@JsonKey(name: "cookMinutes") this.cookMinutes, @JsonKey(name: "description") this.description, @JsonKey(name: "ingredients") required  List<ParsedIngredientLine> ingredients, @JsonKey(name: "originalLocale") required this.originalLocale, @JsonKey(name: "prepMinutes") this.prepMinutes, @JsonKey(name: "servings") this.servings, @JsonKey(name: "sourceAttribution") this.sourceAttribution, @JsonKey(name: "sourceUrl") this.sourceUrl, @JsonKey(name: "steps") required  List<ParsedStep> steps, @JsonKey(name: "title") required this.title}): _ingredients = ingredients,_steps = steps;
  factory _ParsedRecipe.fromJson(Map<String, dynamic> json) => _$ParsedRecipeFromJson(json);

@override@JsonKey(name: "cookMinutes") final  int? cookMinutes;
///A headnote or short introduction, if the source has one.
@override@JsonKey(name: "description") final  String? description;
 final  List<ParsedIngredientLine> _ingredients;
@override@JsonKey(name: "ingredients") List<ParsedIngredientLine> get ingredients {
  if (_ingredients is EqualUnmodifiableListView) return _ingredients;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ingredients);
}

///The language the recipe is written in. 'sr' for Serbian (in either script), 'en' for
///English.
@override@JsonKey(name: "originalLocale") final  ParsedLocale originalLocale;
@override@JsonKey(name: "prepMinutes") final  int? prepMinutes;
@override@JsonKey(name: "servings") final  int? servings;
///Book title, author, page, or site name -- whatever credits the source. Null if the source
///does not say.
@override@JsonKey(name: "sourceAttribution") final  String? sourceAttribution;
@override@JsonKey(name: "sourceUrl") final  String? sourceUrl;
 final  List<ParsedStep> _steps;
@override@JsonKey(name: "steps") List<ParsedStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}

@override@JsonKey(name: "title") final  String title;

/// Create a copy of ParsedRecipe
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParsedRecipeCopyWith<_ParsedRecipe> get copyWith => __$ParsedRecipeCopyWithImpl<_ParsedRecipe>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ParsedRecipeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParsedRecipe&&(identical(other.cookMinutes, cookMinutes) || other.cookMinutes == cookMinutes)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.ingredients, _ingredients)&&(identical(other.originalLocale, originalLocale) || other.originalLocale == originalLocale)&&(identical(other.prepMinutes, prepMinutes) || other.prepMinutes == prepMinutes)&&(identical(other.servings, servings) || other.servings == servings)&&(identical(other.sourceAttribution, sourceAttribution) || other.sourceAttribution == sourceAttribution)&&(identical(other.sourceUrl, sourceUrl) || other.sourceUrl == sourceUrl)&&const DeepCollectionEquality().equals(other.steps, _steps)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,cookMinutes,description,const DeepCollectionEquality().hash(_ingredients),originalLocale,prepMinutes,servings,sourceAttribution,sourceUrl,const DeepCollectionEquality().hash(_steps),title);
}

@override
String toString() {
    return 'ParsedRecipe(cookMinutes: $cookMinutes, description: $description, ingredients: $ingredients, originalLocale: $originalLocale, prepMinutes: $prepMinutes, servings: $servings, sourceAttribution: $sourceAttribution, sourceUrl: $sourceUrl, steps: $steps, title: $title)';
}


}

/// @nodoc
abstract mixin class _$ParsedRecipeCopyWith<$Res> implements $ParsedRecipeCopyWith<$Res> {
  factory _$ParsedRecipeCopyWith(_ParsedRecipe value, $Res Function(_ParsedRecipe) _then) = __$ParsedRecipeCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "cookMinutes") int? cookMinutes,@JsonKey(name: "description") String? description,@JsonKey(name: "ingredients") List<ParsedIngredientLine> ingredients,@JsonKey(name: "originalLocale") ParsedLocale originalLocale,@JsonKey(name: "prepMinutes") int? prepMinutes,@JsonKey(name: "servings") int? servings,@JsonKey(name: "sourceAttribution") String? sourceAttribution,@JsonKey(name: "sourceUrl") String? sourceUrl,@JsonKey(name: "steps") List<ParsedStep> steps,@JsonKey(name: "title") String title
});




}
/// @nodoc
class __$ParsedRecipeCopyWithImpl<$Res>
    implements _$ParsedRecipeCopyWith<$Res> {
  __$ParsedRecipeCopyWithImpl(this._self, this._then);

  final _ParsedRecipe _self;
  final $Res Function(_ParsedRecipe) _then;

/// Create a copy of ParsedRecipe
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cookMinutes = freezed,Object? description = freezed,Object? ingredients = null,Object? originalLocale = null,Object? prepMinutes = freezed,Object? servings = freezed,Object? sourceAttribution = freezed,Object? sourceUrl = freezed,Object? steps = null,Object? title = null,}) {
  return _then(_ParsedRecipe(
cookMinutes: freezed == cookMinutes ? _self.cookMinutes : cookMinutes // ignore: cast_nullable_to_non_nullable
as int?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,ingredients: null == ingredients ? _self._ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as List<ParsedIngredientLine>,originalLocale: null == originalLocale ? _self.originalLocale : originalLocale // ignore: cast_nullable_to_non_nullable
as ParsedLocale,prepMinutes: freezed == prepMinutes ? _self.prepMinutes : prepMinutes // ignore: cast_nullable_to_non_nullable
as int?,servings: freezed == servings ? _self.servings : servings // ignore: cast_nullable_to_non_nullable
as int?,sourceAttribution: freezed == sourceAttribution ? _self.sourceAttribution : sourceAttribution // ignore: cast_nullable_to_non_nullable
as String?,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<ParsedStep>,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ParsedIngredientLine {

@JsonKey(name: "autoAccept") bool get autoAccept;@JsonKey(name: "displayName") String? get displayName;@JsonKey(name: "ingredientId") String? get ingredientId;@JsonKey(name: "isOptional") bool get isOptional;@JsonKey(name: "matchConfidence") double? get matchConfidence;@JsonKey(name: "matchMethod") ParsedMatchMethod? get matchMethod;///The literal remainder after quantity and unit -- inflected as written, because the parser
///does not de-inflect (D6).
@JsonKey(name: "name") String? get name;@JsonKey(name: "note") String? get note;@JsonKey(name: "quantity") ParsedQuantity? get quantity;///The ingredient line exactly as it appears, including quantity and unit. Do not reformat,
///translate, or split it.
@JsonKey(name: "rawText") String get rawText;///The heading this line sits under, if the list has headings, e.g. 'Za fil' or 'For the
///sauce'. Null when the list is flat.
@JsonKey(name: "section") String? get section;///A units.code. Null when no unit was recognised.
@JsonKey(name: "unitCode") String? get unitCode;
/// Create a copy of ParsedIngredientLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParsedIngredientLineCopyWith<ParsedIngredientLine> get copyWith => _$ParsedIngredientLineCopyWithImpl<ParsedIngredientLine>(this as ParsedIngredientLine, _$identity);

  /// Serializes this ParsedIngredientLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ParsedIngredientLine;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParsedIngredientLine&&(identical(other.autoAccept, _this.autoAccept) || other.autoAccept == _this.autoAccept)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.ingredientId, _this.ingredientId) || other.ingredientId == _this.ingredientId)&&(identical(other.isOptional, _this.isOptional) || other.isOptional == _this.isOptional)&&(identical(other.matchConfidence, _this.matchConfidence) || other.matchConfidence == _this.matchConfidence)&&(identical(other.matchMethod, _this.matchMethod) || other.matchMethod == _this.matchMethod)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.quantity, _this.quantity) || other.quantity == _this.quantity)&&(identical(other.rawText, _this.rawText) || other.rawText == _this.rawText)&&(identical(other.section, _this.section) || other.section == _this.section)&&(identical(other.unitCode, _this.unitCode) || other.unitCode == _this.unitCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ParsedIngredientLine;
  return Object.hash(runtimeType,_this.autoAccept,_this.displayName,_this.ingredientId,_this.isOptional,_this.matchConfidence,_this.matchMethod,_this.name,_this.note,_this.quantity,_this.rawText,_this.section,_this.unitCode);
}

@override
String toString() {
  final _this = this as ParsedIngredientLine;
  return 'ParsedIngredientLine(autoAccept: ${_this.autoAccept}, displayName: ${_this.displayName}, ingredientId: ${_this.ingredientId}, isOptional: ${_this.isOptional}, matchConfidence: ${_this.matchConfidence}, matchMethod: ${_this.matchMethod}, name: ${_this.name}, note: ${_this.note}, quantity: ${_this.quantity}, rawText: ${_this.rawText}, section: ${_this.section}, unitCode: ${_this.unitCode})';
}


}

/// @nodoc
abstract mixin class $ParsedIngredientLineCopyWith<$Res>  {
  factory $ParsedIngredientLineCopyWith(ParsedIngredientLine value, $Res Function(ParsedIngredientLine) _then) = _$ParsedIngredientLineCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "autoAccept") bool autoAccept,@JsonKey(name: "displayName") String? displayName,@JsonKey(name: "ingredientId") String? ingredientId,@JsonKey(name: "isOptional") bool isOptional,@JsonKey(name: "matchConfidence") double? matchConfidence,@JsonKey(name: "matchMethod") ParsedMatchMethod? matchMethod,@JsonKey(name: "name") String? name,@JsonKey(name: "note") String? note,@JsonKey(name: "quantity") ParsedQuantity? quantity,@JsonKey(name: "rawText") String rawText,@JsonKey(name: "section") String? section,@JsonKey(name: "unitCode") String? unitCode
});


$ParsedQuantityCopyWith<$Res>? get quantity;

}
/// @nodoc
class _$ParsedIngredientLineCopyWithImpl<$Res>
    implements $ParsedIngredientLineCopyWith<$Res> {
  _$ParsedIngredientLineCopyWithImpl(this._self, this._then);

  final ParsedIngredientLine _self;
  final $Res Function(ParsedIngredientLine) _then;

/// Create a copy of ParsedIngredientLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? autoAccept = null,Object? displayName = freezed,Object? ingredientId = freezed,Object? isOptional = null,Object? matchConfidence = freezed,Object? matchMethod = freezed,Object? name = freezed,Object? note = freezed,Object? quantity = freezed,Object? rawText = null,Object? section = freezed,Object? unitCode = freezed,}) {
  return _then(ParsedIngredientLine(
autoAccept: null == autoAccept ? _self.autoAccept : autoAccept // ignore: cast_nullable_to_non_nullable
as bool,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,ingredientId: freezed == ingredientId ? _self.ingredientId : ingredientId // ignore: cast_nullable_to_non_nullable
as String?,isOptional: null == isOptional ? _self.isOptional : isOptional // ignore: cast_nullable_to_non_nullable
as bool,matchConfidence: freezed == matchConfidence ? _self.matchConfidence : matchConfidence // ignore: cast_nullable_to_non_nullable
as double?,matchMethod: freezed == matchMethod ? _self.matchMethod : matchMethod // ignore: cast_nullable_to_non_nullable
as ParsedMatchMethod?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as ParsedQuantity?,rawText: null == rawText ? _self.rawText : rawText // ignore: cast_nullable_to_non_nullable
as String,section: freezed == section ? _self.section : section // ignore: cast_nullable_to_non_nullable
as String?,unitCode: freezed == unitCode ? _self.unitCode : unitCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ParsedIngredientLine
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParsedQuantityCopyWith<$Res>? get quantity {
    if (_self.quantity == null) {
    return null;
  }

  return $ParsedQuantityCopyWith<$Res>(_self.quantity!, (value) {
    return _then(_self.copyWith(quantity: value));
  });
}
}


/// Adds pattern-matching-related methods to [ParsedIngredientLine].
extension ParsedIngredientLinePatterns on ParsedIngredientLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParsedIngredientLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParsedIngredientLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParsedIngredientLine value)  $default,){
final _that = this;
switch (_that) {
case _ParsedIngredientLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParsedIngredientLine value)?  $default,){
final _that = this;
switch (_that) {
case _ParsedIngredientLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "autoAccept")  bool autoAccept, @JsonKey(name: "displayName")  String? displayName, @JsonKey(name: "ingredientId")  String? ingredientId, @JsonKey(name: "isOptional")  bool isOptional, @JsonKey(name: "matchConfidence")  double? matchConfidence, @JsonKey(name: "matchMethod")  ParsedMatchMethod? matchMethod, @JsonKey(name: "name")  String? name, @JsonKey(name: "note")  String? note, @JsonKey(name: "quantity")  ParsedQuantity? quantity, @JsonKey(name: "rawText")  String rawText, @JsonKey(name: "section")  String? section, @JsonKey(name: "unitCode")  String? unitCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParsedIngredientLine() when $default != null:
return $default(_that.autoAccept,_that.displayName,_that.ingredientId,_that.isOptional,_that.matchConfidence,_that.matchMethod,_that.name,_that.note,_that.quantity,_that.rawText,_that.section,_that.unitCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "autoAccept")  bool autoAccept, @JsonKey(name: "displayName")  String? displayName, @JsonKey(name: "ingredientId")  String? ingredientId, @JsonKey(name: "isOptional")  bool isOptional, @JsonKey(name: "matchConfidence")  double? matchConfidence, @JsonKey(name: "matchMethod")  ParsedMatchMethod? matchMethod, @JsonKey(name: "name")  String? name, @JsonKey(name: "note")  String? note, @JsonKey(name: "quantity")  ParsedQuantity? quantity, @JsonKey(name: "rawText")  String rawText, @JsonKey(name: "section")  String? section, @JsonKey(name: "unitCode")  String? unitCode)  $default,) {final _that = this;
switch (_that) {
case _ParsedIngredientLine():
return $default(_that.autoAccept,_that.displayName,_that.ingredientId,_that.isOptional,_that.matchConfidence,_that.matchMethod,_that.name,_that.note,_that.quantity,_that.rawText,_that.section,_that.unitCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "autoAccept")  bool autoAccept, @JsonKey(name: "displayName")  String? displayName, @JsonKey(name: "ingredientId")  String? ingredientId, @JsonKey(name: "isOptional")  bool isOptional, @JsonKey(name: "matchConfidence")  double? matchConfidence, @JsonKey(name: "matchMethod")  ParsedMatchMethod? matchMethod, @JsonKey(name: "name")  String? name, @JsonKey(name: "note")  String? note, @JsonKey(name: "quantity")  ParsedQuantity? quantity, @JsonKey(name: "rawText")  String rawText, @JsonKey(name: "section")  String? section, @JsonKey(name: "unitCode")  String? unitCode)?  $default,) {final _that = this;
switch (_that) {
case _ParsedIngredientLine() when $default != null:
return $default(_that.autoAccept,_that.displayName,_that.ingredientId,_that.isOptional,_that.matchConfidence,_that.matchMethod,_that.name,_that.note,_that.quantity,_that.rawText,_that.section,_that.unitCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ParsedIngredientLine implements ParsedIngredientLine {
  const _ParsedIngredientLine({@JsonKey(name: "autoAccept") required this.autoAccept, @JsonKey(name: "displayName") this.displayName, @JsonKey(name: "ingredientId") this.ingredientId, @JsonKey(name: "isOptional") required this.isOptional, @JsonKey(name: "matchConfidence") this.matchConfidence, @JsonKey(name: "matchMethod") this.matchMethod, @JsonKey(name: "name") this.name, @JsonKey(name: "note") this.note, @JsonKey(name: "quantity") this.quantity, @JsonKey(name: "rawText") required this.rawText, @JsonKey(name: "section") this.section, @JsonKey(name: "unitCode") this.unitCode});
  factory _ParsedIngredientLine.fromJson(Map<String, dynamic> json) => _$ParsedIngredientLineFromJson(json);

@override@JsonKey(name: "autoAccept") final  bool autoAccept;
@override@JsonKey(name: "displayName") final  String? displayName;
@override@JsonKey(name: "ingredientId") final  String? ingredientId;
@override@JsonKey(name: "isOptional") final  bool isOptional;
@override@JsonKey(name: "matchConfidence") final  double? matchConfidence;
@override@JsonKey(name: "matchMethod") final  ParsedMatchMethod? matchMethod;
///The literal remainder after quantity and unit -- inflected as written, because the parser
///does not de-inflect (D6).
@override@JsonKey(name: "name") final  String? name;
@override@JsonKey(name: "note") final  String? note;
@override@JsonKey(name: "quantity") final  ParsedQuantity? quantity;
///The ingredient line exactly as it appears, including quantity and unit. Do not reformat,
///translate, or split it.
@override@JsonKey(name: "rawText") final  String rawText;
///The heading this line sits under, if the list has headings, e.g. 'Za fil' or 'For the
///sauce'. Null when the list is flat.
@override@JsonKey(name: "section") final  String? section;
///A units.code. Null when no unit was recognised.
@override@JsonKey(name: "unitCode") final  String? unitCode;

/// Create a copy of ParsedIngredientLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParsedIngredientLineCopyWith<_ParsedIngredientLine> get copyWith => __$ParsedIngredientLineCopyWithImpl<_ParsedIngredientLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ParsedIngredientLineToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParsedIngredientLine&&(identical(other.autoAccept, autoAccept) || other.autoAccept == autoAccept)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.ingredientId, ingredientId) || other.ingredientId == ingredientId)&&(identical(other.isOptional, isOptional) || other.isOptional == isOptional)&&(identical(other.matchConfidence, matchConfidence) || other.matchConfidence == matchConfidence)&&(identical(other.matchMethod, matchMethod) || other.matchMethod == matchMethod)&&(identical(other.name, name) || other.name == name)&&(identical(other.note, note) || other.note == note)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.rawText, rawText) || other.rawText == rawText)&&(identical(other.section, section) || other.section == section)&&(identical(other.unitCode, unitCode) || other.unitCode == unitCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,autoAccept,displayName,ingredientId,isOptional,matchConfidence,matchMethod,name,note,quantity,rawText,section,unitCode);
}

@override
String toString() {
    return 'ParsedIngredientLine(autoAccept: $autoAccept, displayName: $displayName, ingredientId: $ingredientId, isOptional: $isOptional, matchConfidence: $matchConfidence, matchMethod: $matchMethod, name: $name, note: $note, quantity: $quantity, rawText: $rawText, section: $section, unitCode: $unitCode)';
}


}

/// @nodoc
abstract mixin class _$ParsedIngredientLineCopyWith<$Res> implements $ParsedIngredientLineCopyWith<$Res> {
  factory _$ParsedIngredientLineCopyWith(_ParsedIngredientLine value, $Res Function(_ParsedIngredientLine) _then) = __$ParsedIngredientLineCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "autoAccept") bool autoAccept,@JsonKey(name: "displayName") String? displayName,@JsonKey(name: "ingredientId") String? ingredientId,@JsonKey(name: "isOptional") bool isOptional,@JsonKey(name: "matchConfidence") double? matchConfidence,@JsonKey(name: "matchMethod") ParsedMatchMethod? matchMethod,@JsonKey(name: "name") String? name,@JsonKey(name: "note") String? note,@JsonKey(name: "quantity") ParsedQuantity? quantity,@JsonKey(name: "rawText") String rawText,@JsonKey(name: "section") String? section,@JsonKey(name: "unitCode") String? unitCode
});


@override $ParsedQuantityCopyWith<$Res>? get quantity;

}
/// @nodoc
class __$ParsedIngredientLineCopyWithImpl<$Res>
    implements _$ParsedIngredientLineCopyWith<$Res> {
  __$ParsedIngredientLineCopyWithImpl(this._self, this._then);

  final _ParsedIngredientLine _self;
  final $Res Function(_ParsedIngredientLine) _then;

/// Create a copy of ParsedIngredientLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? autoAccept = null,Object? displayName = freezed,Object? ingredientId = freezed,Object? isOptional = null,Object? matchConfidence = freezed,Object? matchMethod = freezed,Object? name = freezed,Object? note = freezed,Object? quantity = freezed,Object? rawText = null,Object? section = freezed,Object? unitCode = freezed,}) {
  return _then(_ParsedIngredientLine(
autoAccept: null == autoAccept ? _self.autoAccept : autoAccept // ignore: cast_nullable_to_non_nullable
as bool,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,ingredientId: freezed == ingredientId ? _self.ingredientId : ingredientId // ignore: cast_nullable_to_non_nullable
as String?,isOptional: null == isOptional ? _self.isOptional : isOptional // ignore: cast_nullable_to_non_nullable
as bool,matchConfidence: freezed == matchConfidence ? _self.matchConfidence : matchConfidence // ignore: cast_nullable_to_non_nullable
as double?,matchMethod: freezed == matchMethod ? _self.matchMethod : matchMethod // ignore: cast_nullable_to_non_nullable
as ParsedMatchMethod?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as ParsedQuantity?,rawText: null == rawText ? _self.rawText : rawText // ignore: cast_nullable_to_non_nullable
as String,section: freezed == section ? _self.section : section // ignore: cast_nullable_to_non_nullable
as String?,unitCode: freezed == unitCode ? _self.unitCode : unitCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ParsedIngredientLine
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParsedQuantityCopyWith<$Res>? get quantity {
    if (_self.quantity == null) {
    return null;
  }

  return $ParsedQuantityCopyWith<$Res>(_self.quantity!, (value) {
    return _then(_self.copyWith(quantity: value));
  });
}
}


/// @nodoc
mixin _$ParsedQuantity {

@JsonKey(name: "den") int get den;@JsonKey(name: "maxDen") int? get maxDen;@JsonKey(name: "maxNum") int? get maxNum;@JsonKey(name: "num") int get num;
/// Create a copy of ParsedQuantity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParsedQuantityCopyWith<ParsedQuantity> get copyWith => _$ParsedQuantityCopyWithImpl<ParsedQuantity>(this as ParsedQuantity, _$identity);

  /// Serializes this ParsedQuantity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ParsedQuantity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParsedQuantity&&(identical(other.den, _this.den) || other.den == _this.den)&&(identical(other.maxDen, _this.maxDen) || other.maxDen == _this.maxDen)&&(identical(other.maxNum, _this.maxNum) || other.maxNum == _this.maxNum)&&(identical(other.num, _this.num) || other.num == _this.num));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ParsedQuantity;
  return Object.hash(runtimeType,_this.den,_this.maxDen,_this.maxNum,_this.num);
}

@override
String toString() {
  final _this = this as ParsedQuantity;
  return 'ParsedQuantity(den: ${_this.den}, maxDen: ${_this.maxDen}, maxNum: ${_this.maxNum}, num: ${_this.num})';
}


}

/// @nodoc
abstract mixin class $ParsedQuantityCopyWith<$Res>  {
  factory $ParsedQuantityCopyWith(ParsedQuantity value, $Res Function(ParsedQuantity) _then) = _$ParsedQuantityCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "den") int den,@JsonKey(name: "maxDen") int? maxDen,@JsonKey(name: "maxNum") int? maxNum,@JsonKey(name: "num") int num
});




}
/// @nodoc
class _$ParsedQuantityCopyWithImpl<$Res>
    implements $ParsedQuantityCopyWith<$Res> {
  _$ParsedQuantityCopyWithImpl(this._self, this._then);

  final ParsedQuantity _self;
  final $Res Function(ParsedQuantity) _then;

/// Create a copy of ParsedQuantity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? den = null,Object? maxDen = freezed,Object? maxNum = freezed,Object? num = null,}) {
  return _then(ParsedQuantity(
den: null == den ? _self.den : den // ignore: cast_nullable_to_non_nullable
as int,maxDen: freezed == maxDen ? _self.maxDen : maxDen // ignore: cast_nullable_to_non_nullable
as int?,maxNum: freezed == maxNum ? _self.maxNum : maxNum // ignore: cast_nullable_to_non_nullable
as int?,num: null == num ? _self.num : num // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ParsedQuantity].
extension ParsedQuantityPatterns on ParsedQuantity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParsedQuantity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParsedQuantity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParsedQuantity value)  $default,){
final _that = this;
switch (_that) {
case _ParsedQuantity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParsedQuantity value)?  $default,){
final _that = this;
switch (_that) {
case _ParsedQuantity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "den")  int den, @JsonKey(name: "maxDen")  int? maxDen, @JsonKey(name: "maxNum")  int? maxNum, @JsonKey(name: "num")  int num)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParsedQuantity() when $default != null:
return $default(_that.den,_that.maxDen,_that.maxNum,_that.num);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "den")  int den, @JsonKey(name: "maxDen")  int? maxDen, @JsonKey(name: "maxNum")  int? maxNum, @JsonKey(name: "num")  int num)  $default,) {final _that = this;
switch (_that) {
case _ParsedQuantity():
return $default(_that.den,_that.maxDen,_that.maxNum,_that.num);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "den")  int den, @JsonKey(name: "maxDen")  int? maxDen, @JsonKey(name: "maxNum")  int? maxNum, @JsonKey(name: "num")  int num)?  $default,) {final _that = this;
switch (_that) {
case _ParsedQuantity() when $default != null:
return $default(_that.den,_that.maxDen,_that.maxNum,_that.num);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ParsedQuantity implements ParsedQuantity {
  const _ParsedQuantity({@JsonKey(name: "den") required this.den, @JsonKey(name: "maxDen") this.maxDen, @JsonKey(name: "maxNum") this.maxNum, @JsonKey(name: "num") required this.num});
  factory _ParsedQuantity.fromJson(Map<String, dynamic> json) => _$ParsedQuantityFromJson(json);

@override@JsonKey(name: "den") final  int den;
@override@JsonKey(name: "maxDen") final  int? maxDen;
@override@JsonKey(name: "maxNum") final  int? maxNum;
@override@JsonKey(name: "num") final  int num;

/// Create a copy of ParsedQuantity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParsedQuantityCopyWith<_ParsedQuantity> get copyWith => __$ParsedQuantityCopyWithImpl<_ParsedQuantity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ParsedQuantityToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParsedQuantity&&(identical(other.den, den) || other.den == den)&&(identical(other.maxDen, maxDen) || other.maxDen == maxDen)&&(identical(other.maxNum, maxNum) || other.maxNum == maxNum)&&(identical(other.num, num) || other.num == num));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,den,maxDen,maxNum,num);
}

@override
String toString() {
    return 'ParsedQuantity(den: $den, maxDen: $maxDen, maxNum: $maxNum, num: $num)';
}


}

/// @nodoc
abstract mixin class _$ParsedQuantityCopyWith<$Res> implements $ParsedQuantityCopyWith<$Res> {
  factory _$ParsedQuantityCopyWith(_ParsedQuantity value, $Res Function(_ParsedQuantity) _then) = __$ParsedQuantityCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "den") int den,@JsonKey(name: "maxDen") int? maxDen,@JsonKey(name: "maxNum") int? maxNum,@JsonKey(name: "num") int num
});




}
/// @nodoc
class __$ParsedQuantityCopyWithImpl<$Res>
    implements _$ParsedQuantityCopyWith<$Res> {
  __$ParsedQuantityCopyWithImpl(this._self, this._then);

  final _ParsedQuantity _self;
  final $Res Function(_ParsedQuantity) _then;

/// Create a copy of ParsedQuantity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? den = null,Object? maxDen = freezed,Object? maxNum = freezed,Object? num = null,}) {
  return _then(_ParsedQuantity(
den: null == den ? _self.den : den // ignore: cast_nullable_to_non_nullable
as int,maxDen: freezed == maxDen ? _self.maxDen : maxDen // ignore: cast_nullable_to_non_nullable
as int?,maxNum: freezed == maxNum ? _self.maxNum : maxNum // ignore: cast_nullable_to_non_nullable
as int?,num: null == num ? _self.num : num // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ParsedStep {

///One preparation step, in the recipe's original language.
@JsonKey(name: "text") String get text;///Duration in seconds if the step names an explicit time, else null.
@JsonKey(name: "timerSeconds") int? get timerSeconds;
/// Create a copy of ParsedStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParsedStepCopyWith<ParsedStep> get copyWith => _$ParsedStepCopyWithImpl<ParsedStep>(this as ParsedStep, _$identity);

  /// Serializes this ParsedStep to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ParsedStep;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParsedStep&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.timerSeconds, _this.timerSeconds) || other.timerSeconds == _this.timerSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ParsedStep;
  return Object.hash(runtimeType,_this.text,_this.timerSeconds);
}

@override
String toString() {
  final _this = this as ParsedStep;
  return 'ParsedStep(text: ${_this.text}, timerSeconds: ${_this.timerSeconds})';
}


}

/// @nodoc
abstract mixin class $ParsedStepCopyWith<$Res>  {
  factory $ParsedStepCopyWith(ParsedStep value, $Res Function(ParsedStep) _then) = _$ParsedStepCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "text") String text,@JsonKey(name: "timerSeconds") int? timerSeconds
});




}
/// @nodoc
class _$ParsedStepCopyWithImpl<$Res>
    implements $ParsedStepCopyWith<$Res> {
  _$ParsedStepCopyWithImpl(this._self, this._then);

  final ParsedStep _self;
  final $Res Function(ParsedStep) _then;

/// Create a copy of ParsedStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? timerSeconds = freezed,}) {
  return _then(ParsedStep(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,timerSeconds: freezed == timerSeconds ? _self.timerSeconds : timerSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ParsedStep].
extension ParsedStepPatterns on ParsedStep {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParsedStep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParsedStep() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParsedStep value)  $default,){
final _that = this;
switch (_that) {
case _ParsedStep():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParsedStep value)?  $default,){
final _that = this;
switch (_that) {
case _ParsedStep() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "text")  String text, @JsonKey(name: "timerSeconds")  int? timerSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParsedStep() when $default != null:
return $default(_that.text,_that.timerSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "text")  String text, @JsonKey(name: "timerSeconds")  int? timerSeconds)  $default,) {final _that = this;
switch (_that) {
case _ParsedStep():
return $default(_that.text,_that.timerSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "text")  String text, @JsonKey(name: "timerSeconds")  int? timerSeconds)?  $default,) {final _that = this;
switch (_that) {
case _ParsedStep() when $default != null:
return $default(_that.text,_that.timerSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ParsedStep implements ParsedStep {
  const _ParsedStep({@JsonKey(name: "text") required this.text, @JsonKey(name: "timerSeconds") this.timerSeconds});
  factory _ParsedStep.fromJson(Map<String, dynamic> json) => _$ParsedStepFromJson(json);

///One preparation step, in the recipe's original language.
@override@JsonKey(name: "text") final  String text;
///Duration in seconds if the step names an explicit time, else null.
@override@JsonKey(name: "timerSeconds") final  int? timerSeconds;

/// Create a copy of ParsedStep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParsedStepCopyWith<_ParsedStep> get copyWith => __$ParsedStepCopyWithImpl<_ParsedStep>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ParsedStepToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParsedStep&&(identical(other.text, text) || other.text == text)&&(identical(other.timerSeconds, timerSeconds) || other.timerSeconds == timerSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,text,timerSeconds);
}

@override
String toString() {
    return 'ParsedStep(text: $text, timerSeconds: $timerSeconds)';
}


}

/// @nodoc
abstract mixin class _$ParsedStepCopyWith<$Res> implements $ParsedStepCopyWith<$Res> {
  factory _$ParsedStepCopyWith(_ParsedStep value, $Res Function(_ParsedStep) _then) = __$ParsedStepCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "text") String text,@JsonKey(name: "timerSeconds") int? timerSeconds
});




}
/// @nodoc
class __$ParsedStepCopyWithImpl<$Res>
    implements _$ParsedStepCopyWith<$Res> {
  __$ParsedStepCopyWithImpl(this._self, this._then);

  final _ParsedStep _self;
  final $Res Function(_ParsedStep) _then;

/// Create a copy of ParsedStep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? timerSeconds = freezed,}) {
  return _then(_ParsedStep(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,timerSeconds: freezed == timerSeconds ? _self.timerSeconds : timerSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ingredient_match.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IngredientMatch {

 String get ingredientId;/// The ingredient's name in the requested locale -- so searching `flour`
/// with locale `sr` shows *brašno*. That hop is the product's wedge.
 String get displayName;/// The spelling that actually matched, which may be in the other locale.
/// Worth showing when it differs from [displayName], so a user can see
/// *why* a result is in the list.
 String get matchedName; String get matchedLocale; MatchMethod get matchMethod;/// 1.0 for [MatchMethod.exact] and [MatchMethod.alias]; the trigram
/// similarity for [MatchMethod.fuzzy].
 double get confidence;/// Whether this match may be taken without asking a human.
///
/// Computed server-side against the 0.75 line from docs/INGREDIENTS.md, so
/// there is no copy of that constant on this side to drift (D31). Do not
/// reimplement it by comparing [confidence].
 bool get autoAccept;/// False means nobody has vouched for the ingredient yet.
 bool get isVerified;/// The match came from the household's own private alias rather than the
/// global catalog.
 bool get isHouseholdAlias;
/// Create a copy of IngredientMatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IngredientMatchCopyWith<IngredientMatch> get copyWith => _$IngredientMatchCopyWithImpl<IngredientMatch>(this as IngredientMatch, _$identity);

  /// Serializes this IngredientMatch to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as IngredientMatch;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IngredientMatch&&(identical(other.ingredientId, _this.ingredientId) || other.ingredientId == _this.ingredientId)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.matchedName, _this.matchedName) || other.matchedName == _this.matchedName)&&(identical(other.matchedLocale, _this.matchedLocale) || other.matchedLocale == _this.matchedLocale)&&(identical(other.matchMethod, _this.matchMethod) || other.matchMethod == _this.matchMethod)&&(identical(other.confidence, _this.confidence) || other.confidence == _this.confidence)&&(identical(other.autoAccept, _this.autoAccept) || other.autoAccept == _this.autoAccept)&&(identical(other.isVerified, _this.isVerified) || other.isVerified == _this.isVerified)&&(identical(other.isHouseholdAlias, _this.isHouseholdAlias) || other.isHouseholdAlias == _this.isHouseholdAlias));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as IngredientMatch;
  return Object.hash(runtimeType,_this.ingredientId,_this.displayName,_this.matchedName,_this.matchedLocale,_this.matchMethod,_this.confidence,_this.autoAccept,_this.isVerified,_this.isHouseholdAlias);
}

@override
String toString() {
  final _this = this as IngredientMatch;
  return 'IngredientMatch(ingredientId: ${_this.ingredientId}, displayName: ${_this.displayName}, matchedName: ${_this.matchedName}, matchedLocale: ${_this.matchedLocale}, matchMethod: ${_this.matchMethod}, confidence: ${_this.confidence}, autoAccept: ${_this.autoAccept}, isVerified: ${_this.isVerified}, isHouseholdAlias: ${_this.isHouseholdAlias})';
}


}

/// @nodoc
abstract mixin class $IngredientMatchCopyWith<$Res>  {
  factory $IngredientMatchCopyWith(IngredientMatch value, $Res Function(IngredientMatch) _then) = _$IngredientMatchCopyWithImpl;
@useResult
$Res call({
 String ingredientId, String displayName, String matchedName, String matchedLocale, MatchMethod matchMethod, double confidence, bool autoAccept, bool isVerified, bool isHouseholdAlias
});




}
/// @nodoc
class _$IngredientMatchCopyWithImpl<$Res>
    implements $IngredientMatchCopyWith<$Res> {
  _$IngredientMatchCopyWithImpl(this._self, this._then);

  final IngredientMatch _self;
  final $Res Function(IngredientMatch) _then;

/// Create a copy of IngredientMatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ingredientId = null,Object? displayName = null,Object? matchedName = null,Object? matchedLocale = null,Object? matchMethod = null,Object? confidence = null,Object? autoAccept = null,Object? isVerified = null,Object? isHouseholdAlias = null,}) {
  return _then(IngredientMatch(
ingredientId: null == ingredientId ? _self.ingredientId : ingredientId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,matchedName: null == matchedName ? _self.matchedName : matchedName // ignore: cast_nullable_to_non_nullable
as String,matchedLocale: null == matchedLocale ? _self.matchedLocale : matchedLocale // ignore: cast_nullable_to_non_nullable
as String,matchMethod: null == matchMethod ? _self.matchMethod : matchMethod // ignore: cast_nullable_to_non_nullable
as MatchMethod,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,autoAccept: null == autoAccept ? _self.autoAccept : autoAccept // ignore: cast_nullable_to_non_nullable
as bool,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,isHouseholdAlias: null == isHouseholdAlias ? _self.isHouseholdAlias : isHouseholdAlias // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [IngredientMatch].
extension IngredientMatchPatterns on IngredientMatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IngredientMatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IngredientMatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IngredientMatch value)  $default,){
final _that = this;
switch (_that) {
case _IngredientMatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IngredientMatch value)?  $default,){
final _that = this;
switch (_that) {
case _IngredientMatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String ingredientId,  String displayName,  String matchedName,  String matchedLocale,  MatchMethod matchMethod,  double confidence,  bool autoAccept,  bool isVerified,  bool isHouseholdAlias)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IngredientMatch() when $default != null:
return $default(_that.ingredientId,_that.displayName,_that.matchedName,_that.matchedLocale,_that.matchMethod,_that.confidence,_that.autoAccept,_that.isVerified,_that.isHouseholdAlias);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String ingredientId,  String displayName,  String matchedName,  String matchedLocale,  MatchMethod matchMethod,  double confidence,  bool autoAccept,  bool isVerified,  bool isHouseholdAlias)  $default,) {final _that = this;
switch (_that) {
case _IngredientMatch():
return $default(_that.ingredientId,_that.displayName,_that.matchedName,_that.matchedLocale,_that.matchMethod,_that.confidence,_that.autoAccept,_that.isVerified,_that.isHouseholdAlias);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String ingredientId,  String displayName,  String matchedName,  String matchedLocale,  MatchMethod matchMethod,  double confidence,  bool autoAccept,  bool isVerified,  bool isHouseholdAlias)?  $default,) {final _that = this;
switch (_that) {
case _IngredientMatch() when $default != null:
return $default(_that.ingredientId,_that.displayName,_that.matchedName,_that.matchedLocale,_that.matchMethod,_that.confidence,_that.autoAccept,_that.isVerified,_that.isHouseholdAlias);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IngredientMatch implements IngredientMatch {
  const _IngredientMatch({required this.ingredientId, required this.displayName, required this.matchedName, required this.matchedLocale, required this.matchMethod, required this.confidence, required this.autoAccept, this.isVerified = false, this.isHouseholdAlias = false});
  factory _IngredientMatch.fromJson(Map<String, dynamic> json) => _$IngredientMatchFromJson(json);

@override final  String ingredientId;
/// The ingredient's name in the requested locale -- so searching `flour`
/// with locale `sr` shows *brašno*. That hop is the product's wedge.
@override final  String displayName;
/// The spelling that actually matched, which may be in the other locale.
/// Worth showing when it differs from [displayName], so a user can see
/// *why* a result is in the list.
@override final  String matchedName;
@override final  String matchedLocale;
@override final  MatchMethod matchMethod;
/// 1.0 for [MatchMethod.exact] and [MatchMethod.alias]; the trigram
/// similarity for [MatchMethod.fuzzy].
@override final  double confidence;
/// Whether this match may be taken without asking a human.
///
/// Computed server-side against the 0.75 line from docs/INGREDIENTS.md, so
/// there is no copy of that constant on this side to drift (D31). Do not
/// reimplement it by comparing [confidence].
@override final  bool autoAccept;
/// False means nobody has vouched for the ingredient yet.
@override@JsonKey() final  bool isVerified;
/// The match came from the household's own private alias rather than the
/// global catalog.
@override@JsonKey() final  bool isHouseholdAlias;

/// Create a copy of IngredientMatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IngredientMatchCopyWith<_IngredientMatch> get copyWith => __$IngredientMatchCopyWithImpl<_IngredientMatch>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IngredientMatchToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _IngredientMatch&&(identical(other.ingredientId, ingredientId) || other.ingredientId == ingredientId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.matchedName, matchedName) || other.matchedName == matchedName)&&(identical(other.matchedLocale, matchedLocale) || other.matchedLocale == matchedLocale)&&(identical(other.matchMethod, matchMethod) || other.matchMethod == matchMethod)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.autoAccept, autoAccept) || other.autoAccept == autoAccept)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.isHouseholdAlias, isHouseholdAlias) || other.isHouseholdAlias == isHouseholdAlias));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,ingredientId,displayName,matchedName,matchedLocale,matchMethod,confidence,autoAccept,isVerified,isHouseholdAlias);
}

@override
String toString() {
    return 'IngredientMatch(ingredientId: $ingredientId, displayName: $displayName, matchedName: $matchedName, matchedLocale: $matchedLocale, matchMethod: $matchMethod, confidence: $confidence, autoAccept: $autoAccept, isVerified: $isVerified, isHouseholdAlias: $isHouseholdAlias)';
}


}

/// @nodoc
abstract mixin class _$IngredientMatchCopyWith<$Res> implements $IngredientMatchCopyWith<$Res> {
  factory _$IngredientMatchCopyWith(_IngredientMatch value, $Res Function(_IngredientMatch) _then) = __$IngredientMatchCopyWithImpl;
@override @useResult
$Res call({
 String ingredientId, String displayName, String matchedName, String matchedLocale, MatchMethod matchMethod, double confidence, bool autoAccept, bool isVerified, bool isHouseholdAlias
});




}
/// @nodoc
class __$IngredientMatchCopyWithImpl<$Res>
    implements _$IngredientMatchCopyWith<$Res> {
  __$IngredientMatchCopyWithImpl(this._self, this._then);

  final _IngredientMatch _self;
  final $Res Function(_IngredientMatch) _then;

/// Create a copy of IngredientMatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ingredientId = null,Object? displayName = null,Object? matchedName = null,Object? matchedLocale = null,Object? matchMethod = null,Object? confidence = null,Object? autoAccept = null,Object? isVerified = null,Object? isHouseholdAlias = null,}) {
  return _then(_IngredientMatch(
ingredientId: null == ingredientId ? _self.ingredientId : ingredientId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,matchedName: null == matchedName ? _self.matchedName : matchedName // ignore: cast_nullable_to_non_nullable
as String,matchedLocale: null == matchedLocale ? _self.matchedLocale : matchedLocale // ignore: cast_nullable_to_non_nullable
as String,matchMethod: null == matchMethod ? _self.matchMethod : matchMethod // ignore: cast_nullable_to_non_nullable
as MatchMethod,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,autoAccept: null == autoAccept ? _self.autoAccept : autoAccept // ignore: cast_nullable_to_non_nullable
as bool,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,isHouseholdAlias: null == isHouseholdAlias ? _self.isHouseholdAlias : isHouseholdAlias // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ingredient.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Ingredient {

 String get id;/// The curated seed key (`brasno_glatko`), or null for the auto-created
/// tail (D27). Not a user-facing slug -- only the seed migration writes it.
 String? get key;/// One level only (D3). Shopping lists do not roll up to the parent.
 String? get parentId; String? get category;/// What it is usually measured in, for the shopping list's display choice.
/// Never a constraint on what a recipe may write.
 UnitFamily? get defaultUnitFamily;/// False means nobody has vouched for this row -- it was created by the
/// matcher rather than seeded. Merge candidates live here (D2).
 bool get isVerified;/// Suppressed from the shopping list unless a household overrides it.
 bool get isPantryStaple;
/// Create a copy of Ingredient
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IngredientCopyWith<Ingredient> get copyWith => _$IngredientCopyWithImpl<Ingredient>(this as Ingredient, _$identity);

  /// Serializes this Ingredient to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Ingredient;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Ingredient&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.parentId, _this.parentId) || other.parentId == _this.parentId)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.defaultUnitFamily, _this.defaultUnitFamily) || other.defaultUnitFamily == _this.defaultUnitFamily)&&(identical(other.isVerified, _this.isVerified) || other.isVerified == _this.isVerified)&&(identical(other.isPantryStaple, _this.isPantryStaple) || other.isPantryStaple == _this.isPantryStaple));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Ingredient;
  return Object.hash(runtimeType,_this.id,_this.key,_this.parentId,_this.category,_this.defaultUnitFamily,_this.isVerified,_this.isPantryStaple);
}

@override
String toString() {
  final _this = this as Ingredient;
  return 'Ingredient(id: ${_this.id}, key: ${_this.key}, parentId: ${_this.parentId}, category: ${_this.category}, defaultUnitFamily: ${_this.defaultUnitFamily}, isVerified: ${_this.isVerified}, isPantryStaple: ${_this.isPantryStaple})';
}


}

/// @nodoc
abstract mixin class $IngredientCopyWith<$Res>  {
  factory $IngredientCopyWith(Ingredient value, $Res Function(Ingredient) _then) = _$IngredientCopyWithImpl;
@useResult
$Res call({
 String id, String? key, String? parentId, String? category, UnitFamily? defaultUnitFamily, bool isVerified, bool isPantryStaple
});




}
/// @nodoc
class _$IngredientCopyWithImpl<$Res>
    implements $IngredientCopyWith<$Res> {
  _$IngredientCopyWithImpl(this._self, this._then);

  final Ingredient _self;
  final $Res Function(Ingredient) _then;

/// Create a copy of Ingredient
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? key = freezed,Object? parentId = freezed,Object? category = freezed,Object? defaultUnitFamily = freezed,Object? isVerified = null,Object? isPantryStaple = null,}) {
  return _then(Ingredient(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,key: freezed == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String?,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,defaultUnitFamily: freezed == defaultUnitFamily ? _self.defaultUnitFamily : defaultUnitFamily // ignore: cast_nullable_to_non_nullable
as UnitFamily?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,isPantryStaple: null == isPantryStaple ? _self.isPantryStaple : isPantryStaple // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Ingredient].
extension IngredientPatterns on Ingredient {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Ingredient value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Ingredient() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Ingredient value)  $default,){
final _that = this;
switch (_that) {
case _Ingredient():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Ingredient value)?  $default,){
final _that = this;
switch (_that) {
case _Ingredient() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? key,  String? parentId,  String? category,  UnitFamily? defaultUnitFamily,  bool isVerified,  bool isPantryStaple)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Ingredient() when $default != null:
return $default(_that.id,_that.key,_that.parentId,_that.category,_that.defaultUnitFamily,_that.isVerified,_that.isPantryStaple);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? key,  String? parentId,  String? category,  UnitFamily? defaultUnitFamily,  bool isVerified,  bool isPantryStaple)  $default,) {final _that = this;
switch (_that) {
case _Ingredient():
return $default(_that.id,_that.key,_that.parentId,_that.category,_that.defaultUnitFamily,_that.isVerified,_that.isPantryStaple);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? key,  String? parentId,  String? category,  UnitFamily? defaultUnitFamily,  bool isVerified,  bool isPantryStaple)?  $default,) {final _that = this;
switch (_that) {
case _Ingredient() when $default != null:
return $default(_that.id,_that.key,_that.parentId,_that.category,_that.defaultUnitFamily,_that.isVerified,_that.isPantryStaple);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Ingredient implements Ingredient {
  const _Ingredient({required this.id, this.key, this.parentId, this.category, this.defaultUnitFamily, this.isVerified = false, this.isPantryStaple = false});
  factory _Ingredient.fromJson(Map<String, dynamic> json) => _$IngredientFromJson(json);

@override final  String id;
/// The curated seed key (`brasno_glatko`), or null for the auto-created
/// tail (D27). Not a user-facing slug -- only the seed migration writes it.
@override final  String? key;
/// One level only (D3). Shopping lists do not roll up to the parent.
@override final  String? parentId;
@override final  String? category;
/// What it is usually measured in, for the shopping list's display choice.
/// Never a constraint on what a recipe may write.
@override final  UnitFamily? defaultUnitFamily;
/// False means nobody has vouched for this row -- it was created by the
/// matcher rather than seeded. Merge candidates live here (D2).
@override@JsonKey() final  bool isVerified;
/// Suppressed from the shopping list unless a household overrides it.
@override@JsonKey() final  bool isPantryStaple;

/// Create a copy of Ingredient
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IngredientCopyWith<_Ingredient> get copyWith => __$IngredientCopyWithImpl<_Ingredient>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IngredientToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Ingredient&&(identical(other.id, id) || other.id == id)&&(identical(other.key, key) || other.key == key)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.category, category) || other.category == category)&&(identical(other.defaultUnitFamily, defaultUnitFamily) || other.defaultUnitFamily == defaultUnitFamily)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.isPantryStaple, isPantryStaple) || other.isPantryStaple == isPantryStaple));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,key,parentId,category,defaultUnitFamily,isVerified,isPantryStaple);
}

@override
String toString() {
    return 'Ingredient(id: $id, key: $key, parentId: $parentId, category: $category, defaultUnitFamily: $defaultUnitFamily, isVerified: $isVerified, isPantryStaple: $isPantryStaple)';
}


}

/// @nodoc
abstract mixin class _$IngredientCopyWith<$Res> implements $IngredientCopyWith<$Res> {
  factory _$IngredientCopyWith(_Ingredient value, $Res Function(_Ingredient) _then) = __$IngredientCopyWithImpl;
@override @useResult
$Res call({
 String id, String? key, String? parentId, String? category, UnitFamily? defaultUnitFamily, bool isVerified, bool isPantryStaple
});




}
/// @nodoc
class __$IngredientCopyWithImpl<$Res>
    implements _$IngredientCopyWith<$Res> {
  __$IngredientCopyWithImpl(this._self, this._then);

  final _Ingredient _self;
  final $Res Function(_Ingredient) _then;

/// Create a copy of Ingredient
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? key = freezed,Object? parentId = freezed,Object? category = freezed,Object? defaultUnitFamily = freezed,Object? isVerified = null,Object? isPantryStaple = null,}) {
  return _then(_Ingredient(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,key: freezed == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String?,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,defaultUnitFamily: freezed == defaultUnitFamily ? _self.defaultUnitFamily : defaultUnitFamily // ignore: cast_nullable_to_non_nullable
as UnitFamily?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,isPantryStaple: null == isPantryStaple ? _self.isPantryStaple : isPantryStaple // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

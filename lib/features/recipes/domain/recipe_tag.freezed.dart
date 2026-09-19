// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe_tag.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RecipeTag {

 String get key; String get label;
/// Create a copy of RecipeTag
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeTagCopyWith<RecipeTag> get copyWith => _$RecipeTagCopyWithImpl<RecipeTag>(this as RecipeTag, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RecipeTag;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipeTag&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.label, _this.label) || other.label == _this.label));
}


@override
int get hashCode {
  final _this = this as RecipeTag;
  return Object.hash(runtimeType,_this.key,_this.label);
}

@override
String toString() {
  final _this = this as RecipeTag;
  return 'RecipeTag(key: ${_this.key}, label: ${_this.label})';
}


}

/// @nodoc
abstract mixin class $RecipeTagCopyWith<$Res>  {
  factory $RecipeTagCopyWith(RecipeTag value, $Res Function(RecipeTag) _then) = _$RecipeTagCopyWithImpl;
@useResult
$Res call({
 String key, String label
});




}
/// @nodoc
class _$RecipeTagCopyWithImpl<$Res>
    implements $RecipeTagCopyWith<$Res> {
  _$RecipeTagCopyWithImpl(this._self, this._then);

  final RecipeTag _self;
  final $Res Function(RecipeTag) _then;

/// Create a copy of RecipeTag
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? label = null,}) {
  return _then(RecipeTag(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RecipeTag].
extension RecipeTagPatterns on RecipeTag {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecipeTag value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecipeTag() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecipeTag value)  $default,){
final _that = this;
switch (_that) {
case _RecipeTag():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecipeTag value)?  $default,){
final _that = this;
switch (_that) {
case _RecipeTag() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecipeTag() when $default != null:
return $default(_that.key,_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String label)  $default,) {final _that = this;
switch (_that) {
case _RecipeTag():
return $default(_that.key,_that.label);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String label)?  $default,) {final _that = this;
switch (_that) {
case _RecipeTag() when $default != null:
return $default(_that.key,_that.label);case _:
  return null;

}
}

}

/// @nodoc


class _RecipeTag extends RecipeTag {
  const _RecipeTag({required this.key, required this.label}): super._();
  

@override final  String key;
@override final  String label;

/// Create a copy of RecipeTag
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeTagCopyWith<_RecipeTag> get copyWith => __$RecipeTagCopyWithImpl<_RecipeTag>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipeTag&&(identical(other.key, key) || other.key == key)&&(identical(other.label, label) || other.label == label));
}


@override
int get hashCode {
    return Object.hash(runtimeType,key,label);
}

@override
String toString() {
    return 'RecipeTag(key: $key, label: $label)';
}


}

/// @nodoc
abstract mixin class _$RecipeTagCopyWith<$Res> implements $RecipeTagCopyWith<$Res> {
  factory _$RecipeTagCopyWith(_RecipeTag value, $Res Function(_RecipeTag) _then) = __$RecipeTagCopyWithImpl;
@override @useResult
$Res call({
 String key, String label
});




}
/// @nodoc
class __$RecipeTagCopyWithImpl<$Res>
    implements _$RecipeTagCopyWith<$Res> {
  __$RecipeTagCopyWithImpl(this._self, this._then);

  final _RecipeTag _self;
  final $Res Function(_RecipeTag) _then;

/// Create a copy of RecipeTag
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? label = null,}) {
  return _then(_RecipeTag(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

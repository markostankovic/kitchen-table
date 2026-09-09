// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe_image_upload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RecipeImageUpload {

 Uint8List get bytes; String get contentType; String get extension;
/// Create a copy of RecipeImageUpload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeImageUploadCopyWith<RecipeImageUpload> get copyWith => _$RecipeImageUploadCopyWithImpl<RecipeImageUpload>(this as RecipeImageUpload, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RecipeImageUpload;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipeImageUpload&&const DeepCollectionEquality().equals(other.bytes, _this.bytes)&&(identical(other.contentType, _this.contentType) || other.contentType == _this.contentType)&&(identical(other.extension, _this.extension) || other.extension == _this.extension));
}


@override
int get hashCode {
  final _this = this as RecipeImageUpload;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.bytes),_this.contentType,_this.extension);
}

@override
String toString() {
  final _this = this as RecipeImageUpload;
  return 'RecipeImageUpload(bytes: ${_this.bytes}, contentType: ${_this.contentType}, extension: ${_this.extension})';
}


}

/// @nodoc
abstract mixin class $RecipeImageUploadCopyWith<$Res>  {
  factory $RecipeImageUploadCopyWith(RecipeImageUpload value, $Res Function(RecipeImageUpload) _then) = _$RecipeImageUploadCopyWithImpl;
@useResult
$Res call({
 Uint8List bytes, String contentType, String extension
});




}
/// @nodoc
class _$RecipeImageUploadCopyWithImpl<$Res>
    implements $RecipeImageUploadCopyWith<$Res> {
  _$RecipeImageUploadCopyWithImpl(this._self, this._then);

  final RecipeImageUpload _self;
  final $Res Function(RecipeImageUpload) _then;

/// Create a copy of RecipeImageUpload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bytes = null,Object? contentType = null,Object? extension = null,}) {
  return _then(RecipeImageUpload(
bytes: null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as Uint8List,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,extension: null == extension ? _self.extension : extension // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RecipeImageUpload].
extension RecipeImageUploadPatterns on RecipeImageUpload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecipeImageUpload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecipeImageUpload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecipeImageUpload value)  $default,){
final _that = this;
switch (_that) {
case _RecipeImageUpload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecipeImageUpload value)?  $default,){
final _that = this;
switch (_that) {
case _RecipeImageUpload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Uint8List bytes,  String contentType,  String extension)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecipeImageUpload() when $default != null:
return $default(_that.bytes,_that.contentType,_that.extension);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Uint8List bytes,  String contentType,  String extension)  $default,) {final _that = this;
switch (_that) {
case _RecipeImageUpload():
return $default(_that.bytes,_that.contentType,_that.extension);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Uint8List bytes,  String contentType,  String extension)?  $default,) {final _that = this;
switch (_that) {
case _RecipeImageUpload() when $default != null:
return $default(_that.bytes,_that.contentType,_that.extension);case _:
  return null;

}
}

}

/// @nodoc


class _RecipeImageUpload implements RecipeImageUpload {
  const _RecipeImageUpload({required this.bytes, required this.contentType, required this.extension});
  

@override final  Uint8List bytes;
@override final  String contentType;
@override final  String extension;

/// Create a copy of RecipeImageUpload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeImageUploadCopyWith<_RecipeImageUpload> get copyWith => __$RecipeImageUploadCopyWithImpl<_RecipeImageUpload>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipeImageUpload&&const DeepCollectionEquality().equals(other.bytes, bytes)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.extension, extension) || other.extension == extension));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(bytes),contentType,extension);
}

@override
String toString() {
    return 'RecipeImageUpload(bytes: $bytes, contentType: $contentType, extension: $extension)';
}


}

/// @nodoc
abstract mixin class _$RecipeImageUploadCopyWith<$Res> implements $RecipeImageUploadCopyWith<$Res> {
  factory _$RecipeImageUploadCopyWith(_RecipeImageUpload value, $Res Function(_RecipeImageUpload) _then) = __$RecipeImageUploadCopyWithImpl;
@override @useResult
$Res call({
 Uint8List bytes, String contentType, String extension
});




}
/// @nodoc
class __$RecipeImageUploadCopyWithImpl<$Res>
    implements _$RecipeImageUploadCopyWith<$Res> {
  __$RecipeImageUploadCopyWithImpl(this._self, this._then);

  final _RecipeImageUpload _self;
  final $Res Function(_RecipeImageUpload) _then;

/// Create a copy of RecipeImageUpload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bytes = null,Object? contentType = null,Object? extension = null,}) {
  return _then(_RecipeImageUpload(
bytes: null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as Uint8List,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,extension: null == extension ? _self.extension : extension // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

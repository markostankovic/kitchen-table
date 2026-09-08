// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'import_job.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ImportJob {

 String get id; ImportKind get kind; ImportJobStatus get status; ParsedRecipe? get result; String? get errorCode; String? get errorMessage; String? get recipeId;
/// Create a copy of ImportJob
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImportJobCopyWith<ImportJob> get copyWith => _$ImportJobCopyWithImpl<ImportJob>(this as ImportJob, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ImportJob;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImportJob&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.result, _this.result) || other.result == _this.result)&&(identical(other.errorCode, _this.errorCode) || other.errorCode == _this.errorCode)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage)&&(identical(other.recipeId, _this.recipeId) || other.recipeId == _this.recipeId));
}


@override
int get hashCode {
  final _this = this as ImportJob;
  return Object.hash(runtimeType,_this.id,_this.kind,_this.status,_this.result,_this.errorCode,_this.errorMessage,_this.recipeId);
}

@override
String toString() {
  final _this = this as ImportJob;
  return 'ImportJob(id: ${_this.id}, kind: ${_this.kind}, status: ${_this.status}, result: ${_this.result}, errorCode: ${_this.errorCode}, errorMessage: ${_this.errorMessage}, recipeId: ${_this.recipeId})';
}


}

/// @nodoc
abstract mixin class $ImportJobCopyWith<$Res>  {
  factory $ImportJobCopyWith(ImportJob value, $Res Function(ImportJob) _then) = _$ImportJobCopyWithImpl;
@useResult
$Res call({
 String id, ImportKind kind, ImportJobStatus status, ParsedRecipe? result, String? errorCode, String? errorMessage, String? recipeId
});


$ParsedRecipeCopyWith<$Res>? get result;

}
/// @nodoc
class _$ImportJobCopyWithImpl<$Res>
    implements $ImportJobCopyWith<$Res> {
  _$ImportJobCopyWithImpl(this._self, this._then);

  final ImportJob _self;
  final $Res Function(ImportJob) _then;

/// Create a copy of ImportJob
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? status = null,Object? result = freezed,Object? errorCode = freezed,Object? errorMessage = freezed,Object? recipeId = freezed,}) {
  return _then(ImportJob(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ImportKind,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ImportJobStatus,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as ParsedRecipe?,errorCode: freezed == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,recipeId: freezed == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ImportJob
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParsedRecipeCopyWith<$Res>? get result {
    if (_self.result == null) {
    return null;
  }

  return $ParsedRecipeCopyWith<$Res>(_self.result!, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}


/// Adds pattern-matching-related methods to [ImportJob].
extension ImportJobPatterns on ImportJob {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImportJob value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImportJob() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImportJob value)  $default,){
final _that = this;
switch (_that) {
case _ImportJob():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImportJob value)?  $default,){
final _that = this;
switch (_that) {
case _ImportJob() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  ImportKind kind,  ImportJobStatus status,  ParsedRecipe? result,  String? errorCode,  String? errorMessage,  String? recipeId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ImportJob() when $default != null:
return $default(_that.id,_that.kind,_that.status,_that.result,_that.errorCode,_that.errorMessage,_that.recipeId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  ImportKind kind,  ImportJobStatus status,  ParsedRecipe? result,  String? errorCode,  String? errorMessage,  String? recipeId)  $default,) {final _that = this;
switch (_that) {
case _ImportJob():
return $default(_that.id,_that.kind,_that.status,_that.result,_that.errorCode,_that.errorMessage,_that.recipeId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  ImportKind kind,  ImportJobStatus status,  ParsedRecipe? result,  String? errorCode,  String? errorMessage,  String? recipeId)?  $default,) {final _that = this;
switch (_that) {
case _ImportJob() when $default != null:
return $default(_that.id,_that.kind,_that.status,_that.result,_that.errorCode,_that.errorMessage,_that.recipeId);case _:
  return null;

}
}

}

/// @nodoc


class _ImportJob extends ImportJob {
  const _ImportJob({required this.id, required this.kind, required this.status, this.result, this.errorCode, this.errorMessage, this.recipeId}): super._();
  

@override final  String id;
@override final  ImportKind kind;
@override final  ImportJobStatus status;
@override final  ParsedRecipe? result;
@override final  String? errorCode;
@override final  String? errorMessage;
@override final  String? recipeId;

/// Create a copy of ImportJob
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImportJobCopyWith<_ImportJob> get copyWith => __$ImportJobCopyWithImpl<_ImportJob>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImportJob&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.status, status) || other.status == status)&&(identical(other.result, result) || other.result == result)&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,kind,status,result,errorCode,errorMessage,recipeId);
}

@override
String toString() {
    return 'ImportJob(id: $id, kind: $kind, status: $status, result: $result, errorCode: $errorCode, errorMessage: $errorMessage, recipeId: $recipeId)';
}


}

/// @nodoc
abstract mixin class _$ImportJobCopyWith<$Res> implements $ImportJobCopyWith<$Res> {
  factory _$ImportJobCopyWith(_ImportJob value, $Res Function(_ImportJob) _then) = __$ImportJobCopyWithImpl;
@override @useResult
$Res call({
 String id, ImportKind kind, ImportJobStatus status, ParsedRecipe? result, String? errorCode, String? errorMessage, String? recipeId
});


@override $ParsedRecipeCopyWith<$Res>? get result;

}
/// @nodoc
class __$ImportJobCopyWithImpl<$Res>
    implements _$ImportJobCopyWith<$Res> {
  __$ImportJobCopyWithImpl(this._self, this._then);

  final _ImportJob _self;
  final $Res Function(_ImportJob) _then;

/// Create a copy of ImportJob
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? status = null,Object? result = freezed,Object? errorCode = freezed,Object? errorMessage = freezed,Object? recipeId = freezed,}) {
  return _then(_ImportJob(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ImportKind,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ImportJobStatus,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as ParsedRecipe?,errorCode: freezed == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,recipeId: freezed == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ImportJob
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParsedRecipeCopyWith<$Res>? get result {
    if (_self.result == null) {
    return null;
  }

  return $ParsedRecipeCopyWith<$Res>(_self.result!, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

// dart format on

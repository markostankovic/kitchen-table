// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe_translation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecipeTranslation {

 String get locale; String get title; String? get description; List<RecipeStep> get steps; bool get isMachineGenerated; String? get reviewedBy; DateTime? get reviewedAt;
/// Create a copy of RecipeTranslation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeTranslationCopyWith<RecipeTranslation> get copyWith => _$RecipeTranslationCopyWithImpl<RecipeTranslation>(this as RecipeTranslation, _$identity);

  /// Serializes this RecipeTranslation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RecipeTranslation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipeTranslation&&(identical(other.locale, _this.locale) || other.locale == _this.locale)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&const DeepCollectionEquality().equals(other.steps, _this.steps)&&(identical(other.isMachineGenerated, _this.isMachineGenerated) || other.isMachineGenerated == _this.isMachineGenerated)&&(identical(other.reviewedBy, _this.reviewedBy) || other.reviewedBy == _this.reviewedBy)&&(identical(other.reviewedAt, _this.reviewedAt) || other.reviewedAt == _this.reviewedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RecipeTranslation;
  return Object.hash(runtimeType,_this.locale,_this.title,_this.description,const DeepCollectionEquality().hash(_this.steps),_this.isMachineGenerated,_this.reviewedBy,_this.reviewedAt);
}

@override
String toString() {
  final _this = this as RecipeTranslation;
  return 'RecipeTranslation(locale: ${_this.locale}, title: ${_this.title}, description: ${_this.description}, steps: ${_this.steps}, isMachineGenerated: ${_this.isMachineGenerated}, reviewedBy: ${_this.reviewedBy}, reviewedAt: ${_this.reviewedAt})';
}


}

/// @nodoc
abstract mixin class $RecipeTranslationCopyWith<$Res>  {
  factory $RecipeTranslationCopyWith(RecipeTranslation value, $Res Function(RecipeTranslation) _then) = _$RecipeTranslationCopyWithImpl;
@useResult
$Res call({
 String locale, String title, String? description, List<RecipeStep> steps, bool isMachineGenerated, String? reviewedBy, DateTime? reviewedAt
});




}
/// @nodoc
class _$RecipeTranslationCopyWithImpl<$Res>
    implements $RecipeTranslationCopyWith<$Res> {
  _$RecipeTranslationCopyWithImpl(this._self, this._then);

  final RecipeTranslation _self;
  final $Res Function(RecipeTranslation) _then;

/// Create a copy of RecipeTranslation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? locale = null,Object? title = null,Object? description = freezed,Object? steps = null,Object? isMachineGenerated = null,Object? reviewedBy = freezed,Object? reviewedAt = freezed,}) {
  return _then(RecipeTranslation(
locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<RecipeStep>,isMachineGenerated: null == isMachineGenerated ? _self.isMachineGenerated : isMachineGenerated // ignore: cast_nullable_to_non_nullable
as bool,reviewedBy: freezed == reviewedBy ? _self.reviewedBy : reviewedBy // ignore: cast_nullable_to_non_nullable
as String?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [RecipeTranslation].
extension RecipeTranslationPatterns on RecipeTranslation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecipeTranslation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecipeTranslation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecipeTranslation value)  $default,){
final _that = this;
switch (_that) {
case _RecipeTranslation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecipeTranslation value)?  $default,){
final _that = this;
switch (_that) {
case _RecipeTranslation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String locale,  String title,  String? description,  List<RecipeStep> steps,  bool isMachineGenerated,  String? reviewedBy,  DateTime? reviewedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecipeTranslation() when $default != null:
return $default(_that.locale,_that.title,_that.description,_that.steps,_that.isMachineGenerated,_that.reviewedBy,_that.reviewedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String locale,  String title,  String? description,  List<RecipeStep> steps,  bool isMachineGenerated,  String? reviewedBy,  DateTime? reviewedAt)  $default,) {final _that = this;
switch (_that) {
case _RecipeTranslation():
return $default(_that.locale,_that.title,_that.description,_that.steps,_that.isMachineGenerated,_that.reviewedBy,_that.reviewedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String locale,  String title,  String? description,  List<RecipeStep> steps,  bool isMachineGenerated,  String? reviewedBy,  DateTime? reviewedAt)?  $default,) {final _that = this;
switch (_that) {
case _RecipeTranslation() when $default != null:
return $default(_that.locale,_that.title,_that.description,_that.steps,_that.isMachineGenerated,_that.reviewedBy,_that.reviewedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecipeTranslation implements RecipeTranslation {
  const _RecipeTranslation({required this.locale, required this.title, this.description,  List<RecipeStep> steps = const <RecipeStep>[], this.isMachineGenerated = true, this.reviewedBy, this.reviewedAt}): _steps = steps;
  factory _RecipeTranslation.fromJson(Map<String, dynamic> json) => _$RecipeTranslationFromJson(json);

@override final  String locale;
@override final  String title;
@override final  String? description;
 final  List<RecipeStep> _steps;
@override@JsonKey() List<RecipeStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}

@override@JsonKey() final  bool isMachineGenerated;
@override final  String? reviewedBy;
@override final  DateTime? reviewedAt;

/// Create a copy of RecipeTranslation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeTranslationCopyWith<_RecipeTranslation> get copyWith => __$RecipeTranslationCopyWithImpl<_RecipeTranslation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecipeTranslationToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipeTranslation&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.steps, _steps)&&(identical(other.isMachineGenerated, isMachineGenerated) || other.isMachineGenerated == isMachineGenerated)&&(identical(other.reviewedBy, reviewedBy) || other.reviewedBy == reviewedBy)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,locale,title,description,const DeepCollectionEquality().hash(_steps),isMachineGenerated,reviewedBy,reviewedAt);
}

@override
String toString() {
    return 'RecipeTranslation(locale: $locale, title: $title, description: $description, steps: $steps, isMachineGenerated: $isMachineGenerated, reviewedBy: $reviewedBy, reviewedAt: $reviewedAt)';
}


}

/// @nodoc
abstract mixin class _$RecipeTranslationCopyWith<$Res> implements $RecipeTranslationCopyWith<$Res> {
  factory _$RecipeTranslationCopyWith(_RecipeTranslation value, $Res Function(_RecipeTranslation) _then) = __$RecipeTranslationCopyWithImpl;
@override @useResult
$Res call({
 String locale, String title, String? description, List<RecipeStep> steps, bool isMachineGenerated, String? reviewedBy, DateTime? reviewedAt
});




}
/// @nodoc
class __$RecipeTranslationCopyWithImpl<$Res>
    implements _$RecipeTranslationCopyWith<$Res> {
  __$RecipeTranslationCopyWithImpl(this._self, this._then);

  final _RecipeTranslation _self;
  final $Res Function(_RecipeTranslation) _then;

/// Create a copy of RecipeTranslation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? locale = null,Object? title = null,Object? description = freezed,Object? steps = null,Object? isMachineGenerated = null,Object? reviewedBy = freezed,Object? reviewedAt = freezed,}) {
  return _then(_RecipeTranslation(
locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<RecipeStep>,isMachineGenerated: null == isMachineGenerated ? _self.isMachineGenerated : isMachineGenerated // ignore: cast_nullable_to_non_nullable
as bool,reviewedBy: freezed == reviewedBy ? _self.reviewedBy : reviewedBy // ignore: cast_nullable_to_non_nullable
as String?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

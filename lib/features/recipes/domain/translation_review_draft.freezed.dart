// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'translation_review_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TranslationReviewDraft {

 String get locale;/// The recipe's own language -- distinct from [locale], which is the
/// language being reviewed. Used only to label the source side of the
/// screen ("Original (Serbian)").
 String get sourceLocale; String get sourceTitle; String? get sourceDescription; List<RecipeStep> get sourceSteps; String get title; String? get description; List<RecipeStep> get steps;
/// Create a copy of TranslationReviewDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TranslationReviewDraftCopyWith<TranslationReviewDraft> get copyWith => _$TranslationReviewDraftCopyWithImpl<TranslationReviewDraft>(this as TranslationReviewDraft, _$identity);

  /// Serializes this TranslationReviewDraft to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TranslationReviewDraft;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TranslationReviewDraft&&(identical(other.locale, _this.locale) || other.locale == _this.locale)&&(identical(other.sourceLocale, _this.sourceLocale) || other.sourceLocale == _this.sourceLocale)&&(identical(other.sourceTitle, _this.sourceTitle) || other.sourceTitle == _this.sourceTitle)&&(identical(other.sourceDescription, _this.sourceDescription) || other.sourceDescription == _this.sourceDescription)&&const DeepCollectionEquality().equals(other.sourceSteps, _this.sourceSteps)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&const DeepCollectionEquality().equals(other.steps, _this.steps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TranslationReviewDraft;
  return Object.hash(runtimeType,_this.locale,_this.sourceLocale,_this.sourceTitle,_this.sourceDescription,const DeepCollectionEquality().hash(_this.sourceSteps),_this.title,_this.description,const DeepCollectionEquality().hash(_this.steps));
}

@override
String toString() {
  final _this = this as TranslationReviewDraft;
  return 'TranslationReviewDraft(locale: ${_this.locale}, sourceLocale: ${_this.sourceLocale}, sourceTitle: ${_this.sourceTitle}, sourceDescription: ${_this.sourceDescription}, sourceSteps: ${_this.sourceSteps}, title: ${_this.title}, description: ${_this.description}, steps: ${_this.steps})';
}


}

/// @nodoc
abstract mixin class $TranslationReviewDraftCopyWith<$Res>  {
  factory $TranslationReviewDraftCopyWith(TranslationReviewDraft value, $Res Function(TranslationReviewDraft) _then) = _$TranslationReviewDraftCopyWithImpl;
@useResult
$Res call({
 String locale, String sourceLocale, String sourceTitle, String? sourceDescription, List<RecipeStep> sourceSteps, String title, String? description, List<RecipeStep> steps
});




}
/// @nodoc
class _$TranslationReviewDraftCopyWithImpl<$Res>
    implements $TranslationReviewDraftCopyWith<$Res> {
  _$TranslationReviewDraftCopyWithImpl(this._self, this._then);

  final TranslationReviewDraft _self;
  final $Res Function(TranslationReviewDraft) _then;

/// Create a copy of TranslationReviewDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? locale = null,Object? sourceLocale = null,Object? sourceTitle = null,Object? sourceDescription = freezed,Object? sourceSteps = null,Object? title = null,Object? description = freezed,Object? steps = null,}) {
  return _then(TranslationReviewDraft(
locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,sourceLocale: null == sourceLocale ? _self.sourceLocale : sourceLocale // ignore: cast_nullable_to_non_nullable
as String,sourceTitle: null == sourceTitle ? _self.sourceTitle : sourceTitle // ignore: cast_nullable_to_non_nullable
as String,sourceDescription: freezed == sourceDescription ? _self.sourceDescription : sourceDescription // ignore: cast_nullable_to_non_nullable
as String?,sourceSteps: null == sourceSteps ? _self.sourceSteps : sourceSteps // ignore: cast_nullable_to_non_nullable
as List<RecipeStep>,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<RecipeStep>,
  ));
}

}


/// Adds pattern-matching-related methods to [TranslationReviewDraft].
extension TranslationReviewDraftPatterns on TranslationReviewDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TranslationReviewDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TranslationReviewDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TranslationReviewDraft value)  $default,){
final _that = this;
switch (_that) {
case _TranslationReviewDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TranslationReviewDraft value)?  $default,){
final _that = this;
switch (_that) {
case _TranslationReviewDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String locale,  String sourceLocale,  String sourceTitle,  String? sourceDescription,  List<RecipeStep> sourceSteps,  String title,  String? description,  List<RecipeStep> steps)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TranslationReviewDraft() when $default != null:
return $default(_that.locale,_that.sourceLocale,_that.sourceTitle,_that.sourceDescription,_that.sourceSteps,_that.title,_that.description,_that.steps);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String locale,  String sourceLocale,  String sourceTitle,  String? sourceDescription,  List<RecipeStep> sourceSteps,  String title,  String? description,  List<RecipeStep> steps)  $default,) {final _that = this;
switch (_that) {
case _TranslationReviewDraft():
return $default(_that.locale,_that.sourceLocale,_that.sourceTitle,_that.sourceDescription,_that.sourceSteps,_that.title,_that.description,_that.steps);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String locale,  String sourceLocale,  String sourceTitle,  String? sourceDescription,  List<RecipeStep> sourceSteps,  String title,  String? description,  List<RecipeStep> steps)?  $default,) {final _that = this;
switch (_that) {
case _TranslationReviewDraft() when $default != null:
return $default(_that.locale,_that.sourceLocale,_that.sourceTitle,_that.sourceDescription,_that.sourceSteps,_that.title,_that.description,_that.steps);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TranslationReviewDraft extends TranslationReviewDraft {
  const _TranslationReviewDraft({required this.locale, required this.sourceLocale, required this.sourceTitle, this.sourceDescription,  List<RecipeStep> sourceSteps = const <RecipeStep>[], required this.title, this.description,  List<RecipeStep> steps = const <RecipeStep>[]}): _sourceSteps = sourceSteps,_steps = steps,super._();
  factory _TranslationReviewDraft.fromJson(Map<String, dynamic> json) => _$TranslationReviewDraftFromJson(json);

@override final  String locale;
/// The recipe's own language -- distinct from [locale], which is the
/// language being reviewed. Used only to label the source side of the
/// screen ("Original (Serbian)").
@override final  String sourceLocale;
@override final  String sourceTitle;
@override final  String? sourceDescription;
 final  List<RecipeStep> _sourceSteps;
@override@JsonKey() List<RecipeStep> get sourceSteps {
  if (_sourceSteps is EqualUnmodifiableListView) return _sourceSteps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sourceSteps);
}

@override final  String title;
@override final  String? description;
 final  List<RecipeStep> _steps;
@override@JsonKey() List<RecipeStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}


/// Create a copy of TranslationReviewDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TranslationReviewDraftCopyWith<_TranslationReviewDraft> get copyWith => __$TranslationReviewDraftCopyWithImpl<_TranslationReviewDraft>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TranslationReviewDraftToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TranslationReviewDraft&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.sourceLocale, sourceLocale) || other.sourceLocale == sourceLocale)&&(identical(other.sourceTitle, sourceTitle) || other.sourceTitle == sourceTitle)&&(identical(other.sourceDescription, sourceDescription) || other.sourceDescription == sourceDescription)&&const DeepCollectionEquality().equals(other.sourceSteps, _sourceSteps)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.steps, _steps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,locale,sourceLocale,sourceTitle,sourceDescription,const DeepCollectionEquality().hash(_sourceSteps),title,description,const DeepCollectionEquality().hash(_steps));
}

@override
String toString() {
    return 'TranslationReviewDraft(locale: $locale, sourceLocale: $sourceLocale, sourceTitle: $sourceTitle, sourceDescription: $sourceDescription, sourceSteps: $sourceSteps, title: $title, description: $description, steps: $steps)';
}


}

/// @nodoc
abstract mixin class _$TranslationReviewDraftCopyWith<$Res> implements $TranslationReviewDraftCopyWith<$Res> {
  factory _$TranslationReviewDraftCopyWith(_TranslationReviewDraft value, $Res Function(_TranslationReviewDraft) _then) = __$TranslationReviewDraftCopyWithImpl;
@override @useResult
$Res call({
 String locale, String sourceLocale, String sourceTitle, String? sourceDescription, List<RecipeStep> sourceSteps, String title, String? description, List<RecipeStep> steps
});




}
/// @nodoc
class __$TranslationReviewDraftCopyWithImpl<$Res>
    implements _$TranslationReviewDraftCopyWith<$Res> {
  __$TranslationReviewDraftCopyWithImpl(this._self, this._then);

  final _TranslationReviewDraft _self;
  final $Res Function(_TranslationReviewDraft) _then;

/// Create a copy of TranslationReviewDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? locale = null,Object? sourceLocale = null,Object? sourceTitle = null,Object? sourceDescription = freezed,Object? sourceSteps = null,Object? title = null,Object? description = freezed,Object? steps = null,}) {
  return _then(_TranslationReviewDraft(
locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,sourceLocale: null == sourceLocale ? _self.sourceLocale : sourceLocale // ignore: cast_nullable_to_non_nullable
as String,sourceTitle: null == sourceTitle ? _self.sourceTitle : sourceTitle // ignore: cast_nullable_to_non_nullable
as String,sourceDescription: freezed == sourceDescription ? _self.sourceDescription : sourceDescription // ignore: cast_nullable_to_non_nullable
as String?,sourceSteps: null == sourceSteps ? _self._sourceSteps : sourceSteps // ignore: cast_nullable_to_non_nullable
as List<RecipeStep>,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<RecipeStep>,
  ));
}


}

// dart format on

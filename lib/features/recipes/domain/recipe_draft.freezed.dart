// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecipeDraft {

/// The recipe as last read from or written to the server, or null for a
/// recipe that has never been saved.
///
/// This carries the fields the editor does not own -- `householdId`,
/// `createdBy`, `sourceType` -- so [toRecipe] can build a complete row
/// without the screen having to know they exist. It is also how a second
/// save knows to update rather than create (D37).
 Recipe? get source; String get title; String? get description; int? get servings; int? get prepMinutes; int? get cookMinutes; String get originalLocale; RecipeStatus get status; List<String> get tags; List<RecipeDraftLine> get lines; List<RecipeDraftStep> get steps;
/// Create a copy of RecipeDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeDraftCopyWith<RecipeDraft> get copyWith => _$RecipeDraftCopyWithImpl<RecipeDraft>(this as RecipeDraft, _$identity);

  /// Serializes this RecipeDraft to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RecipeDraft;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipeDraft&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.servings, _this.servings) || other.servings == _this.servings)&&(identical(other.prepMinutes, _this.prepMinutes) || other.prepMinutes == _this.prepMinutes)&&(identical(other.cookMinutes, _this.cookMinutes) || other.cookMinutes == _this.cookMinutes)&&(identical(other.originalLocale, _this.originalLocale) || other.originalLocale == _this.originalLocale)&&(identical(other.status, _this.status) || other.status == _this.status)&&const DeepCollectionEquality().equals(other.tags, _this.tags)&&const DeepCollectionEquality().equals(other.lines, _this.lines)&&const DeepCollectionEquality().equals(other.steps, _this.steps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RecipeDraft;
  return Object.hash(runtimeType,_this.source,_this.title,_this.description,_this.servings,_this.prepMinutes,_this.cookMinutes,_this.originalLocale,_this.status,const DeepCollectionEquality().hash(_this.tags),const DeepCollectionEquality().hash(_this.lines),const DeepCollectionEquality().hash(_this.steps));
}

@override
String toString() {
  final _this = this as RecipeDraft;
  return 'RecipeDraft(source: ${_this.source}, title: ${_this.title}, description: ${_this.description}, servings: ${_this.servings}, prepMinutes: ${_this.prepMinutes}, cookMinutes: ${_this.cookMinutes}, originalLocale: ${_this.originalLocale}, status: ${_this.status}, tags: ${_this.tags}, lines: ${_this.lines}, steps: ${_this.steps})';
}


}

/// @nodoc
abstract mixin class $RecipeDraftCopyWith<$Res>  {
  factory $RecipeDraftCopyWith(RecipeDraft value, $Res Function(RecipeDraft) _then) = _$RecipeDraftCopyWithImpl;
@useResult
$Res call({
 Recipe? source, String title, String? description, int? servings, int? prepMinutes, int? cookMinutes, String originalLocale, RecipeStatus status, List<String> tags, List<RecipeDraftLine> lines, List<RecipeDraftStep> steps
});


$RecipeCopyWith<$Res>? get source;

}
/// @nodoc
class _$RecipeDraftCopyWithImpl<$Res>
    implements $RecipeDraftCopyWith<$Res> {
  _$RecipeDraftCopyWithImpl(this._self, this._then);

  final RecipeDraft _self;
  final $Res Function(RecipeDraft) _then;

/// Create a copy of RecipeDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? source = freezed,Object? title = null,Object? description = freezed,Object? servings = freezed,Object? prepMinutes = freezed,Object? cookMinutes = freezed,Object? originalLocale = null,Object? status = null,Object? tags = null,Object? lines = null,Object? steps = null,}) {
  return _then(RecipeDraft(
source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as Recipe?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,servings: freezed == servings ? _self.servings : servings // ignore: cast_nullable_to_non_nullable
as int?,prepMinutes: freezed == prepMinutes ? _self.prepMinutes : prepMinutes // ignore: cast_nullable_to_non_nullable
as int?,cookMinutes: freezed == cookMinutes ? _self.cookMinutes : cookMinutes // ignore: cast_nullable_to_non_nullable
as int?,originalLocale: null == originalLocale ? _self.originalLocale : originalLocale // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RecipeStatus,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<RecipeDraftLine>,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<RecipeDraftStep>,
  ));
}
/// Create a copy of RecipeDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecipeCopyWith<$Res>? get source {
    if (_self.source == null) {
    return null;
  }

  return $RecipeCopyWith<$Res>(_self.source!, (value) {
    return _then(_self.copyWith(source: value));
  });
}
}


/// Adds pattern-matching-related methods to [RecipeDraft].
extension RecipeDraftPatterns on RecipeDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecipeDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecipeDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecipeDraft value)  $default,){
final _that = this;
switch (_that) {
case _RecipeDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecipeDraft value)?  $default,){
final _that = this;
switch (_that) {
case _RecipeDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Recipe? source,  String title,  String? description,  int? servings,  int? prepMinutes,  int? cookMinutes,  String originalLocale,  RecipeStatus status,  List<String> tags,  List<RecipeDraftLine> lines,  List<RecipeDraftStep> steps)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecipeDraft() when $default != null:
return $default(_that.source,_that.title,_that.description,_that.servings,_that.prepMinutes,_that.cookMinutes,_that.originalLocale,_that.status,_that.tags,_that.lines,_that.steps);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Recipe? source,  String title,  String? description,  int? servings,  int? prepMinutes,  int? cookMinutes,  String originalLocale,  RecipeStatus status,  List<String> tags,  List<RecipeDraftLine> lines,  List<RecipeDraftStep> steps)  $default,) {final _that = this;
switch (_that) {
case _RecipeDraft():
return $default(_that.source,_that.title,_that.description,_that.servings,_that.prepMinutes,_that.cookMinutes,_that.originalLocale,_that.status,_that.tags,_that.lines,_that.steps);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Recipe? source,  String title,  String? description,  int? servings,  int? prepMinutes,  int? cookMinutes,  String originalLocale,  RecipeStatus status,  List<String> tags,  List<RecipeDraftLine> lines,  List<RecipeDraftStep> steps)?  $default,) {final _that = this;
switch (_that) {
case _RecipeDraft() when $default != null:
return $default(_that.source,_that.title,_that.description,_that.servings,_that.prepMinutes,_that.cookMinutes,_that.originalLocale,_that.status,_that.tags,_that.lines,_that.steps);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecipeDraft extends RecipeDraft {
  const _RecipeDraft({this.source, this.title = '', this.description, this.servings, this.prepMinutes, this.cookMinutes, this.originalLocale = 'sr', this.status = RecipeStatus.draft,  List<String> tags = const <String>[],  List<RecipeDraftLine> lines = const <RecipeDraftLine>[],  List<RecipeDraftStep> steps = const <RecipeDraftStep>[]}): _tags = tags,_lines = lines,_steps = steps,super._();
  factory _RecipeDraft.fromJson(Map<String, dynamic> json) => _$RecipeDraftFromJson(json);

/// The recipe as last read from or written to the server, or null for a
/// recipe that has never been saved.
///
/// This carries the fields the editor does not own -- `householdId`,
/// `createdBy`, `sourceType` -- so [toRecipe] can build a complete row
/// without the screen having to know they exist. It is also how a second
/// save knows to update rather than create (D37).
@override final  Recipe? source;
@override@JsonKey() final  String title;
@override final  String? description;
@override final  int? servings;
@override final  int? prepMinutes;
@override final  int? cookMinutes;
@override@JsonKey() final  String originalLocale;
@override@JsonKey() final  RecipeStatus status;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

 final  List<RecipeDraftLine> _lines;
@override@JsonKey() List<RecipeDraftLine> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}

 final  List<RecipeDraftStep> _steps;
@override@JsonKey() List<RecipeDraftStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}


/// Create a copy of RecipeDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeDraftCopyWith<_RecipeDraft> get copyWith => __$RecipeDraftCopyWithImpl<_RecipeDraft>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecipeDraftToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipeDraft&&(identical(other.source, source) || other.source == source)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.servings, servings) || other.servings == servings)&&(identical(other.prepMinutes, prepMinutes) || other.prepMinutes == prepMinutes)&&(identical(other.cookMinutes, cookMinutes) || other.cookMinutes == cookMinutes)&&(identical(other.originalLocale, originalLocale) || other.originalLocale == originalLocale)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.tags, _tags)&&const DeepCollectionEquality().equals(other.lines, _lines)&&const DeepCollectionEquality().equals(other.steps, _steps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,source,title,description,servings,prepMinutes,cookMinutes,originalLocale,status,const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_lines),const DeepCollectionEquality().hash(_steps));
}

@override
String toString() {
    return 'RecipeDraft(source: $source, title: $title, description: $description, servings: $servings, prepMinutes: $prepMinutes, cookMinutes: $cookMinutes, originalLocale: $originalLocale, status: $status, tags: $tags, lines: $lines, steps: $steps)';
}


}

/// @nodoc
abstract mixin class _$RecipeDraftCopyWith<$Res> implements $RecipeDraftCopyWith<$Res> {
  factory _$RecipeDraftCopyWith(_RecipeDraft value, $Res Function(_RecipeDraft) _then) = __$RecipeDraftCopyWithImpl;
@override @useResult
$Res call({
 Recipe? source, String title, String? description, int? servings, int? prepMinutes, int? cookMinutes, String originalLocale, RecipeStatus status, List<String> tags, List<RecipeDraftLine> lines, List<RecipeDraftStep> steps
});


@override $RecipeCopyWith<$Res>? get source;

}
/// @nodoc
class __$RecipeDraftCopyWithImpl<$Res>
    implements _$RecipeDraftCopyWith<$Res> {
  __$RecipeDraftCopyWithImpl(this._self, this._then);

  final _RecipeDraft _self;
  final $Res Function(_RecipeDraft) _then;

/// Create a copy of RecipeDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = freezed,Object? title = null,Object? description = freezed,Object? servings = freezed,Object? prepMinutes = freezed,Object? cookMinutes = freezed,Object? originalLocale = null,Object? status = null,Object? tags = null,Object? lines = null,Object? steps = null,}) {
  return _then(_RecipeDraft(
source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as Recipe?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,servings: freezed == servings ? _self.servings : servings // ignore: cast_nullable_to_non_nullable
as int?,prepMinutes: freezed == prepMinutes ? _self.prepMinutes : prepMinutes // ignore: cast_nullable_to_non_nullable
as int?,cookMinutes: freezed == cookMinutes ? _self.cookMinutes : cookMinutes // ignore: cast_nullable_to_non_nullable
as int?,originalLocale: null == originalLocale ? _self.originalLocale : originalLocale // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RecipeStatus,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<RecipeDraftLine>,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<RecipeDraftStep>,
  ));
}

/// Create a copy of RecipeDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecipeCopyWith<$Res>? get source {
    if (_self.source == null) {
    return null;
  }

  return $RecipeCopyWith<$Res>(_self.source!, (value) {
    return _then(_self.copyWith(source: value));
  });
}
}


/// @nodoc
mixin _$RecipeDraftLine {

 int get localId; String get rawText; String? get section; String? get ingredientId; String? get displayName; Quantity? get quantity; String? get unitCode; String? get note; bool get isOptional; MatchMethod? get matchMethod; double? get matchConfidence; DateTime? get matchedAt;
/// Create a copy of RecipeDraftLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeDraftLineCopyWith<RecipeDraftLine> get copyWith => _$RecipeDraftLineCopyWithImpl<RecipeDraftLine>(this as RecipeDraftLine, _$identity);

  /// Serializes this RecipeDraftLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RecipeDraftLine;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipeDraftLine&&(identical(other.localId, _this.localId) || other.localId == _this.localId)&&(identical(other.rawText, _this.rawText) || other.rawText == _this.rawText)&&(identical(other.section, _this.section) || other.section == _this.section)&&(identical(other.ingredientId, _this.ingredientId) || other.ingredientId == _this.ingredientId)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.quantity, _this.quantity) || other.quantity == _this.quantity)&&(identical(other.unitCode, _this.unitCode) || other.unitCode == _this.unitCode)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.isOptional, _this.isOptional) || other.isOptional == _this.isOptional)&&(identical(other.matchMethod, _this.matchMethod) || other.matchMethod == _this.matchMethod)&&(identical(other.matchConfidence, _this.matchConfidence) || other.matchConfidence == _this.matchConfidence)&&(identical(other.matchedAt, _this.matchedAt) || other.matchedAt == _this.matchedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RecipeDraftLine;
  return Object.hash(runtimeType,_this.localId,_this.rawText,_this.section,_this.ingredientId,_this.displayName,_this.quantity,_this.unitCode,_this.note,_this.isOptional,_this.matchMethod,_this.matchConfidence,_this.matchedAt);
}

@override
String toString() {
  final _this = this as RecipeDraftLine;
  return 'RecipeDraftLine(localId: ${_this.localId}, rawText: ${_this.rawText}, section: ${_this.section}, ingredientId: ${_this.ingredientId}, displayName: ${_this.displayName}, quantity: ${_this.quantity}, unitCode: ${_this.unitCode}, note: ${_this.note}, isOptional: ${_this.isOptional}, matchMethod: ${_this.matchMethod}, matchConfidence: ${_this.matchConfidence}, matchedAt: ${_this.matchedAt})';
}


}

/// @nodoc
abstract mixin class $RecipeDraftLineCopyWith<$Res>  {
  factory $RecipeDraftLineCopyWith(RecipeDraftLine value, $Res Function(RecipeDraftLine) _then) = _$RecipeDraftLineCopyWithImpl;
@useResult
$Res call({
 int localId, String rawText, String? section, String? ingredientId, String? displayName, Quantity? quantity, String? unitCode, String? note, bool isOptional, MatchMethod? matchMethod, double? matchConfidence, DateTime? matchedAt
});


$QuantityCopyWith<$Res>? get quantity;

}
/// @nodoc
class _$RecipeDraftLineCopyWithImpl<$Res>
    implements $RecipeDraftLineCopyWith<$Res> {
  _$RecipeDraftLineCopyWithImpl(this._self, this._then);

  final RecipeDraftLine _self;
  final $Res Function(RecipeDraftLine) _then;

/// Create a copy of RecipeDraftLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? localId = null,Object? rawText = null,Object? section = freezed,Object? ingredientId = freezed,Object? displayName = freezed,Object? quantity = freezed,Object? unitCode = freezed,Object? note = freezed,Object? isOptional = null,Object? matchMethod = freezed,Object? matchConfidence = freezed,Object? matchedAt = freezed,}) {
  return _then(RecipeDraftLine(
localId: null == localId ? _self.localId : localId // ignore: cast_nullable_to_non_nullable
as int,rawText: null == rawText ? _self.rawText : rawText // ignore: cast_nullable_to_non_nullable
as String,section: freezed == section ? _self.section : section // ignore: cast_nullable_to_non_nullable
as String?,ingredientId: freezed == ingredientId ? _self.ingredientId : ingredientId // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as Quantity?,unitCode: freezed == unitCode ? _self.unitCode : unitCode // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,isOptional: null == isOptional ? _self.isOptional : isOptional // ignore: cast_nullable_to_non_nullable
as bool,matchMethod: freezed == matchMethod ? _self.matchMethod : matchMethod // ignore: cast_nullable_to_non_nullable
as MatchMethod?,matchConfidence: freezed == matchConfidence ? _self.matchConfidence : matchConfidence // ignore: cast_nullable_to_non_nullable
as double?,matchedAt: freezed == matchedAt ? _self.matchedAt : matchedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of RecipeDraftLine
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


/// Adds pattern-matching-related methods to [RecipeDraftLine].
extension RecipeDraftLinePatterns on RecipeDraftLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecipeDraftLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecipeDraftLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecipeDraftLine value)  $default,){
final _that = this;
switch (_that) {
case _RecipeDraftLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecipeDraftLine value)?  $default,){
final _that = this;
switch (_that) {
case _RecipeDraftLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int localId,  String rawText,  String? section,  String? ingredientId,  String? displayName,  Quantity? quantity,  String? unitCode,  String? note,  bool isOptional,  MatchMethod? matchMethod,  double? matchConfidence,  DateTime? matchedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecipeDraftLine() when $default != null:
return $default(_that.localId,_that.rawText,_that.section,_that.ingredientId,_that.displayName,_that.quantity,_that.unitCode,_that.note,_that.isOptional,_that.matchMethod,_that.matchConfidence,_that.matchedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int localId,  String rawText,  String? section,  String? ingredientId,  String? displayName,  Quantity? quantity,  String? unitCode,  String? note,  bool isOptional,  MatchMethod? matchMethod,  double? matchConfidence,  DateTime? matchedAt)  $default,) {final _that = this;
switch (_that) {
case _RecipeDraftLine():
return $default(_that.localId,_that.rawText,_that.section,_that.ingredientId,_that.displayName,_that.quantity,_that.unitCode,_that.note,_that.isOptional,_that.matchMethod,_that.matchConfidence,_that.matchedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int localId,  String rawText,  String? section,  String? ingredientId,  String? displayName,  Quantity? quantity,  String? unitCode,  String? note,  bool isOptional,  MatchMethod? matchMethod,  double? matchConfidence,  DateTime? matchedAt)?  $default,) {final _that = this;
switch (_that) {
case _RecipeDraftLine() when $default != null:
return $default(_that.localId,_that.rawText,_that.section,_that.ingredientId,_that.displayName,_that.quantity,_that.unitCode,_that.note,_that.isOptional,_that.matchMethod,_that.matchConfidence,_that.matchedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecipeDraftLine extends RecipeDraftLine {
  const _RecipeDraftLine({required this.localId, required this.rawText, this.section, this.ingredientId, this.displayName, this.quantity, this.unitCode, this.note, this.isOptional = false, this.matchMethod, this.matchConfidence, this.matchedAt}): super._();
  factory _RecipeDraftLine.fromJson(Map<String, dynamic> json) => _$RecipeDraftLineFromJson(json);

@override final  int localId;
@override final  String rawText;
@override final  String? section;
@override final  String? ingredientId;
@override final  String? displayName;
@override final  Quantity? quantity;
@override final  String? unitCode;
@override final  String? note;
@override@JsonKey() final  bool isOptional;
@override final  MatchMethod? matchMethod;
@override final  double? matchConfidence;
@override final  DateTime? matchedAt;

/// Create a copy of RecipeDraftLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeDraftLineCopyWith<_RecipeDraftLine> get copyWith => __$RecipeDraftLineCopyWithImpl<_RecipeDraftLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecipeDraftLineToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipeDraftLine&&(identical(other.localId, localId) || other.localId == localId)&&(identical(other.rawText, rawText) || other.rawText == rawText)&&(identical(other.section, section) || other.section == section)&&(identical(other.ingredientId, ingredientId) || other.ingredientId == ingredientId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitCode, unitCode) || other.unitCode == unitCode)&&(identical(other.note, note) || other.note == note)&&(identical(other.isOptional, isOptional) || other.isOptional == isOptional)&&(identical(other.matchMethod, matchMethod) || other.matchMethod == matchMethod)&&(identical(other.matchConfidence, matchConfidence) || other.matchConfidence == matchConfidence)&&(identical(other.matchedAt, matchedAt) || other.matchedAt == matchedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,localId,rawText,section,ingredientId,displayName,quantity,unitCode,note,isOptional,matchMethod,matchConfidence,matchedAt);
}

@override
String toString() {
    return 'RecipeDraftLine(localId: $localId, rawText: $rawText, section: $section, ingredientId: $ingredientId, displayName: $displayName, quantity: $quantity, unitCode: $unitCode, note: $note, isOptional: $isOptional, matchMethod: $matchMethod, matchConfidence: $matchConfidence, matchedAt: $matchedAt)';
}


}

/// @nodoc
abstract mixin class _$RecipeDraftLineCopyWith<$Res> implements $RecipeDraftLineCopyWith<$Res> {
  factory _$RecipeDraftLineCopyWith(_RecipeDraftLine value, $Res Function(_RecipeDraftLine) _then) = __$RecipeDraftLineCopyWithImpl;
@override @useResult
$Res call({
 int localId, String rawText, String? section, String? ingredientId, String? displayName, Quantity? quantity, String? unitCode, String? note, bool isOptional, MatchMethod? matchMethod, double? matchConfidence, DateTime? matchedAt
});


@override $QuantityCopyWith<$Res>? get quantity;

}
/// @nodoc
class __$RecipeDraftLineCopyWithImpl<$Res>
    implements _$RecipeDraftLineCopyWith<$Res> {
  __$RecipeDraftLineCopyWithImpl(this._self, this._then);

  final _RecipeDraftLine _self;
  final $Res Function(_RecipeDraftLine) _then;

/// Create a copy of RecipeDraftLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? localId = null,Object? rawText = null,Object? section = freezed,Object? ingredientId = freezed,Object? displayName = freezed,Object? quantity = freezed,Object? unitCode = freezed,Object? note = freezed,Object? isOptional = null,Object? matchMethod = freezed,Object? matchConfidence = freezed,Object? matchedAt = freezed,}) {
  return _then(_RecipeDraftLine(
localId: null == localId ? _self.localId : localId // ignore: cast_nullable_to_non_nullable
as int,rawText: null == rawText ? _self.rawText : rawText // ignore: cast_nullable_to_non_nullable
as String,section: freezed == section ? _self.section : section // ignore: cast_nullable_to_non_nullable
as String?,ingredientId: freezed == ingredientId ? _self.ingredientId : ingredientId // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as Quantity?,unitCode: freezed == unitCode ? _self.unitCode : unitCode // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,isOptional: null == isOptional ? _self.isOptional : isOptional // ignore: cast_nullable_to_non_nullable
as bool,matchMethod: freezed == matchMethod ? _self.matchMethod : matchMethod // ignore: cast_nullable_to_non_nullable
as MatchMethod?,matchConfidence: freezed == matchConfidence ? _self.matchConfidence : matchConfidence // ignore: cast_nullable_to_non_nullable
as double?,matchedAt: freezed == matchedAt ? _self.matchedAt : matchedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of RecipeDraftLine
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


/// @nodoc
mixin _$RecipeDraftStep {

 int get localId; String get text; int? get timerSeconds;
/// Create a copy of RecipeDraftStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeDraftStepCopyWith<RecipeDraftStep> get copyWith => _$RecipeDraftStepCopyWithImpl<RecipeDraftStep>(this as RecipeDraftStep, _$identity);

  /// Serializes this RecipeDraftStep to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RecipeDraftStep;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipeDraftStep&&(identical(other.localId, _this.localId) || other.localId == _this.localId)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.timerSeconds, _this.timerSeconds) || other.timerSeconds == _this.timerSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RecipeDraftStep;
  return Object.hash(runtimeType,_this.localId,_this.text,_this.timerSeconds);
}

@override
String toString() {
  final _this = this as RecipeDraftStep;
  return 'RecipeDraftStep(localId: ${_this.localId}, text: ${_this.text}, timerSeconds: ${_this.timerSeconds})';
}


}

/// @nodoc
abstract mixin class $RecipeDraftStepCopyWith<$Res>  {
  factory $RecipeDraftStepCopyWith(RecipeDraftStep value, $Res Function(RecipeDraftStep) _then) = _$RecipeDraftStepCopyWithImpl;
@useResult
$Res call({
 int localId, String text, int? timerSeconds
});




}
/// @nodoc
class _$RecipeDraftStepCopyWithImpl<$Res>
    implements $RecipeDraftStepCopyWith<$Res> {
  _$RecipeDraftStepCopyWithImpl(this._self, this._then);

  final RecipeDraftStep _self;
  final $Res Function(RecipeDraftStep) _then;

/// Create a copy of RecipeDraftStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? localId = null,Object? text = null,Object? timerSeconds = freezed,}) {
  return _then(RecipeDraftStep(
localId: null == localId ? _self.localId : localId // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,timerSeconds: freezed == timerSeconds ? _self.timerSeconds : timerSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [RecipeDraftStep].
extension RecipeDraftStepPatterns on RecipeDraftStep {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecipeDraftStep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecipeDraftStep() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecipeDraftStep value)  $default,){
final _that = this;
switch (_that) {
case _RecipeDraftStep():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecipeDraftStep value)?  $default,){
final _that = this;
switch (_that) {
case _RecipeDraftStep() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int localId,  String text,  int? timerSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecipeDraftStep() when $default != null:
return $default(_that.localId,_that.text,_that.timerSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int localId,  String text,  int? timerSeconds)  $default,) {final _that = this;
switch (_that) {
case _RecipeDraftStep():
return $default(_that.localId,_that.text,_that.timerSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int localId,  String text,  int? timerSeconds)?  $default,) {final _that = this;
switch (_that) {
case _RecipeDraftStep() when $default != null:
return $default(_that.localId,_that.text,_that.timerSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecipeDraftStep implements RecipeDraftStep {
  const _RecipeDraftStep({required this.localId, required this.text, this.timerSeconds});
  factory _RecipeDraftStep.fromJson(Map<String, dynamic> json) => _$RecipeDraftStepFromJson(json);

@override final  int localId;
@override final  String text;
@override final  int? timerSeconds;

/// Create a copy of RecipeDraftStep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeDraftStepCopyWith<_RecipeDraftStep> get copyWith => __$RecipeDraftStepCopyWithImpl<_RecipeDraftStep>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecipeDraftStepToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipeDraftStep&&(identical(other.localId, localId) || other.localId == localId)&&(identical(other.text, text) || other.text == text)&&(identical(other.timerSeconds, timerSeconds) || other.timerSeconds == timerSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,localId,text,timerSeconds);
}

@override
String toString() {
    return 'RecipeDraftStep(localId: $localId, text: $text, timerSeconds: $timerSeconds)';
}


}

/// @nodoc
abstract mixin class _$RecipeDraftStepCopyWith<$Res> implements $RecipeDraftStepCopyWith<$Res> {
  factory _$RecipeDraftStepCopyWith(_RecipeDraftStep value, $Res Function(_RecipeDraftStep) _then) = __$RecipeDraftStepCopyWithImpl;
@override @useResult
$Res call({
 int localId, String text, int? timerSeconds
});




}
/// @nodoc
class __$RecipeDraftStepCopyWithImpl<$Res>
    implements _$RecipeDraftStepCopyWith<$Res> {
  __$RecipeDraftStepCopyWithImpl(this._self, this._then);

  final _RecipeDraftStep _self;
  final $Res Function(_RecipeDraftStep) _then;

/// Create a copy of RecipeDraftStep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? localId = null,Object? text = null,Object? timerSeconds = freezed,}) {
  return _then(_RecipeDraftStep(
localId: null == localId ? _self.localId : localId // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,timerSeconds: freezed == timerSeconds ? _self.timerSeconds : timerSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on

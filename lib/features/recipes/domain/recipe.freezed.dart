// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Recipe {

 String get id; String get householdId; String get title; String get originalLocale; RecipeSourceType get sourceType; RecipeStatus get status; String get createdBy; String? get description; int? get servings; int? get prepMinutes; int? get cookMinutes; String? get sourceUrl; String? get sourceAttribution;/// A Supabase Storage object path. Always null in Phase 1c -- the bucket
/// and the picker are Phase 2 (D35). The field ships now so that slice
/// adds a screen rather than a migration.
 String? get imagePath; List<String> get tags; DateTime? get updatedAt; DateTime? get deletedAt;
/// Create a copy of Recipe
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeCopyWith<Recipe> get copyWith => _$RecipeCopyWithImpl<Recipe>(this as Recipe, _$identity);

  /// Serializes this Recipe to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Recipe;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Recipe&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.householdId, _this.householdId) || other.householdId == _this.householdId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.originalLocale, _this.originalLocale) || other.originalLocale == _this.originalLocale)&&(identical(other.sourceType, _this.sourceType) || other.sourceType == _this.sourceType)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.servings, _this.servings) || other.servings == _this.servings)&&(identical(other.prepMinutes, _this.prepMinutes) || other.prepMinutes == _this.prepMinutes)&&(identical(other.cookMinutes, _this.cookMinutes) || other.cookMinutes == _this.cookMinutes)&&(identical(other.sourceUrl, _this.sourceUrl) || other.sourceUrl == _this.sourceUrl)&&(identical(other.sourceAttribution, _this.sourceAttribution) || other.sourceAttribution == _this.sourceAttribution)&&(identical(other.imagePath, _this.imagePath) || other.imagePath == _this.imagePath)&&const DeepCollectionEquality().equals(other.tags, _this.tags)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.deletedAt, _this.deletedAt) || other.deletedAt == _this.deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Recipe;
  return Object.hash(runtimeType,_this.id,_this.householdId,_this.title,_this.originalLocale,_this.sourceType,_this.status,_this.createdBy,_this.description,_this.servings,_this.prepMinutes,_this.cookMinutes,_this.sourceUrl,_this.sourceAttribution,_this.imagePath,const DeepCollectionEquality().hash(_this.tags),_this.updatedAt,_this.deletedAt);
}

@override
String toString() {
  final _this = this as Recipe;
  return 'Recipe(id: ${_this.id}, householdId: ${_this.householdId}, title: ${_this.title}, originalLocale: ${_this.originalLocale}, sourceType: ${_this.sourceType}, status: ${_this.status}, createdBy: ${_this.createdBy}, description: ${_this.description}, servings: ${_this.servings}, prepMinutes: ${_this.prepMinutes}, cookMinutes: ${_this.cookMinutes}, sourceUrl: ${_this.sourceUrl}, sourceAttribution: ${_this.sourceAttribution}, imagePath: ${_this.imagePath}, tags: ${_this.tags}, updatedAt: ${_this.updatedAt}, deletedAt: ${_this.deletedAt})';
}


}

/// @nodoc
abstract mixin class $RecipeCopyWith<$Res>  {
  factory $RecipeCopyWith(Recipe value, $Res Function(Recipe) _then) = _$RecipeCopyWithImpl;
@useResult
$Res call({
 String id, String householdId, String title, String originalLocale, RecipeSourceType sourceType, RecipeStatus status, String createdBy, String? description, int? servings, int? prepMinutes, int? cookMinutes, String? sourceUrl, String? sourceAttribution, String? imagePath, List<String> tags, DateTime? updatedAt, DateTime? deletedAt
});




}
/// @nodoc
class _$RecipeCopyWithImpl<$Res>
    implements $RecipeCopyWith<$Res> {
  _$RecipeCopyWithImpl(this._self, this._then);

  final Recipe _self;
  final $Res Function(Recipe) _then;

/// Create a copy of Recipe
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? householdId = null,Object? title = null,Object? originalLocale = null,Object? sourceType = null,Object? status = null,Object? createdBy = null,Object? description = freezed,Object? servings = freezed,Object? prepMinutes = freezed,Object? cookMinutes = freezed,Object? sourceUrl = freezed,Object? sourceAttribution = freezed,Object? imagePath = freezed,Object? tags = null,Object? updatedAt = freezed,Object? deletedAt = freezed,}) {
  return _then(Recipe(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,originalLocale: null == originalLocale ? _self.originalLocale : originalLocale // ignore: cast_nullable_to_non_nullable
as String,sourceType: null == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as RecipeSourceType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RecipeStatus,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,servings: freezed == servings ? _self.servings : servings // ignore: cast_nullable_to_non_nullable
as int?,prepMinutes: freezed == prepMinutes ? _self.prepMinutes : prepMinutes // ignore: cast_nullable_to_non_nullable
as int?,cookMinutes: freezed == cookMinutes ? _self.cookMinutes : cookMinutes // ignore: cast_nullable_to_non_nullable
as int?,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,sourceAttribution: freezed == sourceAttribution ? _self.sourceAttribution : sourceAttribution // ignore: cast_nullable_to_non_nullable
as String?,imagePath: freezed == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Recipe].
extension RecipePatterns on Recipe {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Recipe value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Recipe() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Recipe value)  $default,){
final _that = this;
switch (_that) {
case _Recipe():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Recipe value)?  $default,){
final _that = this;
switch (_that) {
case _Recipe() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String householdId,  String title,  String originalLocale,  RecipeSourceType sourceType,  RecipeStatus status,  String createdBy,  String? description,  int? servings,  int? prepMinutes,  int? cookMinutes,  String? sourceUrl,  String? sourceAttribution,  String? imagePath,  List<String> tags,  DateTime? updatedAt,  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Recipe() when $default != null:
return $default(_that.id,_that.householdId,_that.title,_that.originalLocale,_that.sourceType,_that.status,_that.createdBy,_that.description,_that.servings,_that.prepMinutes,_that.cookMinutes,_that.sourceUrl,_that.sourceAttribution,_that.imagePath,_that.tags,_that.updatedAt,_that.deletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String householdId,  String title,  String originalLocale,  RecipeSourceType sourceType,  RecipeStatus status,  String createdBy,  String? description,  int? servings,  int? prepMinutes,  int? cookMinutes,  String? sourceUrl,  String? sourceAttribution,  String? imagePath,  List<String> tags,  DateTime? updatedAt,  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _Recipe():
return $default(_that.id,_that.householdId,_that.title,_that.originalLocale,_that.sourceType,_that.status,_that.createdBy,_that.description,_that.servings,_that.prepMinutes,_that.cookMinutes,_that.sourceUrl,_that.sourceAttribution,_that.imagePath,_that.tags,_that.updatedAt,_that.deletedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String householdId,  String title,  String originalLocale,  RecipeSourceType sourceType,  RecipeStatus status,  String createdBy,  String? description,  int? servings,  int? prepMinutes,  int? cookMinutes,  String? sourceUrl,  String? sourceAttribution,  String? imagePath,  List<String> tags,  DateTime? updatedAt,  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _Recipe() when $default != null:
return $default(_that.id,_that.householdId,_that.title,_that.originalLocale,_that.sourceType,_that.status,_that.createdBy,_that.description,_that.servings,_that.prepMinutes,_that.cookMinutes,_that.sourceUrl,_that.sourceAttribution,_that.imagePath,_that.tags,_that.updatedAt,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Recipe implements Recipe {
  const _Recipe({required this.id, required this.householdId, required this.title, required this.originalLocale, required this.sourceType, required this.status, required this.createdBy, this.description, this.servings, this.prepMinutes, this.cookMinutes, this.sourceUrl, this.sourceAttribution, this.imagePath,  List<String> tags = const <String>[], this.updatedAt, this.deletedAt}): _tags = tags;
  factory _Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);

@override final  String id;
@override final  String householdId;
@override final  String title;
@override final  String originalLocale;
@override final  RecipeSourceType sourceType;
@override final  RecipeStatus status;
@override final  String createdBy;
@override final  String? description;
@override final  int? servings;
@override final  int? prepMinutes;
@override final  int? cookMinutes;
@override final  String? sourceUrl;
@override final  String? sourceAttribution;
/// A Supabase Storage object path. Always null in Phase 1c -- the bucket
/// and the picker are Phase 2 (D35). The field ships now so that slice
/// adds a screen rather than a migration.
@override final  String? imagePath;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override final  DateTime? updatedAt;
@override final  DateTime? deletedAt;

/// Create a copy of Recipe
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeCopyWith<_Recipe> get copyWith => __$RecipeCopyWithImpl<_Recipe>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecipeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Recipe&&(identical(other.id, id) || other.id == id)&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.title, title) || other.title == title)&&(identical(other.originalLocale, originalLocale) || other.originalLocale == originalLocale)&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.description, description) || other.description == description)&&(identical(other.servings, servings) || other.servings == servings)&&(identical(other.prepMinutes, prepMinutes) || other.prepMinutes == prepMinutes)&&(identical(other.cookMinutes, cookMinutes) || other.cookMinutes == cookMinutes)&&(identical(other.sourceUrl, sourceUrl) || other.sourceUrl == sourceUrl)&&(identical(other.sourceAttribution, sourceAttribution) || other.sourceAttribution == sourceAttribution)&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath)&&const DeepCollectionEquality().equals(other.tags, _tags)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,householdId,title,originalLocale,sourceType,status,createdBy,description,servings,prepMinutes,cookMinutes,sourceUrl,sourceAttribution,imagePath,const DeepCollectionEquality().hash(_tags),updatedAt,deletedAt);
}

@override
String toString() {
    return 'Recipe(id: $id, householdId: $householdId, title: $title, originalLocale: $originalLocale, sourceType: $sourceType, status: $status, createdBy: $createdBy, description: $description, servings: $servings, prepMinutes: $prepMinutes, cookMinutes: $cookMinutes, sourceUrl: $sourceUrl, sourceAttribution: $sourceAttribution, imagePath: $imagePath, tags: $tags, updatedAt: $updatedAt, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$RecipeCopyWith<$Res> implements $RecipeCopyWith<$Res> {
  factory _$RecipeCopyWith(_Recipe value, $Res Function(_Recipe) _then) = __$RecipeCopyWithImpl;
@override @useResult
$Res call({
 String id, String householdId, String title, String originalLocale, RecipeSourceType sourceType, RecipeStatus status, String createdBy, String? description, int? servings, int? prepMinutes, int? cookMinutes, String? sourceUrl, String? sourceAttribution, String? imagePath, List<String> tags, DateTime? updatedAt, DateTime? deletedAt
});




}
/// @nodoc
class __$RecipeCopyWithImpl<$Res>
    implements _$RecipeCopyWith<$Res> {
  __$RecipeCopyWithImpl(this._self, this._then);

  final _Recipe _self;
  final $Res Function(_Recipe) _then;

/// Create a copy of Recipe
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? householdId = null,Object? title = null,Object? originalLocale = null,Object? sourceType = null,Object? status = null,Object? createdBy = null,Object? description = freezed,Object? servings = freezed,Object? prepMinutes = freezed,Object? cookMinutes = freezed,Object? sourceUrl = freezed,Object? sourceAttribution = freezed,Object? imagePath = freezed,Object? tags = null,Object? updatedAt = freezed,Object? deletedAt = freezed,}) {
  return _then(_Recipe(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,originalLocale: null == originalLocale ? _self.originalLocale : originalLocale // ignore: cast_nullable_to_non_nullable
as String,sourceType: null == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as RecipeSourceType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RecipeStatus,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,servings: freezed == servings ? _self.servings : servings // ignore: cast_nullable_to_non_nullable
as int?,prepMinutes: freezed == prepMinutes ? _self.prepMinutes : prepMinutes // ignore: cast_nullable_to_non_nullable
as int?,cookMinutes: freezed == cookMinutes ? _self.cookMinutes : cookMinutes // ignore: cast_nullable_to_non_nullable
as int?,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,sourceAttribution: freezed == sourceAttribution ? _self.sourceAttribution : sourceAttribution // ignore: cast_nullable_to_non_nullable
as String?,imagePath: freezed == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

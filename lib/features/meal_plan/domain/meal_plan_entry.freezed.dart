// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meal_plan_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MealPlanEntry {

 String get id; String get mealPlanId; DateTime get entryDate; MealSlot get slot; int get position; MealEntryKind get entryKind; String? get recipeId;/// The source entry this is leftovers of, for `entryKind ==
/// MealEntryKind.leftover`. Ships unreachable in migration 14 (D51);
/// Phase 2 part 3 (D55) writes it, and derives [recipeId] onto the row
/// server-side from the source -- never sent by the client -- so a
/// leftover entry's [recipeId] and [recipeTitle] are trustworthy without
/// a join, the same way [recipeId] already is for an `entryKind ==
/// recipe` row.
 String? get leftoverOfEntryId; String? get note; int? get servings;/// Resolved, not stored -- see the class doc.
 String? get recipeTitle; int? get recipeServings;
/// Create a copy of MealPlanEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MealPlanEntryCopyWith<MealPlanEntry> get copyWith => _$MealPlanEntryCopyWithImpl<MealPlanEntry>(this as MealPlanEntry, _$identity);

  /// Serializes this MealPlanEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MealPlanEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealPlanEntry&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.mealPlanId, _this.mealPlanId) || other.mealPlanId == _this.mealPlanId)&&(identical(other.entryDate, _this.entryDate) || other.entryDate == _this.entryDate)&&(identical(other.slot, _this.slot) || other.slot == _this.slot)&&(identical(other.position, _this.position) || other.position == _this.position)&&(identical(other.entryKind, _this.entryKind) || other.entryKind == _this.entryKind)&&(identical(other.recipeId, _this.recipeId) || other.recipeId == _this.recipeId)&&(identical(other.leftoverOfEntryId, _this.leftoverOfEntryId) || other.leftoverOfEntryId == _this.leftoverOfEntryId)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.servings, _this.servings) || other.servings == _this.servings)&&(identical(other.recipeTitle, _this.recipeTitle) || other.recipeTitle == _this.recipeTitle)&&(identical(other.recipeServings, _this.recipeServings) || other.recipeServings == _this.recipeServings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MealPlanEntry;
  return Object.hash(runtimeType,_this.id,_this.mealPlanId,_this.entryDate,_this.slot,_this.position,_this.entryKind,_this.recipeId,_this.leftoverOfEntryId,_this.note,_this.servings,_this.recipeTitle,_this.recipeServings);
}

@override
String toString() {
  final _this = this as MealPlanEntry;
  return 'MealPlanEntry(id: ${_this.id}, mealPlanId: ${_this.mealPlanId}, entryDate: ${_this.entryDate}, slot: ${_this.slot}, position: ${_this.position}, entryKind: ${_this.entryKind}, recipeId: ${_this.recipeId}, leftoverOfEntryId: ${_this.leftoverOfEntryId}, note: ${_this.note}, servings: ${_this.servings}, recipeTitle: ${_this.recipeTitle}, recipeServings: ${_this.recipeServings})';
}


}

/// @nodoc
abstract mixin class $MealPlanEntryCopyWith<$Res>  {
  factory $MealPlanEntryCopyWith(MealPlanEntry value, $Res Function(MealPlanEntry) _then) = _$MealPlanEntryCopyWithImpl;
@useResult
$Res call({
 String id, String mealPlanId, DateTime entryDate, MealSlot slot, int position, MealEntryKind entryKind, String? recipeId, String? leftoverOfEntryId, String? note, int? servings, String? recipeTitle, int? recipeServings
});




}
/// @nodoc
class _$MealPlanEntryCopyWithImpl<$Res>
    implements $MealPlanEntryCopyWith<$Res> {
  _$MealPlanEntryCopyWithImpl(this._self, this._then);

  final MealPlanEntry _self;
  final $Res Function(MealPlanEntry) _then;

/// Create a copy of MealPlanEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? mealPlanId = null,Object? entryDate = null,Object? slot = null,Object? position = null,Object? entryKind = null,Object? recipeId = freezed,Object? leftoverOfEntryId = freezed,Object? note = freezed,Object? servings = freezed,Object? recipeTitle = freezed,Object? recipeServings = freezed,}) {
  return _then(MealPlanEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mealPlanId: null == mealPlanId ? _self.mealPlanId : mealPlanId // ignore: cast_nullable_to_non_nullable
as String,entryDate: null == entryDate ? _self.entryDate : entryDate // ignore: cast_nullable_to_non_nullable
as DateTime,slot: null == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as MealSlot,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,entryKind: null == entryKind ? _self.entryKind : entryKind // ignore: cast_nullable_to_non_nullable
as MealEntryKind,recipeId: freezed == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String?,leftoverOfEntryId: freezed == leftoverOfEntryId ? _self.leftoverOfEntryId : leftoverOfEntryId // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,servings: freezed == servings ? _self.servings : servings // ignore: cast_nullable_to_non_nullable
as int?,recipeTitle: freezed == recipeTitle ? _self.recipeTitle : recipeTitle // ignore: cast_nullable_to_non_nullable
as String?,recipeServings: freezed == recipeServings ? _self.recipeServings : recipeServings // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [MealPlanEntry].
extension MealPlanEntryPatterns on MealPlanEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MealPlanEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MealPlanEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MealPlanEntry value)  $default,){
final _that = this;
switch (_that) {
case _MealPlanEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MealPlanEntry value)?  $default,){
final _that = this;
switch (_that) {
case _MealPlanEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String mealPlanId,  DateTime entryDate,  MealSlot slot,  int position,  MealEntryKind entryKind,  String? recipeId,  String? leftoverOfEntryId,  String? note,  int? servings,  String? recipeTitle,  int? recipeServings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MealPlanEntry() when $default != null:
return $default(_that.id,_that.mealPlanId,_that.entryDate,_that.slot,_that.position,_that.entryKind,_that.recipeId,_that.leftoverOfEntryId,_that.note,_that.servings,_that.recipeTitle,_that.recipeServings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String mealPlanId,  DateTime entryDate,  MealSlot slot,  int position,  MealEntryKind entryKind,  String? recipeId,  String? leftoverOfEntryId,  String? note,  int? servings,  String? recipeTitle,  int? recipeServings)  $default,) {final _that = this;
switch (_that) {
case _MealPlanEntry():
return $default(_that.id,_that.mealPlanId,_that.entryDate,_that.slot,_that.position,_that.entryKind,_that.recipeId,_that.leftoverOfEntryId,_that.note,_that.servings,_that.recipeTitle,_that.recipeServings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String mealPlanId,  DateTime entryDate,  MealSlot slot,  int position,  MealEntryKind entryKind,  String? recipeId,  String? leftoverOfEntryId,  String? note,  int? servings,  String? recipeTitle,  int? recipeServings)?  $default,) {final _that = this;
switch (_that) {
case _MealPlanEntry() when $default != null:
return $default(_that.id,_that.mealPlanId,_that.entryDate,_that.slot,_that.position,_that.entryKind,_that.recipeId,_that.leftoverOfEntryId,_that.note,_that.servings,_that.recipeTitle,_that.recipeServings);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MealPlanEntry extends MealPlanEntry {
  const _MealPlanEntry({required this.id, required this.mealPlanId, required this.entryDate, required this.slot, required this.position, required this.entryKind, this.recipeId, this.leftoverOfEntryId, this.note, this.servings, this.recipeTitle, this.recipeServings}): super._();
  factory _MealPlanEntry.fromJson(Map<String, dynamic> json) => _$MealPlanEntryFromJson(json);

@override final  String id;
@override final  String mealPlanId;
@override final  DateTime entryDate;
@override final  MealSlot slot;
@override final  int position;
@override final  MealEntryKind entryKind;
@override final  String? recipeId;
/// The source entry this is leftovers of, for `entryKind ==
/// MealEntryKind.leftover`. Ships unreachable in migration 14 (D51);
/// Phase 2 part 3 (D55) writes it, and derives [recipeId] onto the row
/// server-side from the source -- never sent by the client -- so a
/// leftover entry's [recipeId] and [recipeTitle] are trustworthy without
/// a join, the same way [recipeId] already is for an `entryKind ==
/// recipe` row.
@override final  String? leftoverOfEntryId;
@override final  String? note;
@override final  int? servings;
/// Resolved, not stored -- see the class doc.
@override final  String? recipeTitle;
@override final  int? recipeServings;

/// Create a copy of MealPlanEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MealPlanEntryCopyWith<_MealPlanEntry> get copyWith => __$MealPlanEntryCopyWithImpl<_MealPlanEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MealPlanEntryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MealPlanEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.mealPlanId, mealPlanId) || other.mealPlanId == mealPlanId)&&(identical(other.entryDate, entryDate) || other.entryDate == entryDate)&&(identical(other.slot, slot) || other.slot == slot)&&(identical(other.position, position) || other.position == position)&&(identical(other.entryKind, entryKind) || other.entryKind == entryKind)&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId)&&(identical(other.leftoverOfEntryId, leftoverOfEntryId) || other.leftoverOfEntryId == leftoverOfEntryId)&&(identical(other.note, note) || other.note == note)&&(identical(other.servings, servings) || other.servings == servings)&&(identical(other.recipeTitle, recipeTitle) || other.recipeTitle == recipeTitle)&&(identical(other.recipeServings, recipeServings) || other.recipeServings == recipeServings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,mealPlanId,entryDate,slot,position,entryKind,recipeId,leftoverOfEntryId,note,servings,recipeTitle,recipeServings);
}

@override
String toString() {
    return 'MealPlanEntry(id: $id, mealPlanId: $mealPlanId, entryDate: $entryDate, slot: $slot, position: $position, entryKind: $entryKind, recipeId: $recipeId, leftoverOfEntryId: $leftoverOfEntryId, note: $note, servings: $servings, recipeTitle: $recipeTitle, recipeServings: $recipeServings)';
}


}

/// @nodoc
abstract mixin class _$MealPlanEntryCopyWith<$Res> implements $MealPlanEntryCopyWith<$Res> {
  factory _$MealPlanEntryCopyWith(_MealPlanEntry value, $Res Function(_MealPlanEntry) _then) = __$MealPlanEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String mealPlanId, DateTime entryDate, MealSlot slot, int position, MealEntryKind entryKind, String? recipeId, String? leftoverOfEntryId, String? note, int? servings, String? recipeTitle, int? recipeServings
});




}
/// @nodoc
class __$MealPlanEntryCopyWithImpl<$Res>
    implements _$MealPlanEntryCopyWith<$Res> {
  __$MealPlanEntryCopyWithImpl(this._self, this._then);

  final _MealPlanEntry _self;
  final $Res Function(_MealPlanEntry) _then;

/// Create a copy of MealPlanEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? mealPlanId = null,Object? entryDate = null,Object? slot = null,Object? position = null,Object? entryKind = null,Object? recipeId = freezed,Object? leftoverOfEntryId = freezed,Object? note = freezed,Object? servings = freezed,Object? recipeTitle = freezed,Object? recipeServings = freezed,}) {
  return _then(_MealPlanEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mealPlanId: null == mealPlanId ? _self.mealPlanId : mealPlanId // ignore: cast_nullable_to_non_nullable
as String,entryDate: null == entryDate ? _self.entryDate : entryDate // ignore: cast_nullable_to_non_nullable
as DateTime,slot: null == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as MealSlot,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,entryKind: null == entryKind ? _self.entryKind : entryKind // ignore: cast_nullable_to_non_nullable
as MealEntryKind,recipeId: freezed == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String?,leftoverOfEntryId: freezed == leftoverOfEntryId ? _self.leftoverOfEntryId : leftoverOfEntryId // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,servings: freezed == servings ? _self.servings : servings // ignore: cast_nullable_to_non_nullable
as int?,recipeTitle: freezed == recipeTitle ? _self.recipeTitle : recipeTitle // ignore: cast_nullable_to_non_nullable
as String?,recipeServings: freezed == recipeServings ? _self.recipeServings : recipeServings // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on

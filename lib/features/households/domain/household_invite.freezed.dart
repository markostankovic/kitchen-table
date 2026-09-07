// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'household_invite.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HouseholdInvite {

 String get id; String get householdId; String get code; String get createdBy; DateTime get createdAt; DateTime get expiresAt; String? get usedBy; DateTime? get usedAt;
/// Create a copy of HouseholdInvite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HouseholdInviteCopyWith<HouseholdInvite> get copyWith => _$HouseholdInviteCopyWithImpl<HouseholdInvite>(this as HouseholdInvite, _$identity);

  /// Serializes this HouseholdInvite to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HouseholdInvite;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HouseholdInvite&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.householdId, _this.householdId) || other.householdId == _this.householdId)&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.usedBy, _this.usedBy) || other.usedBy == _this.usedBy)&&(identical(other.usedAt, _this.usedAt) || other.usedAt == _this.usedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HouseholdInvite;
  return Object.hash(runtimeType,_this.id,_this.householdId,_this.code,_this.createdBy,_this.createdAt,_this.expiresAt,_this.usedBy,_this.usedAt);
}

@override
String toString() {
  final _this = this as HouseholdInvite;
  return 'HouseholdInvite(id: ${_this.id}, householdId: ${_this.householdId}, code: ${_this.code}, createdBy: ${_this.createdBy}, createdAt: ${_this.createdAt}, expiresAt: ${_this.expiresAt}, usedBy: ${_this.usedBy}, usedAt: ${_this.usedAt})';
}


}

/// @nodoc
abstract mixin class $HouseholdInviteCopyWith<$Res>  {
  factory $HouseholdInviteCopyWith(HouseholdInvite value, $Res Function(HouseholdInvite) _then) = _$HouseholdInviteCopyWithImpl;
@useResult
$Res call({
 String id, String householdId, String code, String createdBy, DateTime createdAt, DateTime expiresAt, String? usedBy, DateTime? usedAt
});




}
/// @nodoc
class _$HouseholdInviteCopyWithImpl<$Res>
    implements $HouseholdInviteCopyWith<$Res> {
  _$HouseholdInviteCopyWithImpl(this._self, this._then);

  final HouseholdInvite _self;
  final $Res Function(HouseholdInvite) _then;

/// Create a copy of HouseholdInvite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? householdId = null,Object? code = null,Object? createdBy = null,Object? createdAt = null,Object? expiresAt = null,Object? usedBy = freezed,Object? usedAt = freezed,}) {
  return _then(HouseholdInvite(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,usedBy: freezed == usedBy ? _self.usedBy : usedBy // ignore: cast_nullable_to_non_nullable
as String?,usedAt: freezed == usedAt ? _self.usedAt : usedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [HouseholdInvite].
extension HouseholdInvitePatterns on HouseholdInvite {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HouseholdInvite value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HouseholdInvite() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HouseholdInvite value)  $default,){
final _that = this;
switch (_that) {
case _HouseholdInvite():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HouseholdInvite value)?  $default,){
final _that = this;
switch (_that) {
case _HouseholdInvite() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String householdId,  String code,  String createdBy,  DateTime createdAt,  DateTime expiresAt,  String? usedBy,  DateTime? usedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HouseholdInvite() when $default != null:
return $default(_that.id,_that.householdId,_that.code,_that.createdBy,_that.createdAt,_that.expiresAt,_that.usedBy,_that.usedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String householdId,  String code,  String createdBy,  DateTime createdAt,  DateTime expiresAt,  String? usedBy,  DateTime? usedAt)  $default,) {final _that = this;
switch (_that) {
case _HouseholdInvite():
return $default(_that.id,_that.householdId,_that.code,_that.createdBy,_that.createdAt,_that.expiresAt,_that.usedBy,_that.usedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String householdId,  String code,  String createdBy,  DateTime createdAt,  DateTime expiresAt,  String? usedBy,  DateTime? usedAt)?  $default,) {final _that = this;
switch (_that) {
case _HouseholdInvite() when $default != null:
return $default(_that.id,_that.householdId,_that.code,_that.createdBy,_that.createdAt,_that.expiresAt,_that.usedBy,_that.usedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HouseholdInvite implements HouseholdInvite {
  const _HouseholdInvite({required this.id, required this.householdId, required this.code, required this.createdBy, required this.createdAt, required this.expiresAt, this.usedBy, this.usedAt});
  factory _HouseholdInvite.fromJson(Map<String, dynamic> json) => _$HouseholdInviteFromJson(json);

@override final  String id;
@override final  String householdId;
@override final  String code;
@override final  String createdBy;
@override final  DateTime createdAt;
@override final  DateTime expiresAt;
@override final  String? usedBy;
@override final  DateTime? usedAt;

/// Create a copy of HouseholdInvite
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HouseholdInviteCopyWith<_HouseholdInvite> get copyWith => __$HouseholdInviteCopyWithImpl<_HouseholdInvite>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HouseholdInviteToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HouseholdInvite&&(identical(other.id, id) || other.id == id)&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.code, code) || other.code == code)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.usedBy, usedBy) || other.usedBy == usedBy)&&(identical(other.usedAt, usedAt) || other.usedAt == usedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,householdId,code,createdBy,createdAt,expiresAt,usedBy,usedAt);
}

@override
String toString() {
    return 'HouseholdInvite(id: $id, householdId: $householdId, code: $code, createdBy: $createdBy, createdAt: $createdAt, expiresAt: $expiresAt, usedBy: $usedBy, usedAt: $usedAt)';
}


}

/// @nodoc
abstract mixin class _$HouseholdInviteCopyWith<$Res> implements $HouseholdInviteCopyWith<$Res> {
  factory _$HouseholdInviteCopyWith(_HouseholdInvite value, $Res Function(_HouseholdInvite) _then) = __$HouseholdInviteCopyWithImpl;
@override @useResult
$Res call({
 String id, String householdId, String code, String createdBy, DateTime createdAt, DateTime expiresAt, String? usedBy, DateTime? usedAt
});




}
/// @nodoc
class __$HouseholdInviteCopyWithImpl<$Res>
    implements _$HouseholdInviteCopyWith<$Res> {
  __$HouseholdInviteCopyWithImpl(this._self, this._then);

  final _HouseholdInvite _self;
  final $Res Function(_HouseholdInvite) _then;

/// Create a copy of HouseholdInvite
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? householdId = null,Object? code = null,Object? createdBy = null,Object? createdAt = null,Object? expiresAt = null,Object? usedBy = freezed,Object? usedAt = freezed,}) {
  return _then(_HouseholdInvite(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,usedBy: freezed == usedBy ? _self.usedBy : usedBy // ignore: cast_nullable_to_non_nullable
as String?,usedAt: freezed == usedAt ? _self.usedAt : usedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

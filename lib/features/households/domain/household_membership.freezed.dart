// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'household_membership.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HouseholdMembership {

 Household get household; HouseholdRole get role; int get memberCount;
/// Create a copy of HouseholdMembership
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HouseholdMembershipCopyWith<HouseholdMembership> get copyWith => _$HouseholdMembershipCopyWithImpl<HouseholdMembership>(this as HouseholdMembership, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as HouseholdMembership;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HouseholdMembership&&(identical(other.household, _this.household) || other.household == _this.household)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.memberCount, _this.memberCount) || other.memberCount == _this.memberCount));
}


@override
int get hashCode {
  final _this = this as HouseholdMembership;
  return Object.hash(runtimeType,_this.household,_this.role,_this.memberCount);
}

@override
String toString() {
  final _this = this as HouseholdMembership;
  return 'HouseholdMembership(household: ${_this.household}, role: ${_this.role}, memberCount: ${_this.memberCount})';
}


}

/// @nodoc
abstract mixin class $HouseholdMembershipCopyWith<$Res>  {
  factory $HouseholdMembershipCopyWith(HouseholdMembership value, $Res Function(HouseholdMembership) _then) = _$HouseholdMembershipCopyWithImpl;
@useResult
$Res call({
 Household household, HouseholdRole role, int memberCount
});


$HouseholdCopyWith<$Res> get household;

}
/// @nodoc
class _$HouseholdMembershipCopyWithImpl<$Res>
    implements $HouseholdMembershipCopyWith<$Res> {
  _$HouseholdMembershipCopyWithImpl(this._self, this._then);

  final HouseholdMembership _self;
  final $Res Function(HouseholdMembership) _then;

/// Create a copy of HouseholdMembership
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? household = null,Object? role = null,Object? memberCount = null,}) {
  return _then(HouseholdMembership(
household: null == household ? _self.household : household // ignore: cast_nullable_to_non_nullable
as Household,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as HouseholdRole,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of HouseholdMembership
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HouseholdCopyWith<$Res> get household {
  
  return $HouseholdCopyWith<$Res>(_self.household, (value) {
    return _then(_self.copyWith(household: value));
  });
}
}


/// Adds pattern-matching-related methods to [HouseholdMembership].
extension HouseholdMembershipPatterns on HouseholdMembership {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HouseholdMembership value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HouseholdMembership() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HouseholdMembership value)  $default,){
final _that = this;
switch (_that) {
case _HouseholdMembership():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HouseholdMembership value)?  $default,){
final _that = this;
switch (_that) {
case _HouseholdMembership() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Household household,  HouseholdRole role,  int memberCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HouseholdMembership() when $default != null:
return $default(_that.household,_that.role,_that.memberCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Household household,  HouseholdRole role,  int memberCount)  $default,) {final _that = this;
switch (_that) {
case _HouseholdMembership():
return $default(_that.household,_that.role,_that.memberCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Household household,  HouseholdRole role,  int memberCount)?  $default,) {final _that = this;
switch (_that) {
case _HouseholdMembership() when $default != null:
return $default(_that.household,_that.role,_that.memberCount);case _:
  return null;

}
}

}

/// @nodoc


class _HouseholdMembership implements HouseholdMembership {
  const _HouseholdMembership({required this.household, required this.role, required this.memberCount});
  

@override final  Household household;
@override final  HouseholdRole role;
@override final  int memberCount;

/// Create a copy of HouseholdMembership
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HouseholdMembershipCopyWith<_HouseholdMembership> get copyWith => __$HouseholdMembershipCopyWithImpl<_HouseholdMembership>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HouseholdMembership&&(identical(other.household, household) || other.household == household)&&(identical(other.role, role) || other.role == role)&&(identical(other.memberCount, memberCount) || other.memberCount == memberCount));
}


@override
int get hashCode {
    return Object.hash(runtimeType,household,role,memberCount);
}

@override
String toString() {
    return 'HouseholdMembership(household: $household, role: $role, memberCount: $memberCount)';
}


}

/// @nodoc
abstract mixin class _$HouseholdMembershipCopyWith<$Res> implements $HouseholdMembershipCopyWith<$Res> {
  factory _$HouseholdMembershipCopyWith(_HouseholdMembership value, $Res Function(_HouseholdMembership) _then) = __$HouseholdMembershipCopyWithImpl;
@override @useResult
$Res call({
 Household household, HouseholdRole role, int memberCount
});


@override $HouseholdCopyWith<$Res> get household;

}
/// @nodoc
class __$HouseholdMembershipCopyWithImpl<$Res>
    implements _$HouseholdMembershipCopyWith<$Res> {
  __$HouseholdMembershipCopyWithImpl(this._self, this._then);

  final _HouseholdMembership _self;
  final $Res Function(_HouseholdMembership) _then;

/// Create a copy of HouseholdMembership
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? household = null,Object? role = null,Object? memberCount = null,}) {
  return _then(_HouseholdMembership(
household: null == household ? _self.household : household // ignore: cast_nullable_to_non_nullable
as Household,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as HouseholdRole,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of HouseholdMembership
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HouseholdCopyWith<$Res> get household {
  
  return $HouseholdCopyWith<$Res>(_self.household, (value) {
    return _then(_self.copyWith(household: value));
  });
}
}

// dart format on

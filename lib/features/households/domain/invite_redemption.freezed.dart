// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invite_redemption.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InviteRedemption {

 String get householdId; String get householdName; bool get alreadyMember;
/// Create a copy of InviteRedemption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteRedemptionCopyWith<InviteRedemption> get copyWith => _$InviteRedemptionCopyWithImpl<InviteRedemption>(this as InviteRedemption, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as InviteRedemption;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteRedemption&&(identical(other.householdId, _this.householdId) || other.householdId == _this.householdId)&&(identical(other.householdName, _this.householdName) || other.householdName == _this.householdName)&&(identical(other.alreadyMember, _this.alreadyMember) || other.alreadyMember == _this.alreadyMember));
}


@override
int get hashCode {
  final _this = this as InviteRedemption;
  return Object.hash(runtimeType,_this.householdId,_this.householdName,_this.alreadyMember);
}

@override
String toString() {
  final _this = this as InviteRedemption;
  return 'InviteRedemption(householdId: ${_this.householdId}, householdName: ${_this.householdName}, alreadyMember: ${_this.alreadyMember})';
}


}

/// @nodoc
abstract mixin class $InviteRedemptionCopyWith<$Res>  {
  factory $InviteRedemptionCopyWith(InviteRedemption value, $Res Function(InviteRedemption) _then) = _$InviteRedemptionCopyWithImpl;
@useResult
$Res call({
 String householdId, String householdName, bool alreadyMember
});




}
/// @nodoc
class _$InviteRedemptionCopyWithImpl<$Res>
    implements $InviteRedemptionCopyWith<$Res> {
  _$InviteRedemptionCopyWithImpl(this._self, this._then);

  final InviteRedemption _self;
  final $Res Function(InviteRedemption) _then;

/// Create a copy of InviteRedemption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? householdId = null,Object? householdName = null,Object? alreadyMember = null,}) {
  return _then(InviteRedemption(
householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,householdName: null == householdName ? _self.householdName : householdName // ignore: cast_nullable_to_non_nullable
as String,alreadyMember: null == alreadyMember ? _self.alreadyMember : alreadyMember // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [InviteRedemption].
extension InviteRedemptionPatterns on InviteRedemption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InviteRedemption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InviteRedemption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InviteRedemption value)  $default,){
final _that = this;
switch (_that) {
case _InviteRedemption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InviteRedemption value)?  $default,){
final _that = this;
switch (_that) {
case _InviteRedemption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String householdId,  String householdName,  bool alreadyMember)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InviteRedemption() when $default != null:
return $default(_that.householdId,_that.householdName,_that.alreadyMember);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String householdId,  String householdName,  bool alreadyMember)  $default,) {final _that = this;
switch (_that) {
case _InviteRedemption():
return $default(_that.householdId,_that.householdName,_that.alreadyMember);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String householdId,  String householdName,  bool alreadyMember)?  $default,) {final _that = this;
switch (_that) {
case _InviteRedemption() when $default != null:
return $default(_that.householdId,_that.householdName,_that.alreadyMember);case _:
  return null;

}
}

}

/// @nodoc


class _InviteRedemption implements InviteRedemption {
  const _InviteRedemption({required this.householdId, required this.householdName, required this.alreadyMember});
  

@override final  String householdId;
@override final  String householdName;
@override final  bool alreadyMember;

/// Create a copy of InviteRedemption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InviteRedemptionCopyWith<_InviteRedemption> get copyWith => __$InviteRedemptionCopyWithImpl<_InviteRedemption>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InviteRedemption&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.householdName, householdName) || other.householdName == householdName)&&(identical(other.alreadyMember, alreadyMember) || other.alreadyMember == alreadyMember));
}


@override
int get hashCode {
    return Object.hash(runtimeType,householdId,householdName,alreadyMember);
}

@override
String toString() {
    return 'InviteRedemption(householdId: $householdId, householdName: $householdName, alreadyMember: $alreadyMember)';
}


}

/// @nodoc
abstract mixin class _$InviteRedemptionCopyWith<$Res> implements $InviteRedemptionCopyWith<$Res> {
  factory _$InviteRedemptionCopyWith(_InviteRedemption value, $Res Function(_InviteRedemption) _then) = __$InviteRedemptionCopyWithImpl;
@override @useResult
$Res call({
 String householdId, String householdName, bool alreadyMember
});




}
/// @nodoc
class __$InviteRedemptionCopyWithImpl<$Res>
    implements _$InviteRedemptionCopyWith<$Res> {
  __$InviteRedemptionCopyWithImpl(this._self, this._then);

  final _InviteRedemption _self;
  final $Res Function(_InviteRedemption) _then;

/// Create a copy of InviteRedemption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? householdId = null,Object? householdName = null,Object? alreadyMember = null,}) {
  return _then(_InviteRedemption(
householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,householdName: null == householdName ? _self.householdName : householdName // ignore: cast_nullable_to_non_nullable
as String,alreadyMember: null == alreadyMember ? _self.alreadyMember : alreadyMember // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

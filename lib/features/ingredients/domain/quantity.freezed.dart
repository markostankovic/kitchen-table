// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quantity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Quantity {

 int get numerator; int get denominator; int? get maxNumerator; int? get maxDenominator;
/// Create a copy of Quantity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuantityCopyWith<Quantity> get copyWith => _$QuantityCopyWithImpl<Quantity>(this as Quantity, _$identity);

  /// Serializes this Quantity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Quantity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Quantity&&(identical(other.numerator, _this.numerator) || other.numerator == _this.numerator)&&(identical(other.denominator, _this.denominator) || other.denominator == _this.denominator)&&(identical(other.maxNumerator, _this.maxNumerator) || other.maxNumerator == _this.maxNumerator)&&(identical(other.maxDenominator, _this.maxDenominator) || other.maxDenominator == _this.maxDenominator));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Quantity;
  return Object.hash(runtimeType,_this.numerator,_this.denominator,_this.maxNumerator,_this.maxDenominator);
}



}

/// @nodoc
abstract mixin class $QuantityCopyWith<$Res>  {
  factory $QuantityCopyWith(Quantity value, $Res Function(Quantity) _then) = _$QuantityCopyWithImpl;
@useResult
$Res call({
 int numerator, int denominator, int? maxNumerator, int? maxDenominator
});




}
/// @nodoc
class _$QuantityCopyWithImpl<$Res>
    implements $QuantityCopyWith<$Res> {
  _$QuantityCopyWithImpl(this._self, this._then);

  final Quantity _self;
  final $Res Function(Quantity) _then;

/// Create a copy of Quantity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? numerator = null,Object? denominator = null,Object? maxNumerator = freezed,Object? maxDenominator = freezed,}) {
  return _then(Quantity(
numerator: null == numerator ? _self.numerator : numerator // ignore: cast_nullable_to_non_nullable
as int,denominator: null == denominator ? _self.denominator : denominator // ignore: cast_nullable_to_non_nullable
as int,maxNumerator: freezed == maxNumerator ? _self.maxNumerator : maxNumerator // ignore: cast_nullable_to_non_nullable
as int?,maxDenominator: freezed == maxDenominator ? _self.maxDenominator : maxDenominator // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [Quantity].
extension QuantityPatterns on Quantity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Quantity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Quantity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Quantity value)  $default,){
final _that = this;
switch (_that) {
case _Quantity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Quantity value)?  $default,){
final _that = this;
switch (_that) {
case _Quantity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int numerator,  int denominator,  int? maxNumerator,  int? maxDenominator)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Quantity() when $default != null:
return $default(_that.numerator,_that.denominator,_that.maxNumerator,_that.maxDenominator);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int numerator,  int denominator,  int? maxNumerator,  int? maxDenominator)  $default,) {final _that = this;
switch (_that) {
case _Quantity():
return $default(_that.numerator,_that.denominator,_that.maxNumerator,_that.maxDenominator);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int numerator,  int denominator,  int? maxNumerator,  int? maxDenominator)?  $default,) {final _that = this;
switch (_that) {
case _Quantity() when $default != null:
return $default(_that.numerator,_that.denominator,_that.maxNumerator,_that.maxDenominator);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Quantity extends Quantity {
  const _Quantity({required this.numerator, required this.denominator, this.maxNumerator, this.maxDenominator}): super._();
  factory _Quantity.fromJson(Map<String, dynamic> json) => _$QuantityFromJson(json);

@override final  int numerator;
@override final  int denominator;
@override final  int? maxNumerator;
@override final  int? maxDenominator;

/// Create a copy of Quantity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuantityCopyWith<_Quantity> get copyWith => __$QuantityCopyWithImpl<_Quantity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuantityToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Quantity&&(identical(other.numerator, numerator) || other.numerator == numerator)&&(identical(other.denominator, denominator) || other.denominator == denominator)&&(identical(other.maxNumerator, maxNumerator) || other.maxNumerator == maxNumerator)&&(identical(other.maxDenominator, maxDenominator) || other.maxDenominator == maxDenominator));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,numerator,denominator,maxNumerator,maxDenominator);
}



}

/// @nodoc
abstract mixin class _$QuantityCopyWith<$Res> implements $QuantityCopyWith<$Res> {
  factory _$QuantityCopyWith(_Quantity value, $Res Function(_Quantity) _then) = __$QuantityCopyWithImpl;
@override @useResult
$Res call({
 int numerator, int denominator, int? maxNumerator, int? maxDenominator
});




}
/// @nodoc
class __$QuantityCopyWithImpl<$Res>
    implements _$QuantityCopyWith<$Res> {
  __$QuantityCopyWithImpl(this._self, this._then);

  final _Quantity _self;
  final $Res Function(_Quantity) _then;

/// Create a copy of Quantity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? numerator = null,Object? denominator = null,Object? maxNumerator = freezed,Object? maxDenominator = freezed,}) {
  return _then(_Quantity(
numerator: null == numerator ? _self.numerator : numerator // ignore: cast_nullable_to_non_nullable
as int,denominator: null == denominator ? _self.denominator : denominator // ignore: cast_nullable_to_non_nullable
as int,maxNumerator: freezed == maxNumerator ? _self.maxNumerator : maxNumerator // ignore: cast_nullable_to_non_nullable
as int?,maxDenominator: freezed == maxDenominator ? _self.maxDenominator : maxDenominator // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on

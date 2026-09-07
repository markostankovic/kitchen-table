// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Unit {

 String get code; UnitFamily get family;/// Multiplier to the family's base: grams, millilitres, or one piece.
///
/// A `double`, and deliberately not the integer fraction rule 5 mandates
/// for quantities. This is a conversion constant, not a quantity -- an
/// ounce is 28.349523125 g and no fraction expresses that honestly. The
/// rule exists so a recipe's `1/3 šolje` never becomes 0.3333; nothing
/// here is a recipe's number.
 double get toBase;/// True only for the metric system proper. Only consulted for mass and
/// volume, where the shopping list uses it to choose a display unit.
 bool get isMetric;
/// Create a copy of Unit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnitCopyWith<Unit> get copyWith => _$UnitCopyWithImpl<Unit>(this as Unit, _$identity);

  /// Serializes this Unit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Unit;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Unit&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.family, _this.family) || other.family == _this.family)&&(identical(other.toBase, _this.toBase) || other.toBase == _this.toBase)&&(identical(other.isMetric, _this.isMetric) || other.isMetric == _this.isMetric));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Unit;
  return Object.hash(runtimeType,_this.code,_this.family,_this.toBase,_this.isMetric);
}

@override
String toString() {
  final _this = this as Unit;
  return 'Unit(code: ${_this.code}, family: ${_this.family}, toBase: ${_this.toBase}, isMetric: ${_this.isMetric})';
}


}

/// @nodoc
abstract mixin class $UnitCopyWith<$Res>  {
  factory $UnitCopyWith(Unit value, $Res Function(Unit) _then) = _$UnitCopyWithImpl;
@useResult
$Res call({
 String code, UnitFamily family, double toBase, bool isMetric
});




}
/// @nodoc
class _$UnitCopyWithImpl<$Res>
    implements $UnitCopyWith<$Res> {
  _$UnitCopyWithImpl(this._self, this._then);

  final Unit _self;
  final $Res Function(Unit) _then;

/// Create a copy of Unit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? family = null,Object? toBase = null,Object? isMetric = null,}) {
  return _then(Unit(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,family: null == family ? _self.family : family // ignore: cast_nullable_to_non_nullable
as UnitFamily,toBase: null == toBase ? _self.toBase : toBase // ignore: cast_nullable_to_non_nullable
as double,isMetric: null == isMetric ? _self.isMetric : isMetric // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Unit].
extension UnitPatterns on Unit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Unit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Unit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Unit value)  $default,){
final _that = this;
switch (_that) {
case _Unit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Unit value)?  $default,){
final _that = this;
switch (_that) {
case _Unit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  UnitFamily family,  double toBase,  bool isMetric)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Unit() when $default != null:
return $default(_that.code,_that.family,_that.toBase,_that.isMetric);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  UnitFamily family,  double toBase,  bool isMetric)  $default,) {final _that = this;
switch (_that) {
case _Unit():
return $default(_that.code,_that.family,_that.toBase,_that.isMetric);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  UnitFamily family,  double toBase,  bool isMetric)?  $default,) {final _that = this;
switch (_that) {
case _Unit() when $default != null:
return $default(_that.code,_that.family,_that.toBase,_that.isMetric);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Unit implements Unit {
  const _Unit({required this.code, required this.family, required this.toBase, this.isMetric = false});
  factory _Unit.fromJson(Map<String, dynamic> json) => _$UnitFromJson(json);

@override final  String code;
@override final  UnitFamily family;
/// Multiplier to the family's base: grams, millilitres, or one piece.
///
/// A `double`, and deliberately not the integer fraction rule 5 mandates
/// for quantities. This is a conversion constant, not a quantity -- an
/// ounce is 28.349523125 g and no fraction expresses that honestly. The
/// rule exists so a recipe's `1/3 šolje` never becomes 0.3333; nothing
/// here is a recipe's number.
@override final  double toBase;
/// True only for the metric system proper. Only consulted for mass and
/// volume, where the shopping list uses it to choose a display unit.
@override@JsonKey() final  bool isMetric;

/// Create a copy of Unit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnitCopyWith<_Unit> get copyWith => __$UnitCopyWithImpl<_Unit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UnitToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Unit&&(identical(other.code, code) || other.code == code)&&(identical(other.family, family) || other.family == family)&&(identical(other.toBase, toBase) || other.toBase == toBase)&&(identical(other.isMetric, isMetric) || other.isMetric == isMetric));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,code,family,toBase,isMetric);
}

@override
String toString() {
    return 'Unit(code: $code, family: $family, toBase: $toBase, isMetric: $isMetric)';
}


}

/// @nodoc
abstract mixin class _$UnitCopyWith<$Res> implements $UnitCopyWith<$Res> {
  factory _$UnitCopyWith(_Unit value, $Res Function(_Unit) _then) = __$UnitCopyWithImpl;
@override @useResult
$Res call({
 String code, UnitFamily family, double toBase, bool isMetric
});




}
/// @nodoc
class __$UnitCopyWithImpl<$Res>
    implements _$UnitCopyWith<$Res> {
  __$UnitCopyWithImpl(this._self, this._then);

  final _Unit _self;
  final $Res Function(_Unit) _then;

/// Create a copy of Unit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? family = null,Object? toBase = null,Object? isMetric = null,}) {
  return _then(_Unit(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,family: null == family ? _self.family : family // ignore: cast_nullable_to_non_nullable
as UnitFamily,toBase: null == toBase ? _self.toBase : toBase // ignore: cast_nullable_to_non_nullable
as double,isMetric: null == isMetric ? _self.isMetric : isMetric // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

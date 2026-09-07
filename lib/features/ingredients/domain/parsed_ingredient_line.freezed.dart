// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'parsed_ingredient_line.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ParsedIngredientLine {

 String get rawText; Quantity? get quantity;/// A `units.code`, never a display name.
 String? get unitCode;/// What is left after the quantity and unit, with notes removed.
 String? get name;/// Everything after the first comma, plus any parenthesised text.
 String? get note;/// `opciono`, `po želji`, `optional`, `to taste`.
 bool get isOptional;
/// Create a copy of ParsedIngredientLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParsedIngredientLineCopyWith<ParsedIngredientLine> get copyWith => _$ParsedIngredientLineCopyWithImpl<ParsedIngredientLine>(this as ParsedIngredientLine, _$identity);

  /// Serializes this ParsedIngredientLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ParsedIngredientLine;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParsedIngredientLine&&(identical(other.rawText, _this.rawText) || other.rawText == _this.rawText)&&(identical(other.quantity, _this.quantity) || other.quantity == _this.quantity)&&(identical(other.unitCode, _this.unitCode) || other.unitCode == _this.unitCode)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.isOptional, _this.isOptional) || other.isOptional == _this.isOptional));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ParsedIngredientLine;
  return Object.hash(runtimeType,_this.rawText,_this.quantity,_this.unitCode,_this.name,_this.note,_this.isOptional);
}

@override
String toString() {
  final _this = this as ParsedIngredientLine;
  return 'ParsedIngredientLine(rawText: ${_this.rawText}, quantity: ${_this.quantity}, unitCode: ${_this.unitCode}, name: ${_this.name}, note: ${_this.note}, isOptional: ${_this.isOptional})';
}


}

/// @nodoc
abstract mixin class $ParsedIngredientLineCopyWith<$Res>  {
  factory $ParsedIngredientLineCopyWith(ParsedIngredientLine value, $Res Function(ParsedIngredientLine) _then) = _$ParsedIngredientLineCopyWithImpl;
@useResult
$Res call({
 String rawText, Quantity? quantity, String? unitCode, String? name, String? note, bool isOptional
});


$QuantityCopyWith<$Res>? get quantity;

}
/// @nodoc
class _$ParsedIngredientLineCopyWithImpl<$Res>
    implements $ParsedIngredientLineCopyWith<$Res> {
  _$ParsedIngredientLineCopyWithImpl(this._self, this._then);

  final ParsedIngredientLine _self;
  final $Res Function(ParsedIngredientLine) _then;

/// Create a copy of ParsedIngredientLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rawText = null,Object? quantity = freezed,Object? unitCode = freezed,Object? name = freezed,Object? note = freezed,Object? isOptional = null,}) {
  return _then(ParsedIngredientLine(
rawText: null == rawText ? _self.rawText : rawText // ignore: cast_nullable_to_non_nullable
as String,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as Quantity?,unitCode: freezed == unitCode ? _self.unitCode : unitCode // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,isOptional: null == isOptional ? _self.isOptional : isOptional // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of ParsedIngredientLine
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


/// Adds pattern-matching-related methods to [ParsedIngredientLine].
extension ParsedIngredientLinePatterns on ParsedIngredientLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParsedIngredientLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParsedIngredientLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParsedIngredientLine value)  $default,){
final _that = this;
switch (_that) {
case _ParsedIngredientLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParsedIngredientLine value)?  $default,){
final _that = this;
switch (_that) {
case _ParsedIngredientLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String rawText,  Quantity? quantity,  String? unitCode,  String? name,  String? note,  bool isOptional)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParsedIngredientLine() when $default != null:
return $default(_that.rawText,_that.quantity,_that.unitCode,_that.name,_that.note,_that.isOptional);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String rawText,  Quantity? quantity,  String? unitCode,  String? name,  String? note,  bool isOptional)  $default,) {final _that = this;
switch (_that) {
case _ParsedIngredientLine():
return $default(_that.rawText,_that.quantity,_that.unitCode,_that.name,_that.note,_that.isOptional);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String rawText,  Quantity? quantity,  String? unitCode,  String? name,  String? note,  bool isOptional)?  $default,) {final _that = this;
switch (_that) {
case _ParsedIngredientLine() when $default != null:
return $default(_that.rawText,_that.quantity,_that.unitCode,_that.name,_that.note,_that.isOptional);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ParsedIngredientLine implements ParsedIngredientLine {
  const _ParsedIngredientLine({required this.rawText, this.quantity, this.unitCode, this.name, this.note, this.isOptional = false});
  factory _ParsedIngredientLine.fromJson(Map<String, dynamic> json) => _$ParsedIngredientLineFromJson(json);

@override final  String rawText;
@override final  Quantity? quantity;
/// A `units.code`, never a display name.
@override final  String? unitCode;
/// What is left after the quantity and unit, with notes removed.
@override final  String? name;
/// Everything after the first comma, plus any parenthesised text.
@override final  String? note;
/// `opciono`, `po želji`, `optional`, `to taste`.
@override@JsonKey() final  bool isOptional;

/// Create a copy of ParsedIngredientLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParsedIngredientLineCopyWith<_ParsedIngredientLine> get copyWith => __$ParsedIngredientLineCopyWithImpl<_ParsedIngredientLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ParsedIngredientLineToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParsedIngredientLine&&(identical(other.rawText, rawText) || other.rawText == rawText)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitCode, unitCode) || other.unitCode == unitCode)&&(identical(other.name, name) || other.name == name)&&(identical(other.note, note) || other.note == note)&&(identical(other.isOptional, isOptional) || other.isOptional == isOptional));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,rawText,quantity,unitCode,name,note,isOptional);
}

@override
String toString() {
    return 'ParsedIngredientLine(rawText: $rawText, quantity: $quantity, unitCode: $unitCode, name: $name, note: $note, isOptional: $isOptional)';
}


}

/// @nodoc
abstract mixin class _$ParsedIngredientLineCopyWith<$Res> implements $ParsedIngredientLineCopyWith<$Res> {
  factory _$ParsedIngredientLineCopyWith(_ParsedIngredientLine value, $Res Function(_ParsedIngredientLine) _then) = __$ParsedIngredientLineCopyWithImpl;
@override @useResult
$Res call({
 String rawText, Quantity? quantity, String? unitCode, String? name, String? note, bool isOptional
});


@override $QuantityCopyWith<$Res>? get quantity;

}
/// @nodoc
class __$ParsedIngredientLineCopyWithImpl<$Res>
    implements _$ParsedIngredientLineCopyWith<$Res> {
  __$ParsedIngredientLineCopyWithImpl(this._self, this._then);

  final _ParsedIngredientLine _self;
  final $Res Function(_ParsedIngredientLine) _then;

/// Create a copy of ParsedIngredientLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rawText = null,Object? quantity = freezed,Object? unitCode = freezed,Object? name = freezed,Object? note = freezed,Object? isOptional = null,}) {
  return _then(_ParsedIngredientLine(
rawText: null == rawText ? _self.rawText : rawText // ignore: cast_nullable_to_non_nullable
as String,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as Quantity?,unitCode: freezed == unitCode ? _self.unitCode : unitCode // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,isOptional: null == isOptional ? _self.isOptional : isOptional // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ParsedIngredientLine
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

// dart format on

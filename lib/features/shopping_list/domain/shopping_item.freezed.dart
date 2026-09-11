// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shopping_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ItemQuantity {

 UnitFamily get family;/// Always in the family's base unit, however [unitCode] renders it.
 Rational get amount;/// The `units.code` to display in, chosen at aggregation time.
 String get unitCode;
/// Create a copy of ItemQuantity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemQuantityCopyWith<ItemQuantity> get copyWith => _$ItemQuantityCopyWithImpl<ItemQuantity>(this as ItemQuantity, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ItemQuantity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemQuantity&&(identical(other.family, _this.family) || other.family == _this.family)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.unitCode, _this.unitCode) || other.unitCode == _this.unitCode));
}


@override
int get hashCode {
  final _this = this as ItemQuantity;
  return Object.hash(runtimeType,_this.family,_this.amount,_this.unitCode);
}

@override
String toString() {
  final _this = this as ItemQuantity;
  return 'ItemQuantity(family: ${_this.family}, amount: ${_this.amount}, unitCode: ${_this.unitCode})';
}


}

/// @nodoc
abstract mixin class $ItemQuantityCopyWith<$Res>  {
  factory $ItemQuantityCopyWith(ItemQuantity value, $Res Function(ItemQuantity) _then) = _$ItemQuantityCopyWithImpl;
@useResult
$Res call({
 UnitFamily family, Rational amount, String unitCode
});




}
/// @nodoc
class _$ItemQuantityCopyWithImpl<$Res>
    implements $ItemQuantityCopyWith<$Res> {
  _$ItemQuantityCopyWithImpl(this._self, this._then);

  final ItemQuantity _self;
  final $Res Function(ItemQuantity) _then;

/// Create a copy of ItemQuantity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? family = null,Object? amount = null,Object? unitCode = null,}) {
  return _then(ItemQuantity(
family: null == family ? _self.family : family // ignore: cast_nullable_to_non_nullable
as UnitFamily,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Rational,unitCode: null == unitCode ? _self.unitCode : unitCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ItemQuantity].
extension ItemQuantityPatterns on ItemQuantity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ItemQuantity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ItemQuantity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ItemQuantity value)  $default,){
final _that = this;
switch (_that) {
case _ItemQuantity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ItemQuantity value)?  $default,){
final _that = this;
switch (_that) {
case _ItemQuantity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( UnitFamily family,  Rational amount,  String unitCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ItemQuantity() when $default != null:
return $default(_that.family,_that.amount,_that.unitCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( UnitFamily family,  Rational amount,  String unitCode)  $default,) {final _that = this;
switch (_that) {
case _ItemQuantity():
return $default(_that.family,_that.amount,_that.unitCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( UnitFamily family,  Rational amount,  String unitCode)?  $default,) {final _that = this;
switch (_that) {
case _ItemQuantity() when $default != null:
return $default(_that.family,_that.amount,_that.unitCode);case _:
  return null;

}
}

}

/// @nodoc


class _ItemQuantity extends ItemQuantity {
  const _ItemQuantity({required this.family, required this.amount, required this.unitCode}): super._();
  

@override final  UnitFamily family;
/// Always in the family's base unit, however [unitCode] renders it.
@override final  Rational amount;
/// The `units.code` to display in, chosen at aggregation time.
@override final  String unitCode;

/// Create a copy of ItemQuantity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItemQuantityCopyWith<_ItemQuantity> get copyWith => __$ItemQuantityCopyWithImpl<_ItemQuantity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ItemQuantity&&(identical(other.family, family) || other.family == family)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.unitCode, unitCode) || other.unitCode == unitCode));
}


@override
int get hashCode {
    return Object.hash(runtimeType,family,amount,unitCode);
}

@override
String toString() {
    return 'ItemQuantity(family: $family, amount: $amount, unitCode: $unitCode)';
}


}

/// @nodoc
abstract mixin class _$ItemQuantityCopyWith<$Res> implements $ItemQuantityCopyWith<$Res> {
  factory _$ItemQuantityCopyWith(_ItemQuantity value, $Res Function(_ItemQuantity) _then) = __$ItemQuantityCopyWithImpl;
@override @useResult
$Res call({
 UnitFamily family, Rational amount, String unitCode
});




}
/// @nodoc
class __$ItemQuantityCopyWithImpl<$Res>
    implements _$ItemQuantityCopyWith<$Res> {
  __$ItemQuantityCopyWithImpl(this._self, this._then);

  final _ItemQuantity _self;
  final $Res Function(_ItemQuantity) _then;

/// Create a copy of ItemQuantity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? family = null,Object? amount = null,Object? unitCode = null,}) {
  return _then(_ItemQuantity(
family: null == family ? _self.family : family // ignore: cast_nullable_to_non_nullable
as UnitFamily,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Rational,unitCode: null == unitCode ? _self.unitCode : unitCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ShoppingItem {

/// Null for a line the catalog never matched, which groups by its
/// normalized raw text instead.
 String? get ingredientId; String get displayName; String? get category; bool get isPantryStaple; List<ItemQuantity> get quantities; List<String> get unmatchedLines;
/// Create a copy of ShoppingItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShoppingItemCopyWith<ShoppingItem> get copyWith => _$ShoppingItemCopyWithImpl<ShoppingItem>(this as ShoppingItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ShoppingItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShoppingItem&&(identical(other.ingredientId, _this.ingredientId) || other.ingredientId == _this.ingredientId)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.isPantryStaple, _this.isPantryStaple) || other.isPantryStaple == _this.isPantryStaple)&&const DeepCollectionEquality().equals(other.quantities, _this.quantities)&&const DeepCollectionEquality().equals(other.unmatchedLines, _this.unmatchedLines));
}


@override
int get hashCode {
  final _this = this as ShoppingItem;
  return Object.hash(runtimeType,_this.ingredientId,_this.displayName,_this.category,_this.isPantryStaple,const DeepCollectionEquality().hash(_this.quantities),const DeepCollectionEquality().hash(_this.unmatchedLines));
}

@override
String toString() {
  final _this = this as ShoppingItem;
  return 'ShoppingItem(ingredientId: ${_this.ingredientId}, displayName: ${_this.displayName}, category: ${_this.category}, isPantryStaple: ${_this.isPantryStaple}, quantities: ${_this.quantities}, unmatchedLines: ${_this.unmatchedLines})';
}


}

/// @nodoc
abstract mixin class $ShoppingItemCopyWith<$Res>  {
  factory $ShoppingItemCopyWith(ShoppingItem value, $Res Function(ShoppingItem) _then) = _$ShoppingItemCopyWithImpl;
@useResult
$Res call({
 String? ingredientId, String displayName, String? category, bool isPantryStaple, List<ItemQuantity> quantities, List<String> unmatchedLines
});




}
/// @nodoc
class _$ShoppingItemCopyWithImpl<$Res>
    implements $ShoppingItemCopyWith<$Res> {
  _$ShoppingItemCopyWithImpl(this._self, this._then);

  final ShoppingItem _self;
  final $Res Function(ShoppingItem) _then;

/// Create a copy of ShoppingItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ingredientId = freezed,Object? displayName = null,Object? category = freezed,Object? isPantryStaple = null,Object? quantities = null,Object? unmatchedLines = null,}) {
  return _then(ShoppingItem(
ingredientId: freezed == ingredientId ? _self.ingredientId : ingredientId // ignore: cast_nullable_to_non_nullable
as String?,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,isPantryStaple: null == isPantryStaple ? _self.isPantryStaple : isPantryStaple // ignore: cast_nullable_to_non_nullable
as bool,quantities: null == quantities ? _self.quantities : quantities // ignore: cast_nullable_to_non_nullable
as List<ItemQuantity>,unmatchedLines: null == unmatchedLines ? _self.unmatchedLines : unmatchedLines // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ShoppingItem].
extension ShoppingItemPatterns on ShoppingItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShoppingItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShoppingItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShoppingItem value)  $default,){
final _that = this;
switch (_that) {
case _ShoppingItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShoppingItem value)?  $default,){
final _that = this;
switch (_that) {
case _ShoppingItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? ingredientId,  String displayName,  String? category,  bool isPantryStaple,  List<ItemQuantity> quantities,  List<String> unmatchedLines)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShoppingItem() when $default != null:
return $default(_that.ingredientId,_that.displayName,_that.category,_that.isPantryStaple,_that.quantities,_that.unmatchedLines);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? ingredientId,  String displayName,  String? category,  bool isPantryStaple,  List<ItemQuantity> quantities,  List<String> unmatchedLines)  $default,) {final _that = this;
switch (_that) {
case _ShoppingItem():
return $default(_that.ingredientId,_that.displayName,_that.category,_that.isPantryStaple,_that.quantities,_that.unmatchedLines);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? ingredientId,  String displayName,  String? category,  bool isPantryStaple,  List<ItemQuantity> quantities,  List<String> unmatchedLines)?  $default,) {final _that = this;
switch (_that) {
case _ShoppingItem() when $default != null:
return $default(_that.ingredientId,_that.displayName,_that.category,_that.isPantryStaple,_that.quantities,_that.unmatchedLines);case _:
  return null;

}
}

}

/// @nodoc


class _ShoppingItem extends ShoppingItem {
  const _ShoppingItem({this.ingredientId, required this.displayName, this.category, this.isPantryStaple = false,  List<ItemQuantity> quantities = const <ItemQuantity>[],  List<String> unmatchedLines = const <String>[]}): _quantities = quantities,_unmatchedLines = unmatchedLines,super._();
  

/// Null for a line the catalog never matched, which groups by its
/// normalized raw text instead.
@override final  String? ingredientId;
@override final  String displayName;
@override final  String? category;
@override@JsonKey() final  bool isPantryStaple;
 final  List<ItemQuantity> _quantities;
@override@JsonKey() List<ItemQuantity> get quantities {
  if (_quantities is EqualUnmodifiableListView) return _quantities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_quantities);
}

 final  List<String> _unmatchedLines;
@override@JsonKey() List<String> get unmatchedLines {
  if (_unmatchedLines is EqualUnmodifiableListView) return _unmatchedLines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_unmatchedLines);
}


/// Create a copy of ShoppingItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShoppingItemCopyWith<_ShoppingItem> get copyWith => __$ShoppingItemCopyWithImpl<_ShoppingItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShoppingItem&&(identical(other.ingredientId, ingredientId) || other.ingredientId == ingredientId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.category, category) || other.category == category)&&(identical(other.isPantryStaple, isPantryStaple) || other.isPantryStaple == isPantryStaple)&&const DeepCollectionEquality().equals(other.quantities, _quantities)&&const DeepCollectionEquality().equals(other.unmatchedLines, _unmatchedLines));
}


@override
int get hashCode {
    return Object.hash(runtimeType,ingredientId,displayName,category,isPantryStaple,const DeepCollectionEquality().hash(_quantities),const DeepCollectionEquality().hash(_unmatchedLines));
}

@override
String toString() {
    return 'ShoppingItem(ingredientId: $ingredientId, displayName: $displayName, category: $category, isPantryStaple: $isPantryStaple, quantities: $quantities, unmatchedLines: $unmatchedLines)';
}


}

/// @nodoc
abstract mixin class _$ShoppingItemCopyWith<$Res> implements $ShoppingItemCopyWith<$Res> {
  factory _$ShoppingItemCopyWith(_ShoppingItem value, $Res Function(_ShoppingItem) _then) = __$ShoppingItemCopyWithImpl;
@override @useResult
$Res call({
 String? ingredientId, String displayName, String? category, bool isPantryStaple, List<ItemQuantity> quantities, List<String> unmatchedLines
});




}
/// @nodoc
class __$ShoppingItemCopyWithImpl<$Res>
    implements _$ShoppingItemCopyWith<$Res> {
  __$ShoppingItemCopyWithImpl(this._self, this._then);

  final _ShoppingItem _self;
  final $Res Function(_ShoppingItem) _then;

/// Create a copy of ShoppingItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ingredientId = freezed,Object? displayName = null,Object? category = freezed,Object? isPantryStaple = null,Object? quantities = null,Object? unmatchedLines = null,}) {
  return _then(_ShoppingItem(
ingredientId: freezed == ingredientId ? _self.ingredientId : ingredientId // ignore: cast_nullable_to_non_nullable
as String?,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,isPantryStaple: null == isPantryStaple ? _self.isPantryStaple : isPantryStaple // ignore: cast_nullable_to_non_nullable
as bool,quantities: null == quantities ? _self._quantities : quantities // ignore: cast_nullable_to_non_nullable
as List<ItemQuantity>,unmatchedLines: null == unmatchedLines ? _self._unmatchedLines : unmatchedLines // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on

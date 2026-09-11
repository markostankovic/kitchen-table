// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shopping_list.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShoppingList {

 String get id; DateTime get dateFrom; DateTime get dateTo; String get locale; DateTime get generatedAt; String? get mealPlanId; List<ShoppingItem> get items;
/// Create a copy of ShoppingList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShoppingListCopyWith<ShoppingList> get copyWith => _$ShoppingListCopyWithImpl<ShoppingList>(this as ShoppingList, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ShoppingList;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShoppingList&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.dateFrom, _this.dateFrom) || other.dateFrom == _this.dateFrom)&&(identical(other.dateTo, _this.dateTo) || other.dateTo == _this.dateTo)&&(identical(other.locale, _this.locale) || other.locale == _this.locale)&&(identical(other.generatedAt, _this.generatedAt) || other.generatedAt == _this.generatedAt)&&(identical(other.mealPlanId, _this.mealPlanId) || other.mealPlanId == _this.mealPlanId)&&const DeepCollectionEquality().equals(other.items, _this.items));
}


@override
int get hashCode {
  final _this = this as ShoppingList;
  return Object.hash(runtimeType,_this.id,_this.dateFrom,_this.dateTo,_this.locale,_this.generatedAt,_this.mealPlanId,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as ShoppingList;
  return 'ShoppingList(id: ${_this.id}, dateFrom: ${_this.dateFrom}, dateTo: ${_this.dateTo}, locale: ${_this.locale}, generatedAt: ${_this.generatedAt}, mealPlanId: ${_this.mealPlanId}, items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $ShoppingListCopyWith<$Res>  {
  factory $ShoppingListCopyWith(ShoppingList value, $Res Function(ShoppingList) _then) = _$ShoppingListCopyWithImpl;
@useResult
$Res call({
 String id, DateTime dateFrom, DateTime dateTo, String locale, DateTime generatedAt, String? mealPlanId, List<ShoppingItem> items
});




}
/// @nodoc
class _$ShoppingListCopyWithImpl<$Res>
    implements $ShoppingListCopyWith<$Res> {
  _$ShoppingListCopyWithImpl(this._self, this._then);

  final ShoppingList _self;
  final $Res Function(ShoppingList) _then;

/// Create a copy of ShoppingList
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? dateFrom = null,Object? dateTo = null,Object? locale = null,Object? generatedAt = null,Object? mealPlanId = freezed,Object? items = null,}) {
  return _then(ShoppingList(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,dateFrom: null == dateFrom ? _self.dateFrom : dateFrom // ignore: cast_nullable_to_non_nullable
as DateTime,dateTo: null == dateTo ? _self.dateTo : dateTo // ignore: cast_nullable_to_non_nullable
as DateTime,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,mealPlanId: freezed == mealPlanId ? _self.mealPlanId : mealPlanId // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ShoppingItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [ShoppingList].
extension ShoppingListPatterns on ShoppingList {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShoppingList value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShoppingList() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShoppingList value)  $default,){
final _that = this;
switch (_that) {
case _ShoppingList():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShoppingList value)?  $default,){
final _that = this;
switch (_that) {
case _ShoppingList() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime dateFrom,  DateTime dateTo,  String locale,  DateTime generatedAt,  String? mealPlanId,  List<ShoppingItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShoppingList() when $default != null:
return $default(_that.id,_that.dateFrom,_that.dateTo,_that.locale,_that.generatedAt,_that.mealPlanId,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime dateFrom,  DateTime dateTo,  String locale,  DateTime generatedAt,  String? mealPlanId,  List<ShoppingItem> items)  $default,) {final _that = this;
switch (_that) {
case _ShoppingList():
return $default(_that.id,_that.dateFrom,_that.dateTo,_that.locale,_that.generatedAt,_that.mealPlanId,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime dateFrom,  DateTime dateTo,  String locale,  DateTime generatedAt,  String? mealPlanId,  List<ShoppingItem> items)?  $default,) {final _that = this;
switch (_that) {
case _ShoppingList() when $default != null:
return $default(_that.id,_that.dateFrom,_that.dateTo,_that.locale,_that.generatedAt,_that.mealPlanId,_that.items);case _:
  return null;

}
}

}

/// @nodoc


class _ShoppingList extends ShoppingList {
  const _ShoppingList({required this.id, required this.dateFrom, required this.dateTo, required this.locale, required this.generatedAt, this.mealPlanId,  List<ShoppingItem> items = const <ShoppingItem>[]}): _items = items,super._();
  

@override final  String id;
@override final  DateTime dateFrom;
@override final  DateTime dateTo;
@override final  String locale;
@override final  DateTime generatedAt;
@override final  String? mealPlanId;
 final  List<ShoppingItem> _items;
@override@JsonKey() List<ShoppingItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of ShoppingList
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShoppingListCopyWith<_ShoppingList> get copyWith => __$ShoppingListCopyWithImpl<_ShoppingList>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShoppingList&&(identical(other.id, id) || other.id == id)&&(identical(other.dateFrom, dateFrom) || other.dateFrom == dateFrom)&&(identical(other.dateTo, dateTo) || other.dateTo == dateTo)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.mealPlanId, mealPlanId) || other.mealPlanId == mealPlanId)&&const DeepCollectionEquality().equals(other.items, _items));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,dateFrom,dateTo,locale,generatedAt,mealPlanId,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'ShoppingList(id: $id, dateFrom: $dateFrom, dateTo: $dateTo, locale: $locale, generatedAt: $generatedAt, mealPlanId: $mealPlanId, items: $items)';
}


}

/// @nodoc
abstract mixin class _$ShoppingListCopyWith<$Res> implements $ShoppingListCopyWith<$Res> {
  factory _$ShoppingListCopyWith(_ShoppingList value, $Res Function(_ShoppingList) _then) = __$ShoppingListCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime dateFrom, DateTime dateTo, String locale, DateTime generatedAt, String? mealPlanId, List<ShoppingItem> items
});




}
/// @nodoc
class __$ShoppingListCopyWithImpl<$Res>
    implements _$ShoppingListCopyWith<$Res> {
  __$ShoppingListCopyWithImpl(this._self, this._then);

  final _ShoppingList _self;
  final $Res Function(_ShoppingList) _then;

/// Create a copy of ShoppingList
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? dateFrom = null,Object? dateTo = null,Object? locale = null,Object? generatedAt = null,Object? mealPlanId = freezed,Object? items = null,}) {
  return _then(_ShoppingList(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,dateFrom: null == dateFrom ? _self.dateFrom : dateFrom // ignore: cast_nullable_to_non_nullable
as DateTime,dateTo: null == dateTo ? _self.dateTo : dateTo // ignore: cast_nullable_to_non_nullable
as DateTime,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,mealPlanId: freezed == mealPlanId ? _self.mealPlanId : mealPlanId // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ShoppingItem>,
  ));
}


}

// dart format on

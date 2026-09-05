// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sale_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SaleModel {

 String get id;@TimestampConverter() DateTime get sellDate; int get sharesSold; double get sellPricePerShare;
/// Create a copy of SaleModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaleModelCopyWith<SaleModel> get copyWith => _$SaleModelCopyWithImpl<SaleModel>(this as SaleModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.sellDate, sellDate) || other.sellDate == sellDate)&&(identical(other.sharesSold, sharesSold) || other.sharesSold == sharesSold)&&(identical(other.sellPricePerShare, sellPricePerShare) || other.sellPricePerShare == sellPricePerShare));
}


@override
int get hashCode => Object.hash(runtimeType,id,sellDate,sharesSold,sellPricePerShare);

@override
String toString() {
  return 'SaleModel(id: $id, sellDate: $sellDate, sharesSold: $sharesSold, sellPricePerShare: $sellPricePerShare)';
}


}

/// @nodoc
abstract mixin class $SaleModelCopyWith<$Res>  {
  factory $SaleModelCopyWith(SaleModel value, $Res Function(SaleModel) _then) = _$SaleModelCopyWithImpl;
@useResult
$Res call({
 String id,@TimestampConverter() DateTime sellDate, int sharesSold, double sellPricePerShare
});




}
/// @nodoc
class _$SaleModelCopyWithImpl<$Res>
    implements $SaleModelCopyWith<$Res> {
  _$SaleModelCopyWithImpl(this._self, this._then);

  final SaleModel _self;
  final $Res Function(SaleModel) _then;

/// Create a copy of SaleModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sellDate = null,Object? sharesSold = null,Object? sellPricePerShare = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sellDate: null == sellDate ? _self.sellDate : sellDate // ignore: cast_nullable_to_non_nullable
as DateTime,sharesSold: null == sharesSold ? _self.sharesSold : sharesSold // ignore: cast_nullable_to_non_nullable
as int,sellPricePerShare: null == sellPricePerShare ? _self.sellPricePerShare : sellPricePerShare // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [SaleModel].
extension SaleModelPatterns on SaleModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SaleModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SaleModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SaleModel value)  $default,){
final _that = this;
switch (_that) {
case _SaleModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SaleModel value)?  $default,){
final _that = this;
switch (_that) {
case _SaleModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @TimestampConverter()  DateTime sellDate,  int sharesSold,  double sellPricePerShare)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SaleModel() when $default != null:
return $default(_that.id,_that.sellDate,_that.sharesSold,_that.sellPricePerShare);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @TimestampConverter()  DateTime sellDate,  int sharesSold,  double sellPricePerShare)  $default,) {final _that = this;
switch (_that) {
case _SaleModel():
return $default(_that.id,_that.sellDate,_that.sharesSold,_that.sellPricePerShare);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @TimestampConverter()  DateTime sellDate,  int sharesSold,  double sellPricePerShare)?  $default,) {final _that = this;
switch (_that) {
case _SaleModel() when $default != null:
return $default(_that.id,_that.sellDate,_that.sharesSold,_that.sellPricePerShare);case _:
  return null;

}
}

}

/// @nodoc


class _SaleModel implements SaleModel {
  const _SaleModel({required this.id, @TimestampConverter() required this.sellDate, required this.sharesSold, required this.sellPricePerShare});
  

@override final  String id;
@override@TimestampConverter() final  DateTime sellDate;
@override final  int sharesSold;
@override final  double sellPricePerShare;

/// Create a copy of SaleModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SaleModelCopyWith<_SaleModel> get copyWith => __$SaleModelCopyWithImpl<_SaleModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SaleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.sellDate, sellDate) || other.sellDate == sellDate)&&(identical(other.sharesSold, sharesSold) || other.sharesSold == sharesSold)&&(identical(other.sellPricePerShare, sellPricePerShare) || other.sellPricePerShare == sellPricePerShare));
}


@override
int get hashCode => Object.hash(runtimeType,id,sellDate,sharesSold,sellPricePerShare);

@override
String toString() {
  return 'SaleModel(id: $id, sellDate: $sellDate, sharesSold: $sharesSold, sellPricePerShare: $sellPricePerShare)';
}


}

/// @nodoc
abstract mixin class _$SaleModelCopyWith<$Res> implements $SaleModelCopyWith<$Res> {
  factory _$SaleModelCopyWith(_SaleModel value, $Res Function(_SaleModel) _then) = __$SaleModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@TimestampConverter() DateTime sellDate, int sharesSold, double sellPricePerShare
});




}
/// @nodoc
class __$SaleModelCopyWithImpl<$Res>
    implements _$SaleModelCopyWith<$Res> {
  __$SaleModelCopyWithImpl(this._self, this._then);

  final _SaleModel _self;
  final $Res Function(_SaleModel) _then;

/// Create a copy of SaleModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sellDate = null,Object? sharesSold = null,Object? sellPricePerShare = null,}) {
  return _then(_SaleModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sellDate: null == sellDate ? _self.sellDate : sellDate // ignore: cast_nullable_to_non_nullable
as DateTime,sharesSold: null == sharesSold ? _self.sharesSold : sharesSold // ignore: cast_nullable_to_non_nullable
as int,sellPricePerShare: null == sellPricePerShare ? _self.sellPricePerShare : sellPricePerShare // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on

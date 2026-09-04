// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'market_price_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MarketPriceModel {

 String get ticker; double get price; double get previousClose; DateTime get updatedAt;
/// Create a copy of MarketPriceModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarketPriceModelCopyWith<MarketPriceModel> get copyWith => _$MarketPriceModelCopyWithImpl<MarketPriceModel>(this as MarketPriceModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarketPriceModel&&(identical(other.ticker, ticker) || other.ticker == ticker)&&(identical(other.price, price) || other.price == price)&&(identical(other.previousClose, previousClose) || other.previousClose == previousClose)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,ticker,price,previousClose,updatedAt);

@override
String toString() {
  return 'MarketPriceModel(ticker: $ticker, price: $price, previousClose: $previousClose, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $MarketPriceModelCopyWith<$Res>  {
  factory $MarketPriceModelCopyWith(MarketPriceModel value, $Res Function(MarketPriceModel) _then) = _$MarketPriceModelCopyWithImpl;
@useResult
$Res call({
 String ticker, double price, double previousClose, DateTime updatedAt
});




}
/// @nodoc
class _$MarketPriceModelCopyWithImpl<$Res>
    implements $MarketPriceModelCopyWith<$Res> {
  _$MarketPriceModelCopyWithImpl(this._self, this._then);

  final MarketPriceModel _self;
  final $Res Function(MarketPriceModel) _then;

/// Create a copy of MarketPriceModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ticker = null,Object? price = null,Object? previousClose = null,Object? updatedAt = null,}) {
  return _then(MarketPriceModel(
ticker: null == ticker ? _self.ticker : ticker // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,previousClose: null == previousClose ? _self.previousClose : previousClose // ignore: cast_nullable_to_non_nullable
as double,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MarketPriceModel].
extension MarketPriceModelPatterns on MarketPriceModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MarketPriceModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MarketPriceModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MarketPriceModel value)  $default,){
final _that = this;
switch (_that) {
case _MarketPriceModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MarketPriceModel value)?  $default,){
final _that = this;
switch (_that) {
case _MarketPriceModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String ticker,  double price,  double previousClose,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MarketPriceModel() when $default != null:
return $default(_that.ticker,_that.price,_that.previousClose,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String ticker,  double price,  double previousClose,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _MarketPriceModel():
return $default(_that.ticker,_that.price,_that.previousClose,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String ticker,  double price,  double previousClose,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _MarketPriceModel() when $default != null:
return $default(_that.ticker,_that.price,_that.previousClose,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _MarketPriceModel implements MarketPriceModel {
  const _MarketPriceModel({required this.ticker, required this.price, required this.previousClose, required this.updatedAt});
  

@override final  String ticker;
@override final  double price;
@override final  double previousClose;
@override final  DateTime updatedAt;

/// Create a copy of MarketPriceModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MarketPriceModelCopyWith<_MarketPriceModel> get copyWith => __$MarketPriceModelCopyWithImpl<_MarketPriceModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MarketPriceModel&&(identical(other.ticker, ticker) || other.ticker == ticker)&&(identical(other.price, price) || other.price == price)&&(identical(other.previousClose, previousClose) || other.previousClose == previousClose)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,ticker,price,previousClose,updatedAt);

@override
String toString() {
  return 'MarketPriceModel(ticker: $ticker, price: $price, previousClose: $previousClose, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$MarketPriceModelCopyWith<$Res> implements $MarketPriceModelCopyWith<$Res> {
  factory _$MarketPriceModelCopyWith(_MarketPriceModel value, $Res Function(_MarketPriceModel) _then) = __$MarketPriceModelCopyWithImpl;
@override @useResult
$Res call({
 String ticker, double price, double previousClose, DateTime updatedAt
});




}
/// @nodoc
class __$MarketPriceModelCopyWithImpl<$Res>
    implements _$MarketPriceModelCopyWith<$Res> {
  __$MarketPriceModelCopyWithImpl(this._self, this._then);

  final _MarketPriceModel _self;
  final $Res Function(_MarketPriceModel) _then;

/// Create a copy of MarketPriceModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ticker = null,Object? price = null,Object? previousClose = null,Object? updatedAt = null,}) {
  return _then(_MarketPriceModel(
ticker: null == ticker ? _self.ticker : ticker // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,previousClose: null == previousClose ? _self.previousClose : previousClose // ignore: cast_nullable_to_non_nullable
as double,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lot_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LotModel {

 String get id; String get ticker;@TimestampConverter() DateTime get buyDate; int get sharesPurchased; double get buyPricePerShare; List<SaleModel> get sales;
/// Create a copy of LotModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LotModelCopyWith<LotModel> get copyWith => _$LotModelCopyWithImpl<LotModel>(this as LotModel, _$identity);

  /// Serializes this LotModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LotModel&&(identical(other.id, id) || other.id == id)&&(identical(other.ticker, ticker) || other.ticker == ticker)&&(identical(other.buyDate, buyDate) || other.buyDate == buyDate)&&(identical(other.sharesPurchased, sharesPurchased) || other.sharesPurchased == sharesPurchased)&&(identical(other.buyPricePerShare, buyPricePerShare) || other.buyPricePerShare == buyPricePerShare)&&const DeepCollectionEquality().equals(other.sales, sales));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ticker,buyDate,sharesPurchased,buyPricePerShare,const DeepCollectionEquality().hash(sales));

@override
String toString() {
  return 'LotModel(id: $id, ticker: $ticker, buyDate: $buyDate, sharesPurchased: $sharesPurchased, buyPricePerShare: $buyPricePerShare, sales: $sales)';
}


}

/// @nodoc
abstract mixin class $LotModelCopyWith<$Res>  {
  factory $LotModelCopyWith(LotModel value, $Res Function(LotModel) _then) = _$LotModelCopyWithImpl;
@useResult
$Res call({
 String id, String ticker,@TimestampConverter() DateTime buyDate, int sharesPurchased, double buyPricePerShare, List<SaleModel> sales
});




}
/// @nodoc
class _$LotModelCopyWithImpl<$Res>
    implements $LotModelCopyWith<$Res> {
  _$LotModelCopyWithImpl(this._self, this._then);

  final LotModel _self;
  final $Res Function(LotModel) _then;

/// Create a copy of LotModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ticker = null,Object? buyDate = null,Object? sharesPurchased = null,Object? buyPricePerShare = null,Object? sales = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ticker: null == ticker ? _self.ticker : ticker // ignore: cast_nullable_to_non_nullable
as String,buyDate: null == buyDate ? _self.buyDate : buyDate // ignore: cast_nullable_to_non_nullable
as DateTime,sharesPurchased: null == sharesPurchased ? _self.sharesPurchased : sharesPurchased // ignore: cast_nullable_to_non_nullable
as int,buyPricePerShare: null == buyPricePerShare ? _self.buyPricePerShare : buyPricePerShare // ignore: cast_nullable_to_non_nullable
as double,sales: null == sales ? _self.sales : sales // ignore: cast_nullable_to_non_nullable
as List<SaleModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [LotModel].
extension LotModelPatterns on LotModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LotModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LotModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LotModel value)  $default,){
final _that = this;
switch (_that) {
case _LotModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LotModel value)?  $default,){
final _that = this;
switch (_that) {
case _LotModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String ticker, @TimestampConverter()  DateTime buyDate,  int sharesPurchased,  double buyPricePerShare,  List<SaleModel> sales)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LotModel() when $default != null:
return $default(_that.id,_that.ticker,_that.buyDate,_that.sharesPurchased,_that.buyPricePerShare,_that.sales);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String ticker, @TimestampConverter()  DateTime buyDate,  int sharesPurchased,  double buyPricePerShare,  List<SaleModel> sales)  $default,) {final _that = this;
switch (_that) {
case _LotModel():
return $default(_that.id,_that.ticker,_that.buyDate,_that.sharesPurchased,_that.buyPricePerShare,_that.sales);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String ticker, @TimestampConverter()  DateTime buyDate,  int sharesPurchased,  double buyPricePerShare,  List<SaleModel> sales)?  $default,) {final _that = this;
switch (_that) {
case _LotModel() when $default != null:
return $default(_that.id,_that.ticker,_that.buyDate,_that.sharesPurchased,_that.buyPricePerShare,_that.sales);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _LotModel implements LotModel {
  const _LotModel({required this.id, required this.ticker, @TimestampConverter() required this.buyDate, required this.sharesPurchased, required this.buyPricePerShare, final  List<SaleModel> sales = const []}): _sales = sales;
  factory _LotModel.fromJson(Map<String, dynamic> json) => _$LotModelFromJson(json);

@override final  String id;
@override final  String ticker;
@override@TimestampConverter() final  DateTime buyDate;
@override final  int sharesPurchased;
@override final  double buyPricePerShare;
 final  List<SaleModel> _sales;
@override@JsonKey() List<SaleModel> get sales {
  if (_sales is EqualUnmodifiableListView) return _sales;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sales);
}


/// Create a copy of LotModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LotModelCopyWith<_LotModel> get copyWith => __$LotModelCopyWithImpl<_LotModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LotModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LotModel&&(identical(other.id, id) || other.id == id)&&(identical(other.ticker, ticker) || other.ticker == ticker)&&(identical(other.buyDate, buyDate) || other.buyDate == buyDate)&&(identical(other.sharesPurchased, sharesPurchased) || other.sharesPurchased == sharesPurchased)&&(identical(other.buyPricePerShare, buyPricePerShare) || other.buyPricePerShare == buyPricePerShare)&&const DeepCollectionEquality().equals(other._sales, _sales));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ticker,buyDate,sharesPurchased,buyPricePerShare,const DeepCollectionEquality().hash(_sales));

@override
String toString() {
  return 'LotModel(id: $id, ticker: $ticker, buyDate: $buyDate, sharesPurchased: $sharesPurchased, buyPricePerShare: $buyPricePerShare, sales: $sales)';
}


}

/// @nodoc
abstract mixin class _$LotModelCopyWith<$Res> implements $LotModelCopyWith<$Res> {
  factory _$LotModelCopyWith(_LotModel value, $Res Function(_LotModel) _then) = __$LotModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String ticker,@TimestampConverter() DateTime buyDate, int sharesPurchased, double buyPricePerShare, List<SaleModel> sales
});




}
/// @nodoc
class __$LotModelCopyWithImpl<$Res>
    implements _$LotModelCopyWith<$Res> {
  __$LotModelCopyWithImpl(this._self, this._then);

  final _LotModel _self;
  final $Res Function(_LotModel) _then;

/// Create a copy of LotModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ticker = null,Object? buyDate = null,Object? sharesPurchased = null,Object? buyPricePerShare = null,Object? sales = null,}) {
  return _then(_LotModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ticker: null == ticker ? _self.ticker : ticker // ignore: cast_nullable_to_non_nullable
as String,buyDate: null == buyDate ? _self.buyDate : buyDate // ignore: cast_nullable_to_non_nullable
as DateTime,sharesPurchased: null == sharesPurchased ? _self.sharesPurchased : sharesPurchased // ignore: cast_nullable_to_non_nullable
as int,buyPricePerShare: null == buyPricePerShare ? _self.buyPricePerShare : buyPricePerShare // ignore: cast_nullable_to_non_nullable
as double,sales: null == sales ? _self._sales : sales // ignore: cast_nullable_to_non_nullable
as List<SaleModel>,
  ));
}


}

// dart format on

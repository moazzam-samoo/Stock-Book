// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'position_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PositionBuyModel {

 String get id;@TimestampConverter() DateTime get date; int get shares; double get pricePerShare;
/// Create a copy of PositionBuyModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PositionBuyModelCopyWith<PositionBuyModel> get copyWith => _$PositionBuyModelCopyWithImpl<PositionBuyModel>(this as PositionBuyModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PositionBuyModel&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.shares, shares) || other.shares == shares)&&(identical(other.pricePerShare, pricePerShare) || other.pricePerShare == pricePerShare));
}


@override
int get hashCode => Object.hash(runtimeType,id,date,shares,pricePerShare);

@override
String toString() {
  return 'PositionBuyModel(id: $id, date: $date, shares: $shares, pricePerShare: $pricePerShare)';
}


}

/// @nodoc
abstract mixin class $PositionBuyModelCopyWith<$Res>  {
  factory $PositionBuyModelCopyWith(PositionBuyModel value, $Res Function(PositionBuyModel) _then) = _$PositionBuyModelCopyWithImpl;
@useResult
$Res call({
 String id,@TimestampConverter() DateTime date, int shares, double pricePerShare
});




}
/// @nodoc
class _$PositionBuyModelCopyWithImpl<$Res>
    implements $PositionBuyModelCopyWith<$Res> {
  _$PositionBuyModelCopyWithImpl(this._self, this._then);

  final PositionBuyModel _self;
  final $Res Function(PositionBuyModel) _then;

/// Create a copy of PositionBuyModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? date = null,Object? shares = null,Object? pricePerShare = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,shares: null == shares ? _self.shares : shares // ignore: cast_nullable_to_non_nullable
as int,pricePerShare: null == pricePerShare ? _self.pricePerShare : pricePerShare // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [PositionBuyModel].
extension PositionBuyModelPatterns on PositionBuyModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PositionBuyModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PositionBuyModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PositionBuyModel value)  $default,){
final _that = this;
switch (_that) {
case _PositionBuyModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PositionBuyModel value)?  $default,){
final _that = this;
switch (_that) {
case _PositionBuyModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @TimestampConverter()  DateTime date,  int shares,  double pricePerShare)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PositionBuyModel() when $default != null:
return $default(_that.id,_that.date,_that.shares,_that.pricePerShare);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @TimestampConverter()  DateTime date,  int shares,  double pricePerShare)  $default,) {final _that = this;
switch (_that) {
case _PositionBuyModel():
return $default(_that.id,_that.date,_that.shares,_that.pricePerShare);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @TimestampConverter()  DateTime date,  int shares,  double pricePerShare)?  $default,) {final _that = this;
switch (_that) {
case _PositionBuyModel() when $default != null:
return $default(_that.id,_that.date,_that.shares,_that.pricePerShare);case _:
  return null;

}
}

}

/// @nodoc


class _PositionBuyModel implements PositionBuyModel {
  const _PositionBuyModel({required this.id, @TimestampConverter() required this.date, required this.shares, required this.pricePerShare});
  

@override final  String id;
@override@TimestampConverter() final  DateTime date;
@override final  int shares;
@override final  double pricePerShare;

/// Create a copy of PositionBuyModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PositionBuyModelCopyWith<_PositionBuyModel> get copyWith => __$PositionBuyModelCopyWithImpl<_PositionBuyModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PositionBuyModel&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.shares, shares) || other.shares == shares)&&(identical(other.pricePerShare, pricePerShare) || other.pricePerShare == pricePerShare));
}


@override
int get hashCode => Object.hash(runtimeType,id,date,shares,pricePerShare);

@override
String toString() {
  return 'PositionBuyModel(id: $id, date: $date, shares: $shares, pricePerShare: $pricePerShare)';
}


}

/// @nodoc
abstract mixin class _$PositionBuyModelCopyWith<$Res> implements $PositionBuyModelCopyWith<$Res> {
  factory _$PositionBuyModelCopyWith(_PositionBuyModel value, $Res Function(_PositionBuyModel) _then) = __$PositionBuyModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@TimestampConverter() DateTime date, int shares, double pricePerShare
});




}
/// @nodoc
class __$PositionBuyModelCopyWithImpl<$Res>
    implements _$PositionBuyModelCopyWith<$Res> {
  __$PositionBuyModelCopyWithImpl(this._self, this._then);

  final _PositionBuyModel _self;
  final $Res Function(_PositionBuyModel) _then;

/// Create a copy of PositionBuyModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? date = null,Object? shares = null,Object? pricePerShare = null,}) {
  return _then(_PositionBuyModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,shares: null == shares ? _self.shares : shares // ignore: cast_nullable_to_non_nullable
as int,pricePerShare: null == pricePerShare ? _self.pricePerShare : pricePerShare // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$PositionSaleModel {

 String get id;@TimestampConverter() DateTime get date; int get shares; double get pricePerShare; double? get costBasisAtSale;
/// Create a copy of PositionSaleModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PositionSaleModelCopyWith<PositionSaleModel> get copyWith => _$PositionSaleModelCopyWithImpl<PositionSaleModel>(this as PositionSaleModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PositionSaleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.shares, shares) || other.shares == shares)&&(identical(other.pricePerShare, pricePerShare) || other.pricePerShare == pricePerShare)&&(identical(other.costBasisAtSale, costBasisAtSale) || other.costBasisAtSale == costBasisAtSale));
}


@override
int get hashCode => Object.hash(runtimeType,id,date,shares,pricePerShare,costBasisAtSale);

@override
String toString() {
  return 'PositionSaleModel(id: $id, date: $date, shares: $shares, pricePerShare: $pricePerShare, costBasisAtSale: $costBasisAtSale)';
}


}

/// @nodoc
abstract mixin class $PositionSaleModelCopyWith<$Res>  {
  factory $PositionSaleModelCopyWith(PositionSaleModel value, $Res Function(PositionSaleModel) _then) = _$PositionSaleModelCopyWithImpl;
@useResult
$Res call({
 String id,@TimestampConverter() DateTime date, int shares, double pricePerShare, double? costBasisAtSale
});




}
/// @nodoc
class _$PositionSaleModelCopyWithImpl<$Res>
    implements $PositionSaleModelCopyWith<$Res> {
  _$PositionSaleModelCopyWithImpl(this._self, this._then);

  final PositionSaleModel _self;
  final $Res Function(PositionSaleModel) _then;

/// Create a copy of PositionSaleModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? date = null,Object? shares = null,Object? pricePerShare = null,Object? costBasisAtSale = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,shares: null == shares ? _self.shares : shares // ignore: cast_nullable_to_non_nullable
as int,pricePerShare: null == pricePerShare ? _self.pricePerShare : pricePerShare // ignore: cast_nullable_to_non_nullable
as double,costBasisAtSale: freezed == costBasisAtSale ? _self.costBasisAtSale : costBasisAtSale // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [PositionSaleModel].
extension PositionSaleModelPatterns on PositionSaleModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PositionSaleModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PositionSaleModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PositionSaleModel value)  $default,){
final _that = this;
switch (_that) {
case _PositionSaleModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PositionSaleModel value)?  $default,){
final _that = this;
switch (_that) {
case _PositionSaleModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @TimestampConverter()  DateTime date,  int shares,  double pricePerShare,  double? costBasisAtSale)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PositionSaleModel() when $default != null:
return $default(_that.id,_that.date,_that.shares,_that.pricePerShare,_that.costBasisAtSale);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @TimestampConverter()  DateTime date,  int shares,  double pricePerShare,  double? costBasisAtSale)  $default,) {final _that = this;
switch (_that) {
case _PositionSaleModel():
return $default(_that.id,_that.date,_that.shares,_that.pricePerShare,_that.costBasisAtSale);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @TimestampConverter()  DateTime date,  int shares,  double pricePerShare,  double? costBasisAtSale)?  $default,) {final _that = this;
switch (_that) {
case _PositionSaleModel() when $default != null:
return $default(_that.id,_that.date,_that.shares,_that.pricePerShare,_that.costBasisAtSale);case _:
  return null;

}
}

}

/// @nodoc


class _PositionSaleModel implements PositionSaleModel {
  const _PositionSaleModel({required this.id, @TimestampConverter() required this.date, required this.shares, required this.pricePerShare, this.costBasisAtSale});
  

@override final  String id;
@override@TimestampConverter() final  DateTime date;
@override final  int shares;
@override final  double pricePerShare;
@override final  double? costBasisAtSale;

/// Create a copy of PositionSaleModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PositionSaleModelCopyWith<_PositionSaleModel> get copyWith => __$PositionSaleModelCopyWithImpl<_PositionSaleModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PositionSaleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.shares, shares) || other.shares == shares)&&(identical(other.pricePerShare, pricePerShare) || other.pricePerShare == pricePerShare)&&(identical(other.costBasisAtSale, costBasisAtSale) || other.costBasisAtSale == costBasisAtSale));
}


@override
int get hashCode => Object.hash(runtimeType,id,date,shares,pricePerShare,costBasisAtSale);

@override
String toString() {
  return 'PositionSaleModel(id: $id, date: $date, shares: $shares, pricePerShare: $pricePerShare, costBasisAtSale: $costBasisAtSale)';
}


}

/// @nodoc
abstract mixin class _$PositionSaleModelCopyWith<$Res> implements $PositionSaleModelCopyWith<$Res> {
  factory _$PositionSaleModelCopyWith(_PositionSaleModel value, $Res Function(_PositionSaleModel) _then) = __$PositionSaleModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@TimestampConverter() DateTime date, int shares, double pricePerShare, double? costBasisAtSale
});




}
/// @nodoc
class __$PositionSaleModelCopyWithImpl<$Res>
    implements _$PositionSaleModelCopyWith<$Res> {
  __$PositionSaleModelCopyWithImpl(this._self, this._then);

  final _PositionSaleModel _self;
  final $Res Function(_PositionSaleModel) _then;

/// Create a copy of PositionSaleModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? date = null,Object? shares = null,Object? pricePerShare = null,Object? costBasisAtSale = freezed,}) {
  return _then(_PositionSaleModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,shares: null == shares ? _self.shares : shares // ignore: cast_nullable_to_non_nullable
as int,pricePerShare: null == pricePerShare ? _self.pricePerShare : pricePerShare // ignore: cast_nullable_to_non_nullable
as double,costBasisAtSale: freezed == costBasisAtSale ? _self.costBasisAtSale : costBasisAtSale // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$PositionModel {

 String get id; String get ticker; String get status;@TimestampConverter() DateTime get openedAt;@TimestampConverter() DateTime? get closedAt; double? get targetPrice;@JsonKey(toJson: _buysToJson, fromJson: _buysFromJson) List<PositionBuyModel> get buys;@JsonKey(toJson: _salesToJson, fromJson: _salesFromJson) List<PositionSaleModel> get sales;
/// Create a copy of PositionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PositionModelCopyWith<PositionModel> get copyWith => _$PositionModelCopyWithImpl<PositionModel>(this as PositionModel, _$identity);

  /// Serializes this PositionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PositionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.ticker, ticker) || other.ticker == ticker)&&(identical(other.status, status) || other.status == status)&&(identical(other.openedAt, openedAt) || other.openedAt == openedAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.targetPrice, targetPrice) || other.targetPrice == targetPrice)&&const DeepCollectionEquality().equals(other.buys, buys)&&const DeepCollectionEquality().equals(other.sales, sales));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ticker,status,openedAt,closedAt,targetPrice,const DeepCollectionEquality().hash(buys),const DeepCollectionEquality().hash(sales));

@override
String toString() {
  return 'PositionModel(id: $id, ticker: $ticker, status: $status, openedAt: $openedAt, closedAt: $closedAt, targetPrice: $targetPrice, buys: $buys, sales: $sales)';
}


}

/// @nodoc
abstract mixin class $PositionModelCopyWith<$Res>  {
  factory $PositionModelCopyWith(PositionModel value, $Res Function(PositionModel) _then) = _$PositionModelCopyWithImpl;
@useResult
$Res call({
 String id, String ticker, String status,@TimestampConverter() DateTime openedAt,@TimestampConverter() DateTime? closedAt, double? targetPrice,@JsonKey(toJson: _buysToJson, fromJson: _buysFromJson) List<PositionBuyModel> buys,@JsonKey(toJson: _salesToJson, fromJson: _salesFromJson) List<PositionSaleModel> sales
});




}
/// @nodoc
class _$PositionModelCopyWithImpl<$Res>
    implements $PositionModelCopyWith<$Res> {
  _$PositionModelCopyWithImpl(this._self, this._then);

  final PositionModel _self;
  final $Res Function(PositionModel) _then;

/// Create a copy of PositionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ticker = null,Object? status = null,Object? openedAt = null,Object? closedAt = freezed,Object? targetPrice = freezed,Object? buys = null,Object? sales = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ticker: null == ticker ? _self.ticker : ticker // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,openedAt: null == openedAt ? _self.openedAt : openedAt // ignore: cast_nullable_to_non_nullable
as DateTime,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,targetPrice: freezed == targetPrice ? _self.targetPrice : targetPrice // ignore: cast_nullable_to_non_nullable
as double?,buys: null == buys ? _self.buys : buys // ignore: cast_nullable_to_non_nullable
as List<PositionBuyModel>,sales: null == sales ? _self.sales : sales // ignore: cast_nullable_to_non_nullable
as List<PositionSaleModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [PositionModel].
extension PositionModelPatterns on PositionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PositionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PositionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PositionModel value)  $default,){
final _that = this;
switch (_that) {
case _PositionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PositionModel value)?  $default,){
final _that = this;
switch (_that) {
case _PositionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String ticker,  String status, @TimestampConverter()  DateTime openedAt, @TimestampConverter()  DateTime? closedAt,  double? targetPrice, @JsonKey(toJson: _buysToJson, fromJson: _buysFromJson)  List<PositionBuyModel> buys, @JsonKey(toJson: _salesToJson, fromJson: _salesFromJson)  List<PositionSaleModel> sales)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PositionModel() when $default != null:
return $default(_that.id,_that.ticker,_that.status,_that.openedAt,_that.closedAt,_that.targetPrice,_that.buys,_that.sales);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String ticker,  String status, @TimestampConverter()  DateTime openedAt, @TimestampConverter()  DateTime? closedAt,  double? targetPrice, @JsonKey(toJson: _buysToJson, fromJson: _buysFromJson)  List<PositionBuyModel> buys, @JsonKey(toJson: _salesToJson, fromJson: _salesFromJson)  List<PositionSaleModel> sales)  $default,) {final _that = this;
switch (_that) {
case _PositionModel():
return $default(_that.id,_that.ticker,_that.status,_that.openedAt,_that.closedAt,_that.targetPrice,_that.buys,_that.sales);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String ticker,  String status, @TimestampConverter()  DateTime openedAt, @TimestampConverter()  DateTime? closedAt,  double? targetPrice, @JsonKey(toJson: _buysToJson, fromJson: _buysFromJson)  List<PositionBuyModel> buys, @JsonKey(toJson: _salesToJson, fromJson: _salesFromJson)  List<PositionSaleModel> sales)?  $default,) {final _that = this;
switch (_that) {
case _PositionModel() when $default != null:
return $default(_that.id,_that.ticker,_that.status,_that.openedAt,_that.closedAt,_that.targetPrice,_that.buys,_that.sales);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PositionModel implements PositionModel {
  const _PositionModel({required this.id, required this.ticker, required this.status, @TimestampConverter() required this.openedAt, @TimestampConverter() this.closedAt, this.targetPrice, @JsonKey(toJson: _buysToJson, fromJson: _buysFromJson) final  List<PositionBuyModel> buys = const [], @JsonKey(toJson: _salesToJson, fromJson: _salesFromJson) final  List<PositionSaleModel> sales = const []}): _buys = buys,_sales = sales;
  factory _PositionModel.fromJson(Map<String, dynamic> json) => _$PositionModelFromJson(json);

@override final  String id;
@override final  String ticker;
@override final  String status;
@override@TimestampConverter() final  DateTime openedAt;
@override@TimestampConverter() final  DateTime? closedAt;
@override final  double? targetPrice;
 final  List<PositionBuyModel> _buys;
@override@JsonKey(toJson: _buysToJson, fromJson: _buysFromJson) List<PositionBuyModel> get buys {
  if (_buys is EqualUnmodifiableListView) return _buys;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_buys);
}

 final  List<PositionSaleModel> _sales;
@override@JsonKey(toJson: _salesToJson, fromJson: _salesFromJson) List<PositionSaleModel> get sales {
  if (_sales is EqualUnmodifiableListView) return _sales;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sales);
}


/// Create a copy of PositionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PositionModelCopyWith<_PositionModel> get copyWith => __$PositionModelCopyWithImpl<_PositionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PositionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PositionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.ticker, ticker) || other.ticker == ticker)&&(identical(other.status, status) || other.status == status)&&(identical(other.openedAt, openedAt) || other.openedAt == openedAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.targetPrice, targetPrice) || other.targetPrice == targetPrice)&&const DeepCollectionEquality().equals(other._buys, _buys)&&const DeepCollectionEquality().equals(other._sales, _sales));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ticker,status,openedAt,closedAt,targetPrice,const DeepCollectionEquality().hash(_buys),const DeepCollectionEquality().hash(_sales));

@override
String toString() {
  return 'PositionModel(id: $id, ticker: $ticker, status: $status, openedAt: $openedAt, closedAt: $closedAt, targetPrice: $targetPrice, buys: $buys, sales: $sales)';
}


}

/// @nodoc
abstract mixin class _$PositionModelCopyWith<$Res> implements $PositionModelCopyWith<$Res> {
  factory _$PositionModelCopyWith(_PositionModel value, $Res Function(_PositionModel) _then) = __$PositionModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String ticker, String status,@TimestampConverter() DateTime openedAt,@TimestampConverter() DateTime? closedAt, double? targetPrice,@JsonKey(toJson: _buysToJson, fromJson: _buysFromJson) List<PositionBuyModel> buys,@JsonKey(toJson: _salesToJson, fromJson: _salesFromJson) List<PositionSaleModel> sales
});




}
/// @nodoc
class __$PositionModelCopyWithImpl<$Res>
    implements _$PositionModelCopyWith<$Res> {
  __$PositionModelCopyWithImpl(this._self, this._then);

  final _PositionModel _self;
  final $Res Function(_PositionModel) _then;

/// Create a copy of PositionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ticker = null,Object? status = null,Object? openedAt = null,Object? closedAt = freezed,Object? targetPrice = freezed,Object? buys = null,Object? sales = null,}) {
  return _then(_PositionModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ticker: null == ticker ? _self.ticker : ticker // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,openedAt: null == openedAt ? _self.openedAt : openedAt // ignore: cast_nullable_to_non_nullable
as DateTime,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,targetPrice: freezed == targetPrice ? _self.targetPrice : targetPrice // ignore: cast_nullable_to_non_nullable
as double?,buys: null == buys ? _self._buys : buys // ignore: cast_nullable_to_non_nullable
as List<PositionBuyModel>,sales: null == sales ? _self._sales : sales // ignore: cast_nullable_to_non_nullable
as List<PositionSaleModel>,
  ));
}


}

// dart format on

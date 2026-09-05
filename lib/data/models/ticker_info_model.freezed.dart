// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ticker_info_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TickerInfoModel {

 String get symbol; String get name; String? get sector;
/// Create a copy of TickerInfoModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TickerInfoModelCopyWith<TickerInfoModel> get copyWith => _$TickerInfoModelCopyWithImpl<TickerInfoModel>(this as TickerInfoModel, _$identity);

  /// Serializes this TickerInfoModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TickerInfoModel&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.name, name) || other.name == name)&&(identical(other.sector, sector) || other.sector == sector));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,symbol,name,sector);

@override
String toString() {
  return 'TickerInfoModel(symbol: $symbol, name: $name, sector: $sector)';
}


}

/// @nodoc
abstract mixin class $TickerInfoModelCopyWith<$Res>  {
  factory $TickerInfoModelCopyWith(TickerInfoModel value, $Res Function(TickerInfoModel) _then) = _$TickerInfoModelCopyWithImpl;
@useResult
$Res call({
 String symbol, String name, String? sector
});




}
/// @nodoc
class _$TickerInfoModelCopyWithImpl<$Res>
    implements $TickerInfoModelCopyWith<$Res> {
  _$TickerInfoModelCopyWithImpl(this._self, this._then);

  final TickerInfoModel _self;
  final $Res Function(TickerInfoModel) _then;

/// Create a copy of TickerInfoModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? symbol = null,Object? name = null,Object? sector = freezed,}) {
  return _then(_self.copyWith(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sector: freezed == sector ? _self.sector : sector // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TickerInfoModel].
extension TickerInfoModelPatterns on TickerInfoModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TickerInfoModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TickerInfoModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TickerInfoModel value)  $default,){
final _that = this;
switch (_that) {
case _TickerInfoModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TickerInfoModel value)?  $default,){
final _that = this;
switch (_that) {
case _TickerInfoModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String symbol,  String name,  String? sector)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TickerInfoModel() when $default != null:
return $default(_that.symbol,_that.name,_that.sector);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String symbol,  String name,  String? sector)  $default,) {final _that = this;
switch (_that) {
case _TickerInfoModel():
return $default(_that.symbol,_that.name,_that.sector);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String symbol,  String name,  String? sector)?  $default,) {final _that = this;
switch (_that) {
case _TickerInfoModel() when $default != null:
return $default(_that.symbol,_that.name,_that.sector);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TickerInfoModel implements TickerInfoModel {
  const _TickerInfoModel({required this.symbol, required this.name, this.sector});
  factory _TickerInfoModel.fromJson(Map<String, dynamic> json) => _$TickerInfoModelFromJson(json);

@override final  String symbol;
@override final  String name;
@override final  String? sector;

/// Create a copy of TickerInfoModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TickerInfoModelCopyWith<_TickerInfoModel> get copyWith => __$TickerInfoModelCopyWithImpl<_TickerInfoModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TickerInfoModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TickerInfoModel&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.name, name) || other.name == name)&&(identical(other.sector, sector) || other.sector == sector));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,symbol,name,sector);

@override
String toString() {
  return 'TickerInfoModel(symbol: $symbol, name: $name, sector: $sector)';
}


}

/// @nodoc
abstract mixin class _$TickerInfoModelCopyWith<$Res> implements $TickerInfoModelCopyWith<$Res> {
  factory _$TickerInfoModelCopyWith(_TickerInfoModel value, $Res Function(_TickerInfoModel) _then) = __$TickerInfoModelCopyWithImpl;
@override @useResult
$Res call({
 String symbol, String name, String? sector
});




}
/// @nodoc
class __$TickerInfoModelCopyWithImpl<$Res>
    implements _$TickerInfoModelCopyWith<$Res> {
  __$TickerInfoModelCopyWithImpl(this._self, this._then);

  final _TickerInfoModel _self;
  final $Res Function(_TickerInfoModel) _then;

/// Create a copy of TickerInfoModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? symbol = null,Object? name = null,Object? sector = freezed,}) {
  return _then(_TickerInfoModel(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sector: freezed == sector ? _self.sector : sector // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'withdrawal_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WithdrawalModel {

 String get id;@TimestampConverter() DateTime get date; double get amount; String get note;
/// Create a copy of WithdrawalModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WithdrawalModelCopyWith<WithdrawalModel> get copyWith => _$WithdrawalModelCopyWithImpl<WithdrawalModel>(this as WithdrawalModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WithdrawalModel&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hash(runtimeType,id,date,amount,note);

@override
String toString() {
  return 'WithdrawalModel(id: $id, date: $date, amount: $amount, note: $note)';
}


}

/// @nodoc
abstract mixin class $WithdrawalModelCopyWith<$Res>  {
  factory $WithdrawalModelCopyWith(WithdrawalModel value, $Res Function(WithdrawalModel) _then) = _$WithdrawalModelCopyWithImpl;
@useResult
$Res call({
 String id,@TimestampConverter() DateTime date, double amount, String note
});




}
/// @nodoc
class _$WithdrawalModelCopyWithImpl<$Res>
    implements $WithdrawalModelCopyWith<$Res> {
  _$WithdrawalModelCopyWithImpl(this._self, this._then);

  final WithdrawalModel _self;
  final $Res Function(WithdrawalModel) _then;

/// Create a copy of WithdrawalModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? date = null,Object? amount = null,Object? note = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WithdrawalModel].
extension WithdrawalModelPatterns on WithdrawalModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WithdrawalModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WithdrawalModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WithdrawalModel value)  $default,){
final _that = this;
switch (_that) {
case _WithdrawalModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WithdrawalModel value)?  $default,){
final _that = this;
switch (_that) {
case _WithdrawalModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @TimestampConverter()  DateTime date,  double amount,  String note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WithdrawalModel() when $default != null:
return $default(_that.id,_that.date,_that.amount,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @TimestampConverter()  DateTime date,  double amount,  String note)  $default,) {final _that = this;
switch (_that) {
case _WithdrawalModel():
return $default(_that.id,_that.date,_that.amount,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @TimestampConverter()  DateTime date,  double amount,  String note)?  $default,) {final _that = this;
switch (_that) {
case _WithdrawalModel() when $default != null:
return $default(_that.id,_that.date,_that.amount,_that.note);case _:
  return null;

}
}

}

/// @nodoc


class _WithdrawalModel implements WithdrawalModel {
  const _WithdrawalModel({required this.id, @TimestampConverter() required this.date, required this.amount, this.note = ''});
  

@override final  String id;
@override@TimestampConverter() final  DateTime date;
@override final  double amount;
@override@JsonKey() final  String note;

/// Create a copy of WithdrawalModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WithdrawalModelCopyWith<_WithdrawalModel> get copyWith => __$WithdrawalModelCopyWithImpl<_WithdrawalModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WithdrawalModel&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hash(runtimeType,id,date,amount,note);

@override
String toString() {
  return 'WithdrawalModel(id: $id, date: $date, amount: $amount, note: $note)';
}


}

/// @nodoc
abstract mixin class _$WithdrawalModelCopyWith<$Res> implements $WithdrawalModelCopyWith<$Res> {
  factory _$WithdrawalModelCopyWith(_WithdrawalModel value, $Res Function(_WithdrawalModel) _then) = __$WithdrawalModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@TimestampConverter() DateTime date, double amount, String note
});




}
/// @nodoc
class __$WithdrawalModelCopyWithImpl<$Res>
    implements _$WithdrawalModelCopyWith<$Res> {
  __$WithdrawalModelCopyWithImpl(this._self, this._then);

  final _WithdrawalModel _self;
  final $Res Function(_WithdrawalModel) _then;

/// Create a copy of WithdrawalModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? date = null,Object? amount = null,Object? note = null,}) {
  return _then(_WithdrawalModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

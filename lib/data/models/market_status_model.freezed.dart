// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'market_status_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MarketStatusModel {

 bool get isOpen; String get label;@JsonKey(fromJson: _dateFromJson, toJson: _dateToJson) DateTime get checkedAt;
/// Create a copy of MarketStatusModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarketStatusModelCopyWith<MarketStatusModel> get copyWith => _$MarketStatusModelCopyWithImpl<MarketStatusModel>(this as MarketStatusModel, _$identity);

  /// Serializes this MarketStatusModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarketStatusModel&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.label, label) || other.label == label)&&(identical(other.checkedAt, checkedAt) || other.checkedAt == checkedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isOpen,label,checkedAt);

@override
String toString() {
  return 'MarketStatusModel(isOpen: $isOpen, label: $label, checkedAt: $checkedAt)';
}


}

/// @nodoc
abstract mixin class $MarketStatusModelCopyWith<$Res>  {
  factory $MarketStatusModelCopyWith(MarketStatusModel value, $Res Function(MarketStatusModel) _then) = _$MarketStatusModelCopyWithImpl;
@useResult
$Res call({
 bool isOpen, String label,@JsonKey(fromJson: _dateFromJson, toJson: _dateToJson) DateTime checkedAt
});




}
/// @nodoc
class _$MarketStatusModelCopyWithImpl<$Res>
    implements $MarketStatusModelCopyWith<$Res> {
  _$MarketStatusModelCopyWithImpl(this._self, this._then);

  final MarketStatusModel _self;
  final $Res Function(MarketStatusModel) _then;

/// Create a copy of MarketStatusModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isOpen = null,Object? label = null,Object? checkedAt = null,}) {
  return _then(MarketStatusModel(
isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,checkedAt: null == checkedAt ? _self.checkedAt : checkedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MarketStatusModel].
extension MarketStatusModelPatterns on MarketStatusModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MarketStatusModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MarketStatusModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MarketStatusModel value)  $default,){
final _that = this;
switch (_that) {
case _MarketStatusModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MarketStatusModel value)?  $default,){
final _that = this;
switch (_that) {
case _MarketStatusModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isOpen,  String label, @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)  DateTime checkedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MarketStatusModel() when $default != null:
return $default(_that.isOpen,_that.label,_that.checkedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isOpen,  String label, @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)  DateTime checkedAt)  $default,) {final _that = this;
switch (_that) {
case _MarketStatusModel():
return $default(_that.isOpen,_that.label,_that.checkedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isOpen,  String label, @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)  DateTime checkedAt)?  $default,) {final _that = this;
switch (_that) {
case _MarketStatusModel() when $default != null:
return $default(_that.isOpen,_that.label,_that.checkedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MarketStatusModel extends MarketStatusModel {
  const _MarketStatusModel({required this.isOpen, required this.label, @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson) required this.checkedAt}): super._();
  factory _MarketStatusModel.fromJson(Map<String, dynamic> json) => _$MarketStatusModelFromJson(json);

@override final  bool isOpen;
@override final  String label;
@override@JsonKey(fromJson: _dateFromJson, toJson: _dateToJson) final  DateTime checkedAt;

/// Create a copy of MarketStatusModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MarketStatusModelCopyWith<_MarketStatusModel> get copyWith => __$MarketStatusModelCopyWithImpl<_MarketStatusModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MarketStatusModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MarketStatusModel&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.label, label) || other.label == label)&&(identical(other.checkedAt, checkedAt) || other.checkedAt == checkedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isOpen,label,checkedAt);

@override
String toString() {
  return 'MarketStatusModel(isOpen: $isOpen, label: $label, checkedAt: $checkedAt)';
}


}

/// @nodoc
abstract mixin class _$MarketStatusModelCopyWith<$Res> implements $MarketStatusModelCopyWith<$Res> {
  factory _$MarketStatusModelCopyWith(_MarketStatusModel value, $Res Function(_MarketStatusModel) _then) = __$MarketStatusModelCopyWithImpl;
@override @useResult
$Res call({
 bool isOpen, String label,@JsonKey(fromJson: _dateFromJson, toJson: _dateToJson) DateTime checkedAt
});




}
/// @nodoc
class __$MarketStatusModelCopyWithImpl<$Res>
    implements _$MarketStatusModelCopyWith<$Res> {
  __$MarketStatusModelCopyWithImpl(this._self, this._then);

  final _MarketStatusModel _self;
  final $Res Function(_MarketStatusModel) _then;

/// Create a copy of MarketStatusModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isOpen = null,Object? label = null,Object? checkedAt = null,}) {
  return _then(_MarketStatusModel(
isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,checkedAt: null == checkedAt ? _self.checkedAt : checkedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on

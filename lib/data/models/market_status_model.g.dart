// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market_status_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MarketStatusModel _$MarketStatusModelFromJson(Map<String, dynamic> json) =>
    _MarketStatusModel(
      isOpen: json['isOpen'] as bool,
      label: json['label'] as String,
      checkedAt: _dateFromJson(json['checkedAt']),
    );

Map<String, dynamic> _$MarketStatusModelToJson(_MarketStatusModel instance) =>
    <String, dynamic>{
      'isOpen': instance.isOpen,
      'label': instance.label,
      'checkedAt': _dateToJson(instance.checkedAt),
    };

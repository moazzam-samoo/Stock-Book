// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticker_info_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TickerInfoModel _$TickerInfoModelFromJson(Map<String, dynamic> json) =>
    _TickerInfoModel(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      sector: json['sector'] as String?,
    );

Map<String, dynamic> _$TickerInfoModelToJson(_TickerInfoModel instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'name': instance.name,
      'sector': instance.sector,
    };

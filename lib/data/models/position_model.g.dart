// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PositionModel _$PositionModelFromJson(
  Map<String, dynamic> json,
) => _PositionModel(
  id: json['id'] as String,
  ticker: json['ticker'] as String,
  status: json['status'] as String,
  openedAt: const TimestampConverter().fromJson(json['openedAt'] as Timestamp),
  closedAt: _$JsonConverterFromJson<Timestamp, DateTime>(
    json['closedAt'],
    const TimestampConverter().fromJson,
  ),
  targetPrice: (json['targetPrice'] as num?)?.toDouble(),
  targetAlertSent: json['targetAlertSent'] as bool? ?? false,
  targetAlertSentAt: _$JsonConverterFromJson<Timestamp, DateTime>(
    json['targetAlertSentAt'],
    const TimestampConverter().fromJson,
  ),
  buys: json['buys'] == null ? const [] : _buysFromJson(json['buys'] as List?),
  sales: json['sales'] == null
      ? const []
      : _salesFromJson(json['sales'] as List?),
);

Map<String, dynamic> _$PositionModelToJson(_PositionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ticker': instance.ticker,
      'status': instance.status,
      'openedAt': const TimestampConverter().toJson(instance.openedAt),
      'closedAt': _$JsonConverterToJson<Timestamp, DateTime>(
        instance.closedAt,
        const TimestampConverter().toJson,
      ),
      'targetPrice': instance.targetPrice,
      'targetAlertSent': instance.targetAlertSent,
      'targetAlertSentAt': _$JsonConverterToJson<Timestamp, DateTime>(
        instance.targetAlertSentAt,
        const TimestampConverter().toJson,
      ),
      'buys': _buysToJson(instance.buys),
      'sales': _salesToJson(instance.sales),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);

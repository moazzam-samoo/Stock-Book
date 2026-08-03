// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SaleModel _$SaleModelFromJson(Map<String, dynamic> json) => _SaleModel(
  id: json['id'] as String,
  sellDate: const TimestampConverter().fromJson(json['sellDate'] as Timestamp),
  sharesSold: (json['sharesSold'] as num).toInt(),
  sellPricePerShare: (json['sellPricePerShare'] as num).toDouble(),
);

Map<String, dynamic> _$SaleModelToJson(_SaleModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sellDate': const TimestampConverter().toJson(instance.sellDate),
      'sharesSold': instance.sharesSold,
      'sellPricePerShare': instance.sellPricePerShare,
    };

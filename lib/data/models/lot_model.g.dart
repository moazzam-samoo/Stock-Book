// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lot_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LotModel _$LotModelFromJson(Map<String, dynamic> json) => _LotModel(
  id: json['id'] as String,
  ticker: json['ticker'] as String,
  buyDate: const TimestampConverter().fromJson(json['buyDate'] as Timestamp),
  sharesPurchased: (json['sharesPurchased'] as num).toInt(),
  buyPricePerShare: (json['buyPricePerShare'] as num).toDouble(),
  sales: (json['sales'] as List<dynamic>?)
          ?.map((e) => SaleModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$LotModelToJson(_LotModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ticker': instance.ticker,
      'buyDate': const TimestampConverter().toJson(instance.buyDate),
      'sharesPurchased': instance.sharesPurchased,
      'buyPricePerShare': instance.buyPricePerShare,
      'sales': instance.sales.map((e) => e.toJson()).toList(),
    };

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stock_investment_tracker/domain/entities/sale.dart';

part 'sale_model.freezed.dart';
part 'sale_model.g.dart';

class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const TimestampConverter();

  @override
  DateTime fromJson(Timestamp timestamp) => timestamp.toDate();

  @override
  Timestamp toJson(DateTime date) => Timestamp.fromDate(date);
}

@freezed
class SaleModel with _$SaleModel {
  const factory SaleModel({
    required String id,
    @TimestampConverter() required DateTime sellDate,
    required int sharesSold,
    required double sellPricePerShare,
  }) = _SaleModel;

  factory SaleModel.fromJson(Map<String, dynamic> json) => _$SaleModelFromJson(json);
}

extension SaleModelExtension on SaleModel {
  Sale toEntity(double amountReceived) {
    return Sale(
      id: id,
      sellDate: sellDate,
      sharesSold: sharesSold,
      sellPricePerShare: sellPricePerShare,
      amountReceived: amountReceived,
    );
  }

  static SaleModel fromEntity(Sale entity) {
    return SaleModel(
      id: entity.id,
      sellDate: entity.sellDate,
      sharesSold: entity.sharesSold,
      sellPricePerShare: entity.sellPricePerShare,
    );
  }
}

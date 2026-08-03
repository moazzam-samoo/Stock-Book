import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stock_investment_tracker/domain/entities/sale.dart';
import 'package:stock_investment_tracker/core/utils/timestamp_converter.dart';

part 'sale_model.freezed.dart';
part 'sale_model.g.dart';


@freezed
abstract class SaleModel with _$SaleModel {
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

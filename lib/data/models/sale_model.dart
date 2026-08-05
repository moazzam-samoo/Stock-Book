import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stock_investment_tracker/domain/entities/sale.dart';
import 'package:stock_investment_tracker/core/utils/timestamp_converter.dart';

part 'sale_model.freezed.dart';

@freezed
abstract class SaleModel with _$SaleModel {
  const factory SaleModel({
    required String id,
    @TimestampConverter() required DateTime sellDate,
    required int sharesSold,
    required double sellPricePerShare,
  }) = _SaleModel;

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['sellDate'] is Timestamp) {
      parsedDate = (json['sellDate'] as Timestamp).toDate();
    } else if (json['sellDate'] is String) {
      parsedDate = DateTime.tryParse(json['sellDate'] as String) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return SaleModel(
      id: (json['id'] as String?) ?? '',
      sellDate: parsedDate,
      sharesSold: (json['sharesSold'] as num).toInt(),
      sellPricePerShare: (json['sellPricePerShare'] as num).toDouble(),
    );
  }
}

extension SaleModelExtension on SaleModel {
  /// Manual toJson since we use a custom fromJson (no .g.dart generated).
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'sellDate': Timestamp.fromDate(sellDate),
      'sharesSold': sharesSold,
      'sellPricePerShare': sellPricePerShare,
    };
  }

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

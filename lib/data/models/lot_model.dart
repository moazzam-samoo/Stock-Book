import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/domain/entities/sale.dart';
import 'package:stock_investment_tracker/data/models/sale_model.dart';
import 'package:stock_investment_tracker/domain/enums/lot_status.dart';
import 'package:stock_investment_tracker/core/utils/timestamp_converter.dart';

part 'lot_model.freezed.dart';
part 'lot_model.g.dart';

@freezed
abstract class LotModel with _$LotModel {
  @JsonSerializable(explicitToJson: true)
  const factory LotModel({
    required String id,
    required String ticker,
    @TimestampConverter() required DateTime buyDate,
    required int sharesPurchased,
    required double buyPricePerShare,
    @Default([]) List<SaleModel> sales,
  }) = _LotModel;

  factory LotModel.fromJson(Map<String, dynamic> json) => _$LotModelFromJson(json);
}

extension LotModelExtension on LotModel {
  Lot toEntity() {
    double amountInvested = sharesPurchased * buyPricePerShare;
    int soldShares = 0;
    double realizedPL = 0.0;
    
    final entitySales = sales.map((s) {
       double saleValue = s.sharesSold * s.sellPricePerShare;
       soldShares += s.sharesSold;
       realizedPL += saleValue - (s.sharesSold * buyPricePerShare);
       return s.toEntity(saleValue);
    }).toList();

    int remaining = sharesPurchased - soldShares;
    double investedRemaining = remaining * buyPricePerShare;
    LotStatus computedStatus = remaining <= 0 ? LotStatus.closed : LotStatus.open;

    return Lot(
      id: id,
      ticker: ticker,
      buyDate: buyDate,
      sharesPurchased: sharesPurchased,
      buyPricePerShare: buyPricePerShare,
      amountInvested: amountInvested,
      sales: entitySales,
      sharesRemaining: remaining,
      amountInvestedRemaining: investedRemaining,
      realizedProfitLoss: realizedPL,
      status: computedStatus,
    );
  }

  static LotModel fromEntity(Lot entity) {
    return LotModel(
      id: entity.id,
      ticker: entity.ticker,
      buyDate: entity.buyDate,
      sharesPurchased: entity.sharesPurchased,
      buyPricePerShare: entity.buyPricePerShare,
      sales: entity.sales.map((s) => SaleModelExtension.fromEntity(s)).toList(),
    );
  }
}

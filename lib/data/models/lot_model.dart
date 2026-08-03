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
  const factory LotModel({
    required String id,
    required String ticker,
    @TimestampConverter() required DateTime buyDate,
    required int sharesPurchased,
    required double buyPricePerShare,
  }) = _LotModel;

  factory LotModel.fromJson(Map<String, dynamic> json) => _$LotModelFromJson(json);
}

extension LotModelExtension on LotModel {
  Lot toEntity({
    required double amountInvested,
    List<Sale> sales = const [],
    int sharesRemaining = 0,
    double amountInvestedRemaining = 0.0,
    double realizedProfitLoss = 0.0,
    LotStatus status = LotStatus.open,
  }) {
    return Lot(
      id: id,
      ticker: ticker,
      buyDate: buyDate,
      sharesPurchased: sharesPurchased,
      buyPricePerShare: buyPricePerShare,
      amountInvested: amountInvested,
      sales: sales,
      sharesRemaining: sharesRemaining,
      amountInvestedRemaining: amountInvestedRemaining,
      realizedProfitLoss: realizedProfitLoss,
      status: status,
    );
  }

  static LotModel fromEntity(Lot entity) {
    return LotModel(
      id: entity.id,
      ticker: entity.ticker,
      buyDate: entity.buyDate,
      sharesPurchased: entity.sharesPurchased,
      buyPricePerShare: entity.buyPricePerShare,
    );
  }
}

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stock_investment_tracker/domain/entities/ticker_info.dart';

part 'ticker_info_model.freezed.dart';
part 'ticker_info_model.g.dart';

@freezed
abstract class TickerInfoModel with _$TickerInfoModel {
  const factory TickerInfoModel({
    required String symbol,
    required String name,
    String? sector,
  }) = _TickerInfoModel;

  factory TickerInfoModel.fromJson(Map<String, dynamic> json) =>
      _$TickerInfoModelFromJson(json);

  factory TickerInfoModel.fromEntity(TickerInfo entity) {
    return TickerInfoModel(
      symbol: entity.symbol,
      name: entity.name,
      sector: entity.sector,
    );
  }
}

extension TickerInfoModelX on TickerInfoModel {
  TickerInfo toEntity() {
    return TickerInfo(
      symbol: symbol,
      name: name,
      sector: sector,
    );
  }
}

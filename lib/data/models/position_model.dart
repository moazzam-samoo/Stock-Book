import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stock_investment_tracker/domain/entities/position.dart';
import 'package:stock_investment_tracker/domain/entities/position_buy.dart';
import 'package:stock_investment_tracker/domain/entities/position_sale.dart';
import 'package:stock_investment_tracker/domain/enums/position_status.dart';
import 'package:stock_investment_tracker/core/utils/timestamp_converter.dart';

part 'position_model.freezed.dart';
part 'position_model.g.dart';

DateTime _parseDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  } else if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  } else {
    return DateTime.now();
  }
}

// ----------------------------------------------------------------------
// PositionBuyModel
// ----------------------------------------------------------------------

@freezed
abstract class PositionBuyModel with _$PositionBuyModel {
  const factory PositionBuyModel({
    required String id,
    @TimestampConverter() required DateTime date,
    required int shares,
    required double pricePerShare,
  }) = _PositionBuyModel;

  factory PositionBuyModel.fromJson(Map<String, dynamic> json) {
    return PositionBuyModel(
      id: (json['id'] as String?) ?? '',
      date: _parseDate(json['date']),
      shares: (json['shares'] as num).toInt(),
      pricePerShare: (json['pricePerShare'] as num).toDouble(),
    );
  }
}

extension PositionBuyModelExtension on PositionBuyModel {
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'date': Timestamp.fromDate(date),
      'shares': shares,
      'pricePerShare': pricePerShare,
    };
  }

  PositionBuy toEntity() {
    return PositionBuy(
      id: id,
      date: date,
      shares: shares,
      pricePerShare: pricePerShare,
    );
  }

  static PositionBuyModel fromEntity(PositionBuy entity) {
    return PositionBuyModel(
      id: entity.id,
      date: entity.date,
      shares: entity.shares,
      pricePerShare: entity.pricePerShare,
    );
  }
}

// ----------------------------------------------------------------------
// PositionSaleModel
// ----------------------------------------------------------------------

@freezed
abstract class PositionSaleModel with _$PositionSaleModel {
  const factory PositionSaleModel({
    required String id,
    @TimestampConverter() required DateTime date,
    required int shares,
    required double pricePerShare,
    double? costBasisAtSale,
  }) = _PositionSaleModel;

  factory PositionSaleModel.fromJson(Map<String, dynamic> json) {
    return PositionSaleModel(
      id: (json['id'] as String?) ?? '',
      date: _parseDate(json['date']),
      shares: (json['shares'] as num).toInt(),
      pricePerShare: (json['pricePerShare'] as num).toDouble(),
      costBasisAtSale: json['costBasisAtSale'] != null ? (json['costBasisAtSale'] as num).toDouble() : null,
    );
  }
}

extension PositionSaleModelExtension on PositionSaleModel {
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'date': Timestamp.fromDate(date),
      'shares': shares,
      'pricePerShare': pricePerShare,
      'costBasisAtSale': costBasisAtSale,
    };
  }

  PositionSale toEntity() {
    return PositionSale(
      id: id,
      date: date,
      shares: shares,
      pricePerShare: pricePerShare,
      costBasisAtSale: costBasisAtSale,
    );
  }

  static PositionSaleModel fromEntity(PositionSale entity) {
    return PositionSaleModel(
      id: entity.id,
      date: entity.date,
      shares: entity.shares,
      pricePerShare: entity.pricePerShare,
      costBasisAtSale: entity.costBasisAtSale,
    );
  }
}

// ----------------------------------------------------------------------
// PositionModel
// ----------------------------------------------------------------------

@freezed
abstract class PositionModel with _$PositionModel {
  const factory PositionModel({
    required String id,
    required String ticker,
    required String status,
    @TimestampConverter() required DateTime openedAt,
    @TimestampConverter() DateTime? closedAt,
    double? targetPrice,
    @Default(false) bool targetAlertSent,
    @TimestampConverter() DateTime? targetAlertSentAt,
    @JsonKey(toJson: _buysToJson, fromJson: _buysFromJson)
    @Default([]) List<PositionBuyModel> buys,
    @JsonKey(toJson: _salesToJson, fromJson: _salesFromJson)
    @Default([]) List<PositionSaleModel> sales,
  }) = _PositionModel;

  factory PositionModel.fromJson(Map<String, dynamic> json) => _$PositionModelFromJson(json);
}

List<Map<String, dynamic>> _buysToJson(List<PositionBuyModel> buys) =>
    buys.map((b) => b.toJson()).toList();

List<PositionBuyModel> _buysFromJson(List<dynamic>? list) =>
    list == null ? [] : list.map((e) => PositionBuyModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();

List<Map<String, dynamic>> _salesToJson(List<PositionSaleModel> sales) =>
    sales.map((s) => s.toJson()).toList();

List<PositionSaleModel> _salesFromJson(List<dynamic>? list) =>
    list == null ? [] : list.map((e) => PositionSaleModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();

extension PositionModelExtension on PositionModel {
  Position toEntity() {
    PositionStatus parsedStatus;
    switch (status) {
      case 'open':
        parsedStatus = PositionStatus.open;
        break;
      case 'partiallySold':
        parsedStatus = PositionStatus.partiallySold;
        break;
      case 'closed':
        parsedStatus = PositionStatus.closed;
        break;
      default:
        parsedStatus = PositionStatus.open;
    }

    return Position(
      id: id,
      ticker: ticker,
      status: parsedStatus,
      openedAt: openedAt,
      closedAt: closedAt,
      targetPrice: targetPrice,
      targetAlertSent: targetAlertSent,
      targetAlertSentAt: targetAlertSentAt,
      buys: buys.map((b) => b.toEntity()).toList(),
      sales: sales.map((s) => s.toEntity()).toList(),
    );
  }

  static PositionModel fromEntity(Position entity) {
    return PositionModel(
      id: entity.id,
      ticker: entity.ticker,
      status: entity.status.name,
      openedAt: entity.openedAt,
      closedAt: entity.closedAt,
      targetPrice: entity.targetPrice,
      targetAlertSent: entity.targetAlertSent,
      targetAlertSentAt: entity.targetAlertSentAt,
      buys: entity.buys.map((b) => PositionBuyModelExtension.fromEntity(b)).toList(),
      sales: entity.sales.map((s) => PositionSaleModelExtension.fromEntity(s)).toList(),
    );
  }
}

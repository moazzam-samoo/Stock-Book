import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stock_investment_tracker/domain/entities/price_alert.dart';
import 'package:stock_investment_tracker/core/utils/timestamp_converter.dart';

part 'price_alert_model.freezed.dart';

DateTime _parseDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  } else if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  } else {
    return DateTime.now();
  }
}

@freezed
abstract class PriceAlertModel with _$PriceAlertModel {
  const factory PriceAlertModel({
    required String id,
    required String ticker,
    required double targetPrice,
    @Default(1.0) double tolerancePercent,
    @Default(true) bool isActive,
    @Default(false) bool alertSent,
    @TimestampConverter() DateTime? alertSentAt,
    double? lastAlertPrice,
    @TimestampConverter() required DateTime createdAt,
  }) = _PriceAlertModel;

  factory PriceAlertModel.fromJson(Map<String, dynamic> json) {
    // We override fromJson for defensive date parsing like PositionBuyModel
    return PriceAlertModel(
      id: (json['id'] as String?) ?? '',
      ticker: (json['ticker'] as String?) ?? '',
      targetPrice: (json['targetPrice'] as num).toDouble(),
      tolerancePercent: (json['tolerancePercent'] as num?)?.toDouble() ?? 1.0,
      isActive: (json['isActive'] as bool?) ?? true,
      alertSent: (json['alertSent'] as bool?) ?? false,
      alertSentAt: json['alertSentAt'] != null ? _parseDate(json['alertSentAt']) : null,
      lastAlertPrice: (json['lastAlertPrice'] as num?)?.toDouble(),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  factory PriceAlertModel.fromEntity(PriceAlert entity) {
    return PriceAlertModel(
      id: entity.id,
      ticker: entity.ticker,
      targetPrice: entity.targetPrice,
      tolerancePercent: entity.tolerancePercent,
      isActive: entity.isActive,
      alertSent: entity.alertSent,
      alertSentAt: entity.alertSentAt,
      lastAlertPrice: entity.lastAlertPrice,
      createdAt: entity.createdAt,
    );
  }
}

extension PriceAlertModelExtension on PriceAlertModel {
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'ticker': ticker,
      'targetPrice': targetPrice,
      'tolerancePercent': tolerancePercent,
      'isActive': isActive,
      'alertSent': alertSent,
      'alertSentAt': alertSentAt != null ? Timestamp.fromDate(alertSentAt!) : null,
      'lastAlertPrice': lastAlertPrice,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  PriceAlert toEntity() {
    return PriceAlert(
      id: id,
      ticker: ticker,
      targetPrice: targetPrice,
      tolerancePercent: tolerancePercent,
      isActive: isActive,
      alertSent: alertSent,
      alertSentAt: alertSentAt,
      lastAlertPrice: lastAlertPrice,
      createdAt: createdAt,
    );
  }
}

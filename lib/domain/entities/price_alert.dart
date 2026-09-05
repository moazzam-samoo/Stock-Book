import 'package:equatable/equatable.dart';

class PriceAlert extends Equatable {
  final String id;
  final String ticker;
  final double targetPrice;
  final double tolerancePercent;
  final bool isActive;
  final bool alertSent;
  final DateTime? alertSentAt;
  final DateTime createdAt;

  const PriceAlert({
    required this.id,
    required this.ticker,
    required this.targetPrice,
    this.tolerancePercent = 1.0,
    this.isActive = true,
    this.alertSent = false,
    this.alertSentAt,
    required this.createdAt,
  });

  PriceAlert copyWith({
    String? id,
    String? ticker,
    double? targetPrice,
    double? tolerancePercent,
    bool? isActive,
    bool? alertSent,
    DateTime? alertSentAt,
    bool clearAlertSentAt = false,
    DateTime? createdAt,
  }) {
    return PriceAlert(
      id: id ?? this.id,
      ticker: ticker ?? this.ticker,
      targetPrice: targetPrice ?? this.targetPrice,
      tolerancePercent: tolerancePercent ?? this.tolerancePercent,
      isActive: isActive ?? this.isActive,
      alertSent: alertSent ?? this.alertSent,
      alertSentAt: clearAlertSentAt ? null : (alertSentAt ?? this.alertSentAt),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ticker,
        targetPrice,
        tolerancePercent,
        isActive,
        alertSent,
        alertSentAt,
        createdAt,
      ];
}

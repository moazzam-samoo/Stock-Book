import 'package:equatable/equatable.dart';

class PriceAlert extends Equatable {
  final String id;
  final String ticker;
  final double targetPrice;
  final double tolerancePercent;
  final bool isActive;
  final bool alertSent;
  final DateTime? alertSentAt;
  // The price the last buy notification actually fired at. Not one-shot:
  // once the threshold is crossed, the alert keeps firing again each further
  // 1% drop (tracking a continuing better entry), rather than deactivating
  // after the first notification.
  final double? lastAlertPrice;
  final DateTime createdAt;

  const PriceAlert({
    required this.id,
    required this.ticker,
    required this.targetPrice,
    this.tolerancePercent = 1.0,
    this.isActive = true,
    this.alertSent = false,
    this.alertSentAt,
    this.lastAlertPrice,
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
    double? lastAlertPrice,
    DateTime? createdAt,
  }) {
    final targetChanged = (targetPrice != null && targetPrice != this.targetPrice) ||
        (tolerancePercent != null && tolerancePercent != this.tolerancePercent);

    return PriceAlert(
      id: id ?? this.id,
      ticker: ticker ?? this.ticker,
      targetPrice: targetPrice ?? this.targetPrice,
      tolerancePercent: tolerancePercent ?? this.tolerancePercent,
      // Editing the target/tolerance re-arms a fired alert — otherwise
      // lowering an already-triggered alert's target would silently stay
      // dormant forever, since nothing else ever flips isActive back on.
      isActive: targetChanged ? true : (isActive ?? this.isActive),
      alertSent: targetChanged ? false : (alertSent ?? this.alertSent),
      alertSentAt: targetChanged ? null : (clearAlertSentAt ? null : (alertSentAt ?? this.alertSentAt)),
      lastAlertPrice: targetChanged ? null : (lastAlertPrice ?? this.lastAlertPrice),
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
        lastAlertPrice,
        createdAt,
      ];
}

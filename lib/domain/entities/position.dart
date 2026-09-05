import 'package:equatable/equatable.dart';
import 'package:stock_investment_tracker/domain/entities/position_buy.dart';
import 'package:stock_investment_tracker/domain/entities/position_sale.dart';
import 'package:stock_investment_tracker/domain/enums/position_status.dart';

class Position extends Equatable {
  final String id;
  final String ticker;
  final PositionStatus status;
  final DateTime openedAt;
  final DateTime? closedAt;
  final double? targetPrice;
  final bool targetAlertSent;
  final DateTime? targetAlertSentAt;
  // The price the last sell notification actually fired at. Re-notifying
  // once the target is crossed isn't one-shot: once true, the position keeps
  // firing again each further 1% climb (tracking realised profit as it
  // grows), rather than going silent after the first alert.
  final double? lastAlertPrice;
  final List<PositionBuy> buys;
  final List<PositionSale> sales;

  const Position({
    required this.id,
    required this.ticker,
    required this.status,
    required this.openedAt,
    this.closedAt,
    this.targetPrice,
    this.targetAlertSent = false,
    this.targetAlertSentAt,
    this.lastAlertPrice,
    this.buys = const [],
    this.sales = const [],
  });

  Position copyWith({
    String? id,
    String? ticker,
    PositionStatus? status,
    DateTime? openedAt,
    DateTime? closedAt,
    double? targetPrice,
    bool clearTargetPrice = false,
    bool? targetAlertSent,
    DateTime? targetAlertSentAt,
    bool clearTargetAlertSentAt = false,
    double? lastAlertPrice,
    List<PositionBuy>? buys,
    List<PositionSale>? sales,
  }) {
    final newTargetPrice = clearTargetPrice ? null : (targetPrice ?? this.targetPrice);
    final targetPriceChanged = newTargetPrice != this.targetPrice;

    return Position(
      id: id ?? this.id,
      ticker: ticker ?? this.ticker,
      status: status ?? this.status,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      targetPrice: newTargetPrice,
      targetAlertSent: targetPriceChanged ? false : (targetAlertSent ?? this.targetAlertSent),
      targetAlertSentAt: targetPriceChanged ? null : (clearTargetAlertSentAt ? null : (targetAlertSentAt ?? this.targetAlertSentAt)),
      // A changed target starts the "how far past the target has it moved
      // since the last alert" tracking fresh — otherwise a new, lower target
      // would inherit a stale high-water mark from the old one and could
      // silently suppress a notification that should fire immediately.
      lastAlertPrice: targetPriceChanged ? null : (lastAlertPrice ?? this.lastAlertPrice),
      buys: buys ?? this.buys,
      sales: sales ?? this.sales,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ticker,
        status,
        openedAt,
        closedAt,
        targetPrice,
        targetAlertSent,
        targetAlertSentAt,
        lastAlertPrice,
        buys,
        sales,
      ];
}

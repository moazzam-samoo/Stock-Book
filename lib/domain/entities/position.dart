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
  final List<PositionBuy> buys;
  final List<PositionSale> sales;

  const Position({
    required this.id,
    required this.ticker,
    required this.status,
    required this.openedAt,
    this.closedAt,
    this.targetPrice,
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
    List<PositionBuy>? buys,
    List<PositionSale>? sales,
  }) {
    return Position(
      id: id ?? this.id,
      ticker: ticker ?? this.ticker,
      status: status ?? this.status,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      targetPrice: targetPrice ?? this.targetPrice,
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
        buys,
        sales,
      ];
}

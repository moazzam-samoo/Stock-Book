import 'package:stock_investment_tracker/domain/enums/lot_status.dart';

class StockSummary {
  final String ticker;
  final int sharesHeld;
  final double amountInvestedOpen;
  final double realizedPL;
  final double avgBuyPrice;
  final LotStatus status;
  final double allocationPercent;

  const StockSummary({
    required this.ticker,
    required this.sharesHeld,
    required this.amountInvestedOpen,
    required this.realizedPL,
    required this.avgBuyPrice,
    required this.status,
    required this.allocationPercent,
  });
}

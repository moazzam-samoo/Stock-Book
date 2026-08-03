import 'package:stock_investment_tracker/domain/entities/sale.dart';
import 'package:stock_investment_tracker/domain/enums/lot_status.dart';

import 'package:equatable/equatable.dart';

class Lot extends Equatable {
  final String id;
  final String ticker;
  final DateTime buyDate;
  final int sharesPurchased;
  final double buyPricePerShare;
  final double amountInvested;
  final List<Sale> sales;
  
  // Derived fields that can be attached to the entity after calculation
  final int sharesRemaining;
  final double amountInvestedRemaining;
  final double realizedProfitLoss;
  final LotStatus status;

  const Lot({
    required this.id,
    required this.ticker,
    required this.buyDate,
    required this.sharesPurchased,
    required this.buyPricePerShare,
    required this.amountInvested,
    this.sales = const [],
    this.sharesRemaining = 0,
    this.amountInvestedRemaining = 0.0,
    this.realizedProfitLoss = 0.0,
    this.status = LotStatus.open,
  });

  Lot copyWith({
    String? id,
    String? ticker,
    DateTime? buyDate,
    int? sharesPurchased,
    double? buyPricePerShare,
    double? amountInvested,
    List<Sale>? sales,
    int? sharesRemaining,
    double? amountInvestedRemaining,
    double? realizedProfitLoss,
    LotStatus? status,
  }) {
    return Lot(
      id: id ?? this.id,
      ticker: ticker ?? this.ticker,
      buyDate: buyDate ?? this.buyDate,
      sharesPurchased: sharesPurchased ?? this.sharesPurchased,
      buyPricePerShare: buyPricePerShare ?? this.buyPricePerShare,
      amountInvested: amountInvested ?? this.amountInvested,
      sales: sales ?? this.sales,
      sharesRemaining: sharesRemaining ?? this.sharesRemaining,
      amountInvestedRemaining: amountInvestedRemaining ?? this.amountInvestedRemaining,
      realizedProfitLoss: realizedProfitLoss ?? this.realizedProfitLoss,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ticker,
        buyDate,
        sharesPurchased,
        buyPricePerShare,
        amountInvested,
        sales,
        sharesRemaining,
        amountInvestedRemaining,
        realizedProfitLoss,
        status,
      ];
}

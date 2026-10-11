import 'package:equatable/equatable.dart';
import 'package:stock_investment_tracker/domain/entities/tax_settings.dart';

/// Detailed breakdown of charges for a trade (buy or sell).
class TradeChargeBreakdown extends Equatable {
  final double tradeValue;
  final double cdc;
  final double psxLaga;
  final double secpLaga;
  final double nccpl;
  final double commission;
  final double sst;
  final double otherCharges;

  const TradeChargeBreakdown({
    required this.tradeValue,
    required this.cdc,
    required this.psxLaga,
    required this.secpLaga,
    required this.nccpl,
    required this.commission,
    required this.sst,
    required this.otherCharges,
  });

  /// Other Transaction Charges (PSX Laga + SECP Laga + NCCPL)
  double get otc => _r2(psxLaga + secpLaga + nccpl);

  /// Total sum of all charges & levies
  double get total =>
      _r2(cdc + psxLaga + secpLaga + nccpl + commission + sst + otherCharges);

  static double _r2(double v) => ((v + 1e-9) * 100).roundToDouble() / 100;

  @override
  List<Object?> get props => [
        tradeValue,
        cdc,
        psxLaga,
        secpLaga,
        nccpl,
        commission,
        sst,
        otherCharges,
      ];
}

/// Pure Dart calculator for Pakistan Stock Exchange (PSX) charges and taxes.
class TradeChargeCalculator {
  static double _r2(double v) => ((v + 1e-9) * 100).roundToDouble() / 100;

  /// Calculates individual charge breakdown for a single trade execution (buy or sell).
  static TradeChargeBreakdown calculateCharges({
    required int quantity,
    required double pricePerShare,
    required EffectiveTaxRates rates,
  }) {
    if (!rates.taxEnabled || quantity <= 0 || pricePerShare <= 0) {
      return const TradeChargeBreakdown(
        tradeValue: 0.0,
        cdc: 0.0,
        psxLaga: 0.0,
        secpLaga: 0.0,
        nccpl: 0.0,
        commission: 0.0,
        sst: 0.0,
        otherCharges: 0.0,
      );
    }

    final tradeValue = _r2(quantity * pricePerShare);
    final commission = _r2(tradeValue * rates.commissionRate);
    final sst = _r2(commission * rates.sstRate);
    final cdc = _r2(quantity * rates.cdcPerShare);
    final psxLaga = _r2(tradeValue * rates.psxLagaRate);
    final secpLaga = _r2(tradeValue * rates.secpLagaRate);
    final nccpl = _r2(tradeValue * rates.nccplRate);
    final other = _r2(rates.otherCharges);

    return TradeChargeBreakdown(
      tradeValue: tradeValue,
      cdc: cdc,
      psxLaga: psxLaga,
      secpLaga: secpLaga,
      nccpl: nccpl,
      commission: commission,
      sst: sst,
      otherCharges: other,
    );
  }

  /// Net amount paid for a BUY trade (trade value + total charges).
  static double netBuyAmount({
    required int quantity,
    required double pricePerShare,
    required EffectiveTaxRates rates,
  }) {
    final breakdown = calculateCharges(
      quantity: quantity,
      pricePerShare: pricePerShare,
      rates: rates,
    );
    return _r2(breakdown.tradeValue + breakdown.total);
  }

  /// Net amount received from a SELL trade (trade value - total charges).
  static double netSellAmount({
    required int quantity,
    required double pricePerShare,
    required EffectiveTaxRates rates,
  }) {
    final breakdown = calculateCharges(
      quantity: quantity,
      pricePerShare: pricePerShare,
      rates: rates,
    );
    return _r2(breakdown.tradeValue - breakdown.total);
  }

  /// Calculates Capital Gains Tax (CGT) on positive net profit.
  static double calculateCgt(double profit, EffectiveTaxRates rates) {
    if (!rates.taxEnabled || profit <= 0.0 || rates.cgtRate <= 0.0) {
      return 0.0;
    }
    return _r2(profit * rates.cgtRate);
  }

  /// Calculates net realized profit/loss for a sale, deducting:
  /// 1. Proportional buy charges for the shares sold
  /// 2. Sell trade charges
  /// 3. Capital Gains Tax (CGT) if profit is positive
  static double calculateNetRealizedPL({
    required int sharesSold,
    required double sellPrice,
    required double costBasisPerShare,
    required int totalBuyShares,
    required double buyPricePerShare,
    required EffectiveTaxRates rates,
  }) {
    if (!rates.taxEnabled) {
      // Gross realized P/L
      return _r2(sharesSold * (sellPrice - costBasisPerShare));
    }

    // 1. Gross profit/loss
    final grossPL = sharesSold * (sellPrice - costBasisPerShare);

    // 2. Buy charges allocated proportionally to the sold shares
    final totalBuyCharges = calculateCharges(
      quantity: totalBuyShares,
      pricePerShare: buyPricePerShare,
      rates: rates,
    ).total;

    final double allocatedBuyCharges = totalBuyShares > 0
        ? _r2((sharesSold / totalBuyShares) * totalBuyCharges)
        : 0.0;

    // 3. Sell charges on this sale
    final sellCharges = calculateCharges(
      quantity: sharesSold,
      pricePerShare: sellPrice,
      rates: rates,
    ).total;

    // 4. Profit before CGT
    final profitBeforeCgt = _r2(grossPL - allocatedBuyCharges - sellCharges);

    // 5. CGT (only on positive profit)
    final cgt = calculateCgt(profitBeforeCgt, rates);

    return _r2(profitBeforeCgt - cgt);
  }
}

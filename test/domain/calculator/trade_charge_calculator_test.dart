import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/domain/calculator/trade_charge_calculator.dart';
import 'package:stock_investment_tracker/domain/entities/admin_tax_rates.dart';
import 'package:stock_investment_tracker/domain/entities/tax_settings.dart';

void main() {
  group('TradeChargeCalculator PSX Statement Tests', () {
    const adminRates = AdminTaxRates.psxDefaults;
    final effectiveRates = const TaxSettings(taxEnabled: true).resolveEffective(adminRates);

    test('Case 1: BUY 2,000 TISL @ Rs 4.91', () {
      final breakdown = TradeChargeCalculator.calculateCharges(
        quantity: 2000,
        pricePerShare: 4.91,
        rates: effectiveRates,
      );

      expect(breakdown.tradeValue, 9820.00);
      expect(breakdown.cdc, 5.00);
      expect(breakdown.psxLaga, 0.42);
      expect(breakdown.secpLaga, 0.06);
      expect(breakdown.nccpl, 0.41);
      expect(breakdown.commission, 0.00);
      expect(breakdown.sst, 0.00);
      expect(breakdown.total, 5.89);

      final netBuy = TradeChargeCalculator.netBuyAmount(
        quantity: 2000,
        pricePerShare: 4.91,
        rates: effectiveRates,
      );
      expect(netBuy, 9825.89);
    });

    test('Case 2: SELL 94 TISL @ Rs 4.94', () {
      final breakdown = TradeChargeCalculator.calculateCharges(
        quantity: 94,
        pricePerShare: 4.94,
        rates: effectiveRates,
      );

      expect(breakdown.tradeValue, closeTo(464.36, 0.01));
      expect(breakdown.cdc, 0.24);
      expect(breakdown.psxLaga, 0.02);
      expect(breakdown.secpLaga, 0.00);
      expect(breakdown.nccpl, 0.02);
      expect(breakdown.total, closeTo(0.28, 0.02));
    });

    test('Case 3: SELL 1,906 TISL @ Rs 4.99', () {
      final breakdown = TradeChargeCalculator.calculateCharges(
        quantity: 1906,
        pricePerShare: 4.99,
        rates: effectiveRates,
      );

      expect(breakdown.tradeValue, closeTo(9510.94, 0.01));
      expect(breakdown.cdc, 4.77);
      expect(breakdown.psxLaga, 0.40);
      expect(breakdown.secpLaga, 0.06);
      expect(breakdown.nccpl, 0.40);
      expect(breakdown.total, closeTo(5.63, 0.02));
    });

    test('Round-Trip Full Profit Matches Statement (~Rs 143.51)', () {
      // Worked example from statement:
      // Buy: 2,000 @ 4.91 (charges 5.89)
      // Sell 1: 94 @ 4.94
      // Sell 2: 1906 @ 4.99
      final netPL1 = TradeChargeCalculator.calculateNetRealizedPL(
        sharesSold: 94,
        sellPrice: 4.94,
        costBasisPerShare: 4.91,
        totalBuyShares: 2000,
        buyPricePerShare: 4.91,
        rates: effectiveRates,
      );

      final netPL2 = TradeChargeCalculator.calculateNetRealizedPL(
        sharesSold: 1906,
        sellPrice: 4.99,
        costBasisPerShare: 4.91,
        totalBuyShares: 2000,
        buyPricePerShare: 4.91,
        rates: effectiveRates,
      );

      final totalNet = netPL1 + netPL2;
      // Expected statement net profit is ~143.51
      expect(totalNet, closeTo(143.51, 0.15));
    });

    test('When taxEnabled is false, charges are 0 and gross PL is returned', () {
      const disabledRates = EffectiveTaxRates.disabled;
      final breakdown = TradeChargeCalculator.calculateCharges(
        quantity: 2000,
        pricePerShare: 4.91,
        rates: disabledRates,
      );

      expect(breakdown.total, 0.0);

      final netPL = TradeChargeCalculator.calculateNetRealizedPL(
        sharesSold: 100,
        sellPrice: 50.0,
        costBasisPerShare: 40.0,
        totalBuyShares: 100,
        buyPricePerShare: 40.0,
        rates: disabledRates,
      );

      // Gross profit is 100 * (50 - 40) = 1000
      expect(netPL, 1000.0);
    });

    test('CGT only deducts on positive profit', () {
      final ratesWithCgt = const TaxSettings(
        taxEnabled: true,
        cgtRate: 0.15, // 15% CGT
      ).resolveEffective(adminRates);

      // On loss (-200 profit)
      final cgtOnLoss = TradeChargeCalculator.calculateCgt(-200.0, ratesWithCgt);
      expect(cgtOnLoss, 0.0);

      // On profit (+1000 profit)
      final cgtOnProfit = TradeChargeCalculator.calculateCgt(1000.0, ratesWithCgt);
      expect(cgtOnProfit, 150.0);
    });

    test('Custom user override takes precedence over admin default', () {
      final customSettings = const TaxSettings(
        taxEnabled: true,
        cdcPerShare: 0.0050, // User override
      );

      final resolved = customSettings.resolveEffective(adminRates);
      expect(resolved.cdcPerShare, 0.0050);
      expect(resolved.psxLagaRate, adminRates.psxLagaRate); // Default inherited
    });
  });
}

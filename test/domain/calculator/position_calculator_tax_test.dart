import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/domain/calculator/position_calculator.dart';
import 'package:stock_investment_tracker/domain/calculator/portfolio_calculator.dart';
import 'package:stock_investment_tracker/domain/entities/admin_tax_rates.dart';
import 'package:stock_investment_tracker/domain/entities/position.dart';
import 'package:stock_investment_tracker/domain/entities/position_buy.dart';
import 'package:stock_investment_tracker/domain/entities/position_sale.dart';
import 'package:stock_investment_tracker/domain/entities/tax_settings.dart';
import 'package:stock_investment_tracker/domain/enums/position_status.dart';

void main() {
  group('PositionCalculator Tax Integration', () {
    const adminRates = AdminTaxRates.psxDefaults;
    final enabledRates =
        const TaxSettings(taxEnabled: true).resolveEffective(adminRates);

    final position = Position(
      id: 'pos-1',
      ticker: 'TISL',
      status: PositionStatus.closed,
      openedAt: DateTime(2026, 10, 8),
      buys: [
        PositionBuy(
          id: 'buy-1',
          date: DateTime(2026, 10, 8),
          shares: 2000,
          pricePerShare: 4.91,
        ),
      ],
      sales: [
        PositionSale(
          id: 'sale-1',
          date: DateTime(2026, 10, 9),
          shares: 94,
          pricePerShare: 4.94,
          costBasisAtSale: 4.91,
        ),
        PositionSale(
          id: 'sale-2',
          date: DateTime(2026, 10, 9),
          shares: 1906,
          pricePerShare: 4.99,
          costBasisAtSale: 4.91,
        ),
      ],
    );

    test('Gross vs Net Realized P/L', () {
      final grossPL = PositionCalculator.realizedPL(position);
      final netPL = PositionCalculator.realizedPLWithTax(position, enabledRates);
      final charges = PositionCalculator.totalCharges(position, enabledRates);

      expect(grossPL, closeTo(155.30, 0.05));
      expect(netPL, closeTo(143.51, 0.15));
      expect(charges, closeTo(11.79, 0.15));
    });

    test('Single sale net profit and charges', () {
      final sale1 = position.sales[0];
      final sale1Net = PositionCalculator.saleRealizedPLWithTax(
        position,
        sale1,
        enabledRates,
      );
      final sale1Charges = PositionCalculator.saleCharges(
        position,
        sale1,
        enabledRates,
      );

      expect(sale1.realizedPL, closeTo(2.82, 0.05));
      expect(sale1Net, closeTo(2.13, 0.15));
      expect(sale1Charges, closeTo(0.69, 0.15));
    });

    test('calculateStockSummariesFromPositions reflects net P/L when enabled', () {
      final summaries = PortfolioCalculator.calculateStockSummariesFromPositions(
        [position],
        enabledRates,
      );

      expect(summaries.length, 1);
      expect(summaries[0].ticker, 'TISL');
      expect(summaries[0].realizedPL, closeTo(143.51, 0.15));
    });

    test('Zero charges when taxes are disabled', () {
      const disabledRates = EffectiveTaxRates.disabled;
      final netPL = PositionCalculator.realizedPLWithTax(position, disabledRates);
      final charges = PositionCalculator.totalCharges(position, disabledRates);

      expect(netPL, PositionCalculator.realizedPL(position));
      expect(charges, 0.0);
    });
  });
}

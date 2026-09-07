import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/domain/calculator/portfolio_calculator.dart';
import 'package:stock_investment_tracker/domain/calculator/position_calculator.dart';
import 'package:stock_investment_tracker/domain/entities/position.dart';
import 'package:stock_investment_tracker/domain/entities/position_buy.dart';
import 'package:stock_investment_tracker/domain/enums/lot_status.dart';

/// Phase 03C tests 5-6: the dashboard shows one row per **ticker**, even when
/// that ticker has several holding cycles. Realized profit from closed cycles
/// must survive the grouping — hiding sold-out tickers is the dashboard
/// widget's job, not this function's.
void main() {
  Position closedCycle({
    required String ticker,
    required String idSuffix,
    required int shares,
    required double buyPrice,
    required double sellPrice,
  }) {
    final open = PositionCalculator.replay(
      ticker,
      [
        PositionBuy(
          id: 'b$idSuffix',
          date: DateTime.parse('2026-06-01'),
          shares: shares,
          pricePerShare: buyPrice,
        ),
      ],
      [],
    ).first;
    return PositionCalculator.applySell(
      open,
      saleId: 's$idSuffix',
      date: DateTime.parse('2026-06-20'),
      shares: shares,
      pricePerShare: sellPrice,
    ).copyWith(id: 'pos-closed-$idSuffix');
  }

  Position openCycle({
    required String ticker,
    required String idSuffix,
    required int shares,
    required double buyPrice,
  }) {
    return PositionCalculator.replay(
      ticker,
      [
        PositionBuy(
          id: 'b$idSuffix',
          date: DateTime.parse('2026-08-31'),
          shares: shares,
          pricePerShare: buyPrice,
        ),
      ],
      [],
    ).first.copyWith(id: 'pos-open-$idSuffix');
  }

  test('a ticker with a closed cycle AND a fresh, never-sold-from open one reads as Open', () {
    // The open cycle here has never had a sale — a past, fully-closed cycle
    // for the same ticker must not make this read as "Partial". "Partial"
    // means "of what I currently hold, I've sold part of it" (matching how
    // an individual Position's own status badge works elsewhere in the
    // app), not "this ticker has ever had any sale in its history".
    final positions = [
      closedCycle(ticker: 'STPL', idSuffix: '1', shares: 1000, buyPrice: 5.0, sellPrice: 6.0),
      openCycle(ticker: 'STPL', idSuffix: '2', shares: 500, buyPrice: 8.0),
    ];

    final summaries = PortfolioCalculator.calculateStockSummariesFromPositions(positions);

    expect(summaries.length, 1);
    final stpl = summaries.single;
    expect(stpl.ticker, 'STPL');

    // Shares and cost come from the cycle still held.
    expect(stpl.sharesHeld, 500);
    expect(stpl.avgBuyPrice, 8.0);
    expect(stpl.amountInvestedOpen, 4000.0);

    // Profit from the CLOSED cycle is booked and must not vanish: 1000 × 1.00.
    expect(stpl.realizedPL, 1000.0);

    // Fully held, never partially sold from — reads as Open, not Partial.
    expect(stpl.status, LotStatus.open);
  });

  test('a ticker whose currently-held cycle has itself been partially sold reads as Partial', () {
    final partiallySoldOpenCycle = PositionCalculator.applySell(
      PositionCalculator.replay(
        'STPL',
        [
          PositionBuy(
            id: 'b3',
            date: DateTime.parse('2026-08-31'),
            shares: 500,
            pricePerShare: 8.0,
          ),
        ],
        [],
      ).first,
      saleId: 's3',
      date: DateTime.parse('2026-09-05'),
      shares: 200,
      pricePerShare: 9.0,
    ).copyWith(id: 'pos-open-3');

    final summaries = PortfolioCalculator.calculateStockSummariesFromPositions([
      partiallySoldOpenCycle,
    ]);

    expect(summaries.single.status, LotStatus.partiallySold);
    expect(summaries.single.sharesHeld, 300);
  });

  test('a fully-closed ticker still yields a row carrying its realized profit', () {
    final positions = [
      closedCycle(ticker: 'OGDC', idSuffix: '1', shares: 200, buyPrice: 100.0, sellPrice: 110.0),
    ];

    final summaries = PortfolioCalculator.calculateStockSummariesFromPositions(positions);

    expect(summaries.length, 1);
    final ogdc = summaries.single;
    expect(ogdc.sharesHeld, 0);
    expect(ogdc.amountInvestedOpen, 0.0);
    expect(ogdc.realizedPL, 2000.0);
    expect(ogdc.status, LotStatus.closed);
    expect(ogdc.avgBuyPrice, 0.0);

    // The dashboard hides this row itself (sharesHeld == 0) — the calculator
    // stays complete so the PDF report and metric drill-downs keep the profit.
  });

  test('an untouched ticker reads as open', () {
    final summaries = PortfolioCalculator.calculateStockSummariesFromPositions([
      openCycle(ticker: 'ENGRO', idSuffix: '1', shares: 300, buyPrice: 350.0),
    ]);
    expect(summaries.single.status, LotStatus.open);
    expect(summaries.single.sharesHeld, 300);
  });

  test('separate tickers stay separate rows', () {
    final positions = [
      openCycle(ticker: 'STPL', idSuffix: '1', shares: 500, buyPrice: 8.0),
      openCycle(ticker: 'ENGRO', idSuffix: '2', shares: 300, buyPrice: 350.0),
      closedCycle(ticker: 'OGDC', idSuffix: '3', shares: 100, buyPrice: 100.0, sellPrice: 105.0),
    ];

    final summaries = PortfolioCalculator.calculateStockSummariesFromPositions(positions);

    expect(summaries.map((s) => s.ticker).toSet(), {'STPL', 'ENGRO', 'OGDC'});
    expect(summaries.length, 3);
  });
}

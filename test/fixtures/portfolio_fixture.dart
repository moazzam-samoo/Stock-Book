import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/domain/entities/sale.dart';
import 'package:stock_investment_tracker/domain/entities/withdrawal.dart';
import 'package:stock_investment_tracker/domain/calculator/portfolio_calculator.dart';

class PortfolioFixture {
  static final List<Lot> baseLots = [
    Lot(
      id: 'lot-stpl-1',
      ticker: 'STPL',
      buyDate: DateTime.parse('2026-08-31'),
      sharesPurchased: 500,
      buyPricePerShare: 8.73,
      amountInvested: 4365.0,
      targetPrice: 10.00,
      sales: [
        Sale(id: 's1', sellDate: DateTime.parse('2026-09-01'), sharesSold: 200, sellPricePerShare: 9.00, amountReceived: 1800.0),
        Sale(id: 's2', sellDate: DateTime.parse('2026-09-02'), sharesSold: 100, sellPricePerShare: 8.50, amountReceived: 850.0),
      ],
    ),
    Lot(
      id: 'lot-stpl-2',
      ticker: 'STPL',
      buyDate: DateTime.parse('2026-09-07'),
      sharesPurchased: 1200,
      buyPricePerShare: 8.38,
      amountInvested: 10056.0,
      targetPrice: null,
      sales: [
        Sale(id: 's3', sellDate: DateTime.parse('2026-09-08'), sharesSold: 1200, sellPricePerShare: 9.10, amountReceived: 10920.0),
      ],
    ),
    Lot(
      id: 'lot-engro-1',
      ticker: 'ENGRO',
      buyDate: DateTime.parse('2026-07-15'),
      sharesPurchased: 300,
      buyPricePerShare: 350.00,
      amountInvested: 105000.0,
      targetPrice: 400.00,
      sales: [
        Sale(id: 's4', sellDate: DateTime.parse('2026-07-20'), sharesSold: 100, sellPricePerShare: 380.0, amountReceived: 38000.0),
        Sale(id: 's5', sellDate: DateTime.parse('2026-07-25'), sharesSold: 100, sellPricePerShare: 340.0, amountReceived: 34000.0),
        Sale(id: 's6', sellDate: DateTime.parse('2026-08-05'), sharesSold: 100, sellPricePerShare: 390.0, amountReceived: 39000.0),
      ],
    ),
    Lot(
      id: 'lot-engro-2',
      ticker: 'ENGRO',
      buyDate: DateTime.parse('2026-08-01'),
      sharesPurchased: 500,
      buyPricePerShare: 360.00,
      amountInvested: 180000.0,
      targetPrice: null,
      sales: [
        Sale(id: 's7', sellDate: DateTime.parse('2026-08-10'), sharesSold: 200, sellPricePerShare: 370.0, amountReceived: 74000.0),
        Sale(id: 's8', sellDate: DateTime.parse('2026-08-15'), sharesSold: 50, sellPricePerShare: 350.0, amountReceived: 17500.0),
      ],
    ),
    Lot(
      id: 'lot-sys-1',
      ticker: 'SYS',
      buyDate: DateTime.parse('2026-08-20'),
      sharesPurchased: 100,
      buyPricePerShare: 520.00,
      amountInvested: 52000.0,
      targetPrice: 600.00,
      sales: [
        Sale(id: 's9', sellDate: DateTime.parse('2026-08-25'), sharesSold: 40, sellPricePerShare: 550.0, amountReceived: 22000.0),
      ],
    ),
    Lot(
      id: 'lot-sys-2',
      ticker: 'SYS',
      buyDate: DateTime.parse('2026-09-01'),
      sharesPurchased: 200,
      buyPricePerShare: 510.00,
      amountInvested: 102000.0,
      targetPrice: null,
      sales: [
        Sale(id: 's10', sellDate: DateTime.parse('2026-09-05'), sharesSold: 100, sellPricePerShare: 530.0, amountReceived: 53000.0),
        Sale(id: 's11', sellDate: DateTime.parse('2026-09-10'), sharesSold: 100, sellPricePerShare: 490.0, amountReceived: 49000.0),
      ],
    ),
    Lot(
      id: 'lot-ogdc-1',
      ticker: 'OGDC',
      buyDate: DateTime.parse('2026-08-10'),
      sharesPurchased: 400,
      buyPricePerShare: 100.00,
      amountInvested: 40000.0,
      targetPrice: 120.00,
      sales: [],
    ),
    Lot(
      id: 'lot-ogdc-2',
      ticker: 'OGDC',
      buyDate: DateTime.parse('2026-08-15'),
      sharesPurchased: 600,
      buyPricePerShare: 105.00,
      amountInvested: 63000.0,
      targetPrice: null,
      sales: [
        Sale(id: 's12', sellDate: DateTime.parse('2026-08-20'), sharesSold: 200, sellPricePerShare: 98.00, amountReceived: 19600.0),
      ],
    ),
  ];

  static final List<Withdrawal> baseWithdrawals = [
    Withdrawal(id: 'w1', date: DateTime.parse('2026-08-20'), amount: 15000.0, note: 'w1'),
    Withdrawal(id: 'w2', date: DateTime.parse('2026-09-01'), amount: 7500.0, note: 'w2'),
  ];

  static List<Lot> get enrichedLots => baseLots.map((l) => PortfolioCalculator.enrichLot(l)).toList();
  static double get totalWithdrawn => PortfolioCalculator.calculateTotalWithdrawn(baseWithdrawals);
}

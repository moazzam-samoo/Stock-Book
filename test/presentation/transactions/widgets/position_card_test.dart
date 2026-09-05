import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';
import 'package:stock_investment_tracker/domain/calculator/position_calculator.dart';
import 'package:stock_investment_tracker/domain/entities/position.dart';
import 'package:stock_investment_tracker/domain/entities/position_buy.dart';
import 'package:stock_investment_tracker/domain/entities/market_price.dart';
import 'package:stock_investment_tracker/domain/enums/position_status.dart';
import 'package:stock_investment_tracker/domain/repositories/market_price_repository.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/position_card.dart';
import 'package:stock_investment_tracker/providers/repository_providers.dart';

/// PositionCard renders several of its detail lines as raw `RichText` (not
/// the `Text`/`Text.rich` widgets `find.text`/`find.textContaining` look
/// inside), so this walks every RichText's flattened plain text instead.
Finder findRichTextContaining(String substring) {
  return find.byWidgetPredicate(
    (widget) => widget is RichText && widget.text.toPlainText().contains(substring),
  );
}

/// Phase 03B required widget tests 11-12: PositionCard is what proves the
/// merge is visible in the UI, not just correct in the calculator.
void main() {
  // Same two buys as the STPL reference case used throughout Phase 03A/03B.
  final position = Position(
    id: 'pos-stpl',
    ticker: 'STPL',
    status: PositionStatus.open,
    openedAt: DateTime.parse('2026-08-31'),
    buys: [
      PositionBuy(id: 'b1', date: DateTime.parse('2026-08-31'), shares: 500, pricePerShare: 8.73),
      PositionBuy(id: 'b2', date: DateTime.parse('2026-09-07'), shares: 1200, pricePerShare: 8.38),
    ],
  );

  Widget wrap(Widget child, {MarketPriceRepository? marketPriceRepository}) {
    return ProviderScope(
      overrides: [
        if (marketPriceRepository != null)
          marketPriceRepositoryProvider.overrideWithValue(marketPriceRepository),
      ],
      child: MaterialApp(
        // PositionCard is always inside a scrolling parent in production
        // (ListView.builder / CustomScrollView) — matched here so an expanded
        // card growing past the test viewport's fixed height isn't a false
        // overflow failure.
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  testWidgets(
    'test 11: two buys of one ticker render as ONE card showing the blended average',
    (tester) async {
      await tester.pumpWidget(wrap(PositionCard(position: position, showStockDetailNavigation: false)));
      await tester.pumpAndSettle();

      // Exactly one card — one ticker, one avatar/header, not two.
      expect(find.byType(PositionCard), findsOneWidget);

      // Total shares across both buys (500 + 1200), not either buy alone.
      expect(find.textContaining('1,700 sh'), findsOneWidget);

      // The blended avg cost — PositionCalculator.avgCost, not either buy's
      // own price (8.73 or 8.38).
      final avgCost = PositionCalculator.avgCost(position);
      expect(avgCost, 8.48);
      expect(findRichTextContaining('8.48'), findsWidgets);
    },
  );

  testWidgets(
    'a closed position shows what the cycle cost, not Rs 0, and is badged CLOSED',
    (tester) async {
      // The exact shape of the reported STPL card: everything bought was sold.
      final closed = PositionCalculator.applySell(
        position,
        saleId: 's1',
        date: DateTime.parse('2026-09-08'),
        shares: 1700,
        pricePerShare: 9.0,
      );
      expect(closed.status, PositionStatus.closed);

      await tester.pumpWidget(wrap(PositionCard(position: closed, showStockDetailNavigation: false)));
      await tester.pumpAndSettle();

      // The badge used to read OPEN for every position regardless of status.
      expect(find.text('CLOSED'), findsOneWidget);
      expect(find.text('OPEN'), findsNothing);

      // avgCost/amountInvested are 0 once nothing is held; the card must fall
      // back to the cycle's historical figures instead of printing "Rs 0".
      expect(PositionCalculator.avgCost(closed), 0.0);
      expect(findRichTextContaining('Rs 0'), findsNothing);
      expect(findRichTextContaining('8.48'), findsWidgets); // historical avg cost
      expect(findRichTextContaining('Total Cost'), findsOneWidget);
    },
  );

  testWidgets(
    'a split closed cycle renders one card per buy, each with its own cost and profit',
    (tester) async {
      final closed = PositionCalculator.applySell(
        position,
        saleId: 's1',
        date: DateTime.parse('2026-09-10'),
        shares: 1700,
        pricePerShare: 9.0,
      );
      final slices = PositionCalculator.splitByBuy(closed);
      expect(slices.length, 2);

      await tester.pumpWidget(wrap(
        Column(
          children: [
            for (final slice in slices)
              PositionCard(
                position: slice,
                showStockDetailNavigation: false,
                writePosition: closed,
              ),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      // Two distinct cards, both CLOSED — not one merged card.
      expect(find.byType(PositionCard), findsNWidgets(2));
      expect(find.text('CLOSED'), findsNWidgets(2));

      // Each card is headed by its own buy's share count, not the pooled 1,700.
      expect(find.text('500 sh'), findsOneWidget);
      expect(find.text('1,200 sh'), findsOneWidget);
      expect(find.text('1,700 sh'), findsNothing);

      // And each shows the price that buy was actually made at.
      expect(findRichTextContaining('8.73'), findsWidgets);
      expect(findRichTextContaining('8.38'), findsWidgets);
    },
  );

  testWidgets(
    'test 12: expanding the card shows both original buys — their own dates and prices',
    (tester) async {
      await tester.pumpWidget(wrap(PositionCard(position: position, showStockDetailNavigation: false)));
      await tester.pumpAndSettle();

      // Buy history is collapsed by default.
      expect(find.text('BUY HISTORY'), findsNothing);

      await tester.tap(find.byType(PositionCard));
      await tester.pumpAndSettle();

      expect(find.text('BUY HISTORY'), findsOneWidget);

      final dateFormat = DateFormat('MMM d, y');
      // Buy 1: 500 sh @ 8.73 on 2026-08-31 — its own price/date, not the average.
      expect(find.textContaining('Bought ${NumberFormat('#,##0').format(500)} @ ${AppCurrencyFormatter.format(8.73)}'), findsOneWidget);
      expect(find.textContaining(dateFormat.format(DateTime.parse('2026-08-31'))), findsWidgets);

      // Buy 2: 1,200 sh @ 8.38 on 2026-09-07.
      expect(find.textContaining('Bought ${NumberFormat('#,##0').format(1200)} @ ${AppCurrencyFormatter.format(8.38)}'), findsOneWidget);
      expect(find.textContaining(dateFormat.format(DateTime.parse('2026-09-07'))), findsWidgets);
    },
  );

  // --- Phase 04 required tests 10-11 ---

  testWidgets(
    'test 10: no market_prices doc for this ticker shows "—", never Rs 0',
    (tester) async {
      await tester.pumpWidget(wrap(
        PositionCard(position: position, showStockDetailNavigation: false),
        marketPriceRepository: _FakeMarketPriceRepository(price: null),
      ));
      await tester.pumpAndSettle();

      expect(findRichTextContaining('Live Price'), findsOneWidget);
      expect(findRichTextContaining('—'), findsOneWidget);
      // Unrealized P/L only renders once there's a live price to compute it
      // against — with none, it must not appear at all.
      expect(findRichTextContaining('Unrealized'), findsNothing);
    },
  );

  testWidgets(
    'test 11: a stale updatedAt is visually marked, a fresh one is not',
    (tester) async {
      await tester.pumpWidget(wrap(
        PositionCard(position: position, showStockDetailNavigation: false),
        marketPriceRepository: _FakeMarketPriceRepository(
          price: 9.0,
          updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ));
      await tester.pumpAndSettle();

      expect(findRichTextContaining('(Stale)'), findsOneWidget);
    },
  );

  testWidgets(
    'a fresh live price shows no staleness marker',
    (tester) async {
      await tester.pumpWidget(wrap(
        PositionCard(position: position, showStockDetailNavigation: false),
        marketPriceRepository: _FakeMarketPriceRepository(
          price: 9.0,
          updatedAt: DateTime.now(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(findRichTextContaining('(Stale)'), findsNothing);
      // With a live price present, unrealized P/L should now render.
      expect(findRichTextContaining('Unrealized'), findsOneWidget);
    },
  );

  // --- Phase 04B required tests 4-5 ---

  testWidgets(
    'Phase 04B test 4: a fresh price shows an "As of HH:mm" caption',
    (tester) async {
      final updatedAt = DateTime.now();
      await tester.pumpWidget(wrap(
        PositionCard(position: position, showStockDetailNavigation: false),
        marketPriceRepository: _FakeMarketPriceRepository(price: 9.0, updatedAt: updatedAt),
      ));
      await tester.pumpAndSettle();

      expect(findRichTextContaining('As of'), findsOneWidget);
      expect(findRichTextContaining(DateFormat('h:mm a').format(updatedAt)), findsOneWidget);
    },
  );

  testWidgets(
    'Phase 04B test 5: a stale price shows BOTH the stale marker and the "As of HH:mm" caption',
    (tester) async {
      final updatedAt = DateTime.now().subtract(const Duration(hours: 3));
      await tester.pumpWidget(wrap(
        PositionCard(position: position, showStockDetailNavigation: false),
        marketPriceRepository: _FakeMarketPriceRepository(price: 9.0, updatedAt: updatedAt),
      ));
      await tester.pumpAndSettle();

      expect(findRichTextContaining('(Stale)'), findsOneWidget);
      expect(findRichTextContaining('As of'), findsOneWidget);
      expect(findRichTextContaining(DateFormat('h:mm a').format(updatedAt)), findsOneWidget);
    },
  );
}

class _FakeMarketPriceRepository implements MarketPriceRepository {
  final double? price;
  final DateTime? updatedAt;

  _FakeMarketPriceRepository({required this.price, DateTime? updatedAt})
      : updatedAt = updatedAt ?? DateTime.now();

  @override
  Stream<MarketPrice?> watchPrice(String ticker) {
    if (price == null) return Stream.value(null);
    return Stream.value(MarketPrice(
      ticker: ticker,
      price: price!,
      previousClose: price!,
      updatedAt: updatedAt!,
    ));
  }

  @override
  Stream<Map<String, MarketPrice>> watchPrices(List<String> tickers) {
    return Stream.value({});
  }
}

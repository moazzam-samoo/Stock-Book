import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';
import 'package:stock_investment_tracker/domain/calculator/position_calculator.dart';
import 'package:stock_investment_tracker/domain/entities/position.dart';
import 'package:stock_investment_tracker/domain/entities/position_buy.dart';
import 'package:stock_investment_tracker/domain/enums/position_status.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/position_card.dart';

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

  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: child),
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
}

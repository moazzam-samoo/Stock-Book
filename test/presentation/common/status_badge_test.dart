import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/domain/enums/lot_status.dart';
import 'package:stock_investment_tracker/domain/enums/position_status.dart';
import 'package:stock_investment_tracker/presentation/common/badges.dart';

/// Regression cover for a bug that made every position in the app look OPEN.
///
/// `StatusBadge.status` is `dynamic` and handled `TradeStatus` and `LotStatus`
/// only — a `PositionStatus` fell through to `return TradeStatus.open`, with no
/// compile error. A fully-sold position rendered a green OPEN badge.
void main() {
  Future<void> pumpBadge(WidgetTester tester, dynamic status) {
    return tester.pumpWidget(
      MaterialApp(home: Scaffold(body: StatusBadge(status: status))),
    );
  }

  group('StatusBadge with PositionStatus', () {
    testWidgets('open renders OPEN', (tester) async {
      await pumpBadge(tester, PositionStatus.open);
      expect(find.text('OPEN'), findsOneWidget);
    });

    testWidgets('partiallySold renders PARTIAL', (tester) async {
      await pumpBadge(tester, PositionStatus.partiallySold);
      expect(find.text('PARTIAL'), findsOneWidget);
      expect(find.text('OPEN'), findsNothing);
    });

    testWidgets('closed renders CLOSED, not OPEN', (tester) async {
      await pumpBadge(tester, PositionStatus.closed);
      expect(find.text('CLOSED'), findsOneWidget);
      expect(find.text('OPEN'), findsNothing);
    });
  });

  group('StatusBadge still handles the other two enums', () {
    testWidgets('LotStatus.closed renders CLOSED', (tester) async {
      await pumpBadge(tester, LotStatus.closed);
      expect(find.text('CLOSED'), findsOneWidget);
    });

    testWidgets('TradeStatus.partial renders PARTIAL', (tester) async {
      await pumpBadge(tester, TradeStatus.partial);
      expect(find.text('PARTIAL'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/domain/enums/lot_status.dart';
import 'package:stock_investment_tracker/presentation/common/badges.dart';

void main() {
  testWidgets('StatusBadge displays correct text and color for open status', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(status: LotStatus.open),
        ),
      ),
    );

    expect(find.text('OPEN'), findsOneWidget);
  });
}

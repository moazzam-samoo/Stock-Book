import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/domain/entities/price_alert.dart';
import 'package:stock_investment_tracker/domain/repositories/price_alert_repository.dart';
import 'package:stock_investment_tracker/presentation/alerts/widgets/add_alert_bottom_sheet.dart';
import 'package:stock_investment_tracker/providers/repository_providers.dart';

class _FakePriceAlertRepository implements PriceAlertRepository {
  @override
  Stream<List<PriceAlert>> watchAllAlerts() => const Stream.empty();

  @override
  Future<void> addAlert(PriceAlert alert) async {}

  @override
  Future<void> updateAlert(PriceAlert alert) async {}

  @override
  Future<void> deleteAlert(String alertId) async {}
}

void main() {
  testWidgets('10. live threshold preview matches the tested formula', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          priceAlertRepositoryProvider.overrideWithValue(_FakePriceAlertRepository()),
        ],
        child: MaterialApp(
          home: Scaffold(body: AddAlertBottomSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final numericFields = find.byType(TextFormField);
    // Order matches the Row in add_alert_bottom_sheet.dart: Target Price, then Tolerance.
    await tester.enterText(numericFields.at(0), '8.60');
    await tester.pump();
    await tester.enterText(numericFields.at(1), '1');
    await tester.pump();

    // 8.60 * 1.01 = 8.686 -> AppCurrencyFormatter rounds for display.
    expect(find.textContaining('8.69'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/domain/entities/price_alert.dart';
import 'package:stock_investment_tracker/domain/repositories/price_alert_repository.dart';
import 'package:stock_investment_tracker/presentation/alerts/widgets/alert_row.dart';
import 'package:stock_investment_tracker/providers/repository_providers.dart';

class _FakePriceAlertRepository implements PriceAlertRepository {
  String? lastDeletedId;

  @override
  Stream<List<PriceAlert>> watchAllAlerts() => const Stream.empty();

  @override
  Future<void> addAlert(PriceAlert alert) async {}

  @override
  Future<void> updateAlert(PriceAlert alert) async {}

  @override
  Future<void> deleteAlert(String alertId) async {
    lastDeletedId = alertId;
  }
}

void main() {
  testWidgets('9. swiping and confirming delete removes the alert', (tester) async {
    final alert = PriceAlert(
      id: 'a1',
      ticker: 'GUSM',
      targetPrice: 8.60,
      createdAt: DateTime(2026, 9, 1),
    );
    final fakeRepo = _FakePriceAlertRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          priceAlertRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          home: Scaffold(body: AlertRow(alert: alert)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Reveal the slidable's Delete action, then tap it.
    await tester.drag(find.byType(AlertRow), const Offset(-400, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Confirm the dialog.
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(fakeRepo.lastDeletedId, 'a1');
  });
}

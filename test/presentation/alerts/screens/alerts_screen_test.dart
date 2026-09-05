import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/domain/entities/price_alert.dart';
import 'package:stock_investment_tracker/domain/repositories/price_alert_repository.dart';
import 'package:stock_investment_tracker/presentation/alerts/screens/alerts_screen.dart';
import 'package:stock_investment_tracker/providers/repository_providers.dart';

class _FakePriceAlertRepository implements PriceAlertRepository {
  final Stream<List<PriceAlert>> stream;
  _FakePriceAlertRepository(this.stream);

  @override
  Stream<List<PriceAlert>> watchAllAlerts() => stream;

  @override
  Future<void> addAlert(PriceAlert alert) async {}

  @override
  Future<void> updateAlert(PriceAlert alert) async {}

  @override
  Future<void> deleteAlert(String alertId) async {}
}

void main() {
  testWidgets('8. shows EmptyStateView when there are no alerts', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          priceAlertRepositoryProvider.overrideWithValue(
            _FakePriceAlertRepository(Stream.value(const [])),
          ),
        ],
        child: const MaterialApp(home: AlertsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('No Active Alerts'), findsOneWidget);
  });
}

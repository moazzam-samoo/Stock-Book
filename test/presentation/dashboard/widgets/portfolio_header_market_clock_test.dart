import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/domain/entities/market_status.dart';
import 'package:stock_investment_tracker/domain/repositories/market_status_repository.dart';
import 'package:stock_investment_tracker/presentation/auth/providers/auth_providers.dart';
import 'package:stock_investment_tracker/presentation/dashboard/widgets/portfolio_header.dart';
import 'package:stock_investment_tracker/providers/repository_providers.dart';

/// Phase 04B required tests 7-10: the dashboard's market-open/closed clock.
///
/// Uses bounded `pump()` calls rather than `pumpAndSettle()` throughout: the
/// status dot's `flutter_animate` fade/delay chain never fully quiesces
/// (`pumpAndSettle` waits indefinitely for every pending timer and fails the
/// test with "Timer is still pending" once it gives up), while `_MarketClock`
/// itself only needs one frame plus its animation's own delay to render.
class _FakeMarketStatusRepository implements MarketStatusRepository {
  final MarketStatus? status;

  _FakeMarketStatusRepository(this.status);

  @override
  Stream<MarketStatus?> watchStatus() => Stream.value(status);
}

void main() {
  Widget wrap({MarketStatus? status, DateTime? lastSyncTime}) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(null)),
        currentUserIdProvider.overrideWith((ref) => 'test-uid'),
        marketStatusRepositoryProvider.overrideWithValue(
          _FakeMarketStatusRepository(status),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: PortfolioHeader(
            totalValue: 100000,
            profitLossPercentage: 5.0,
            lastSyncTime: lastSyncTime,
          ),
        ),
      ),
    );
  }

  testWidgets('test 7: isOpen true with a fresh checkedAt shows "Market Open" + current time', (tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(wrap(
      status: MarketStatus(isOpen: true, label: 'Open', checkedAt: now),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Market Open'), findsOneWidget);
  });

  testWidgets('test 8: isOpen false with a fresh checkedAt shows "Market Closed" + current time', (tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(wrap(
      status: MarketStatus(isOpen: false, label: 'Closed', checkedAt: now),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Market Closed'), findsOneWidget);
  });

  testWidgets('test 9: no market_status doc falls back to the legacy sync indicator, not a blank badge', (tester) async {
    final syncTime = DateTime.now();
    await tester.pumpWidget(wrap(status: null, lastSyncTime: syncTime));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Market Open'), findsNothing);
    expect(find.textContaining('Market Closed'), findsNothing);
    expect(find.textContaining('Last Sync'), findsOneWidget);
  });

  testWidgets('test 9b: no market_status doc AND no lastSyncTime renders nothing, no crash', (tester) async {
    await tester.pumpWidget(wrap(status: null, lastSyncTime: null));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Market Open'), findsNothing);
    expect(find.textContaining('Market Closed'), findsNothing);
    expect(find.textContaining('Last Sync'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('test 10: a checkedAt older than 30 minutes is treated as stale — same fallback as no doc', (tester) async {
    final staleTime = DateTime.now().subtract(const Duration(minutes: 45));
    final syncTime = DateTime.now();
    await tester.pumpWidget(wrap(
      status: MarketStatus(isOpen: true, label: 'Open', checkedAt: staleTime),
      lastSyncTime: syncTime,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Market Open'), findsNothing);
    expect(find.textContaining('Last Sync'), findsOneWidget);
  });
}

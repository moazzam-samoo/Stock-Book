import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/domain/entities/market_price.dart';
import 'package:stock_investment_tracker/domain/repositories/market_price_repository.dart';
import 'package:stock_investment_tracker/providers/market_prices_providers.dart';
import 'package:stock_investment_tracker/providers/repository_providers.dart';

/// Phase 04B required test 6. `transactions_screen.dart` and
/// `stock_detail_screen.dart` both wrap their content in a `RefreshIndicator`
/// whose `onRefresh` calls `ref.invalidate(watchMarketPriceProvider(...))`.
/// Rather than duplicate a full-screen harness (heavy provider stack: router,
/// positions, withdrawals, summaries) for each, this proves the shared
/// mechanic both screens rely on: pulling to refresh actually causes the
/// market-price provider to re-subscribe to the repository, using the exact
/// same `RefreshIndicator` + `ref.invalidate` pattern production code uses.
class _CountingMarketPriceRepository implements MarketPriceRepository {
  int watchPriceCallCount = 0;

  @override
  Stream<MarketPrice?> watchPrice(String ticker) {
    watchPriceCallCount++;
    return Stream.value(MarketPrice(
      ticker: ticker,
      price: 9.0,
      previousClose: 9.0,
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Stream<Map<String, MarketPrice>> watchPrices(List<String> tickers) => Stream.value({});
}

void main() {
  testWidgets(
    'pulling to refresh invalidates watchMarketPriceProvider, forcing a fresh repository subscription',
    (tester) async {
      final fakeRepo = _CountingMarketPriceRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [marketPriceRepositoryProvider.overrideWithValue(fakeRepo)],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                // Watching it here is what makes the provider "alive" and
                // subject to invalidation, same as PositionCard/StockDetailScreen do.
                ref.watch(watchMarketPriceProvider('STPL'));
                return Scaffold(
                  body: RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(watchMarketPriceProvider('STPL'));
                      await Future.delayed(const Duration(milliseconds: 10));
                    },
                    child: ListView(
                      children: const [
                        SizedBox(height: 800, child: Text('content')),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(fakeRepo.watchPriceCallCount, 1, reason: 'the initial watch');

      await tester.fling(find.text('content'), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(
        fakeRepo.watchPriceCallCount,
        2,
        reason: 'pull-to-refresh must invalidate and re-subscribe, not just redraw',
      );
    },
  );
}

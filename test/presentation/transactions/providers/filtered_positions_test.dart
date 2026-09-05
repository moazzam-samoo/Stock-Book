import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/domain/entities/position.dart';
import 'package:stock_investment_tracker/domain/entities/position_buy.dart';
import 'package:stock_investment_tracker/domain/enums/position_status.dart';
import 'package:stock_investment_tracker/presentation/dashboard/providers/dashboard_providers.dart';
import 'package:stock_investment_tracker/presentation/transactions/providers/transactions_providers.dart';

/// Phase 03C tests 3-4. The default "Open" chip means "still holding" — a
/// position vanishing from the list the moment it was partially sold is what
/// this covers.
void main() {
  Position position(String ticker, PositionStatus status) {
    return Position(
      id: 'pos-$ticker-${status.name}',
      ticker: ticker,
      status: status,
      openedAt: DateTime.parse('2026-08-01'),
      buys: [
        PositionBuy(
          id: 'b-$ticker',
          date: DateTime.parse('2026-08-01'),
          shares: 100,
          pricePerShare: 10.0,
        ),
      ],
    );
  }

  final open = position('AAA', PositionStatus.open);
  final partial = position('BBB', PositionStatus.partiallySold);
  final closed = position('CCC', PositionStatus.closed);

  ProviderContainer containerWith(String filter) {
    final container = ProviderContainer(
      overrides: [
        allPositionsProvider.overrideWith(
          (ref) => Stream.value([open, partial, closed]),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(statusFilterProvider.notifier).updateFilter(filter);
    return container;
  }

  Future<List<String>> tickersFor(String filter) async {
    final container = containerWith(filter);
    // Let the overridden stream deliver before reading the derived provider.
    await container.read(allPositionsProvider.future);
    return container.read(filteredPositionsProvider).map((p) => p.ticker).toList();
  }

  test('"Open" includes partially-sold positions and excludes closed ones', () async {
    expect(await tickersFor('Open'), containsAll(['AAA', 'BBB']));
    expect(await tickersFor('Open'), isNot(contains('CCC')));
  });

  test('"Partial" shows only partially-sold', () async {
    expect(await tickersFor('Partial'), ['BBB']);
  });

  test('"Closed" shows only closed', () async {
    expect(await tickersFor('Closed'), ['CCC']);
  });

  test('"All" shows everything', () async {
    expect((await tickersFor('All')).toSet(), {'AAA', 'BBB', 'CCC'});
  });

  test('the default filter is "Open"', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(statusFilterProvider), 'Open');
  });
}

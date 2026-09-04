import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stock_investment_tracker/domain/entities/market_price.dart';
import 'package:stock_investment_tracker/providers/repository_providers.dart';

part 'market_prices_providers.g.dart';

@riverpod
Stream<MarketPrice?> watchMarketPrice(WatchMarketPriceRef ref, String ticker) {
  final repository = ref.watch(marketPriceRepositoryProvider);
  if (repository == null) return Stream.value(null);
  return repository.watchPrice(ticker);
}

@riverpod
Stream<Map<String, MarketPrice>> watchMarketPrices(WatchMarketPricesRef ref, List<String> tickers) {
  final repository = ref.watch(marketPriceRepositoryProvider);
  if (repository == null) return Stream.value({});
  return repository.watchPrices(tickers);
}

import 'package:stock_investment_tracker/data/data_sources/local/hive_data_source.dart';
import 'package:stock_investment_tracker/data/data_sources/remote/firestore_data_source.dart';
import 'package:stock_investment_tracker/data/models/market_price_model.dart';
import 'package:stock_investment_tracker/domain/entities/market_price.dart';
import 'package:stock_investment_tracker/domain/repositories/market_price_repository.dart';
import 'package:rxdart/rxdart.dart';

class MarketPriceRepositoryImpl implements MarketPriceRepository {
  final FirestoreDataSource firestoreDataSource;
  final HiveDataSource hiveDataSource;

  MarketPriceRepositoryImpl({
    required this.firestoreDataSource,
    required this.hiveDataSource,
  });

  @override
  Stream<MarketPrice?> watchPrice(String ticker) {
    // Emit the Hive-cached value first (instant, works offline), then switch
    // to the live Firestore stream. Rx.concat waits for the cache future to
    // complete (a Future-backed stream completes right after its one value)
    // before subscribing to the Firestore stream, so this is "cache, then
    // live updates" rather than "both at once".
    final cacheFuture = hiveDataSource.getMarketPrices().then((map) => map[ticker]?.toEntity());

    final firestoreStream = firestoreDataSource.watchMarketPrice(ticker).map((model) {
      if (model != null) {
        hiveDataSource.getMarketPrices().then((map) {
          map[ticker] = model;
          hiveDataSource.saveMarketPrices(map);
        });
      }
      return model?.toEntity();
    });

    return Rx.concat([
      Stream.fromFuture(cacheFuture),
      firestoreStream,
    ]).distinct(); // prevent duplicate emission if cache == firestore initially
  }

  @override
  Stream<Map<String, MarketPrice>> watchPrices(List<String> tickers) {
    if (tickers.isEmpty) return Stream.value({});

    final cacheFuture = hiveDataSource.getMarketPrices().then((map) {
      // Filter the cache to only requested tickers.
      final filtered = <String, MarketPrice>{};
      for (final t in tickers) {
        final cached = map[t];
        if (cached != null) {
          filtered[t] = cached.toEntity();
        }
      }
      return filtered;
    });

    final firestoreStream = firestoreDataSource.watchMarketPrices(tickers).map((models) {
      final map = <String, MarketPriceModel>{};
      for (final model in models) {
        map[model.ticker] = model;
      }

      // Write back to Hive on each emission.
      hiveDataSource.getMarketPrices().then((existing) {
        existing.addAll(map);
        hiveDataSource.saveMarketPrices(existing);
      });

      return map.map((ticker, model) => MapEntry(ticker, model.toEntity()));
    });

    return Rx.concat([
      Stream.fromFuture(cacheFuture),
      firestoreStream,
    ]);
  }
}

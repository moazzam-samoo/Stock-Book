import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stock_investment_tracker/data/data_sources/remote/firestore_data_source.dart';
import 'package:stock_investment_tracker/data/data_sources/local/hive_data_source.dart';
import 'package:stock_investment_tracker/data/repositories/market_price_repository_impl.dart';
import 'package:stock_investment_tracker/data/models/market_price_model.dart';
import 'market_price_repository_test.mocks.dart';

@GenerateMocks([FirestoreDataSource, HiveDataSource])
void main() {
  late MockFirestoreDataSource mockFirestore;
  late MockHiveDataSource mockHive;
  late MarketPriceRepositoryImpl repository;

  setUp(() {
    mockFirestore = MockFirestoreDataSource();
    mockHive = MockHiveDataSource();
    repository = MarketPriceRepositoryImpl(
      firestoreDataSource: mockFirestore,
      hiveDataSource: mockHive,
    );
  });

  group('MarketPriceRepositoryImpl.watchPrice', () {
    test('emits the Hive-cached value first (test 4: cache serves on cold start), then live updates', () async {
      const ticker = 'SYS';
      final now = DateTime.now();
      final hiveModel = MarketPriceModel(ticker: ticker, price: 100.0, previousClose: 90.0, updatedAt: now);
      final fsModel = MarketPriceModel(ticker: ticker, price: 105.0, previousClose: 90.0, updatedAt: now);

      when(mockHive.getMarketPrices()).thenAnswer((_) => Future.value({ticker: hiveModel}));
      when(mockFirestore.watchMarketPrice(ticker)).thenAnswer((_) => Stream.value(fsModel));

      final stream = repository.watchPrice(ticker);
      final results = await stream.toList();

      expect(results.length, 2);
      expect(results[0]?.price, 100.0, reason: 'the cached value, available before any Firestore emission');
      expect(results[1]?.price, 105.0, reason: 'the live Firestore value');

      // Test 5: cache updated on emission — the live value gets written back.
      verify(mockHive.saveMarketPrices({ticker: fsModel})).called(1);
    });

    test('returns MarketPrice entities, not the raw data model', () async {
      const ticker = 'ENGRO';
      final now = DateTime.now();
      final model = MarketPriceModel(ticker: ticker, price: 350.0, previousClose: 340.0, updatedAt: now);

      when(mockHive.getMarketPrices()).thenAnswer((_) => Future.value({}));
      when(mockFirestore.watchMarketPrice(ticker)).thenAnswer((_) => Stream.value(model));

      final result = await repository.watchPrice(ticker).last;

      expect(result, isNotNull);
      expect(result!.ticker, ticker);
      expect(result.price, 350.0);
      expect(result.previousClose, 340.0);
      expect(result.updatedAt, now);
    });
  });

  group('MarketPriceRepositoryImpl.watchPrices', () {
    test('hands the full ticker list through and returns every one in the merged result', () async {
      final tickers = List.generate(35, (i) => 'TICK$i');

      when(mockHive.getMarketPrices()).thenAnswer((_) => Future.value(<String, MarketPriceModel>{}));

      when(mockFirestore.watchMarketPrices(any)).thenAnswer((invocation) {
        final reqTickers = invocation.positionalArguments[0] as List<String>;
        final list = <MarketPriceModel>[
          for (final t in reqTickers)
            MarketPriceModel(ticker: t, price: 10.0, previousClose: 9.0, updatedAt: DateTime.now()),
        ];
        return Stream.value(list);
      });

      final stream = repository.watchPrices(tickers);

      final allEmissions = await stream.toList();
      expect(allEmissions.length, 2);
      expect(allEmissions[0], isEmpty, reason: 'the cache emission, empty here since Hive was empty');
      expect(allEmissions[1].length, 35, reason: 'no ticker dropped by the 30-per-query Firestore cap');
      expect(allEmissions[1].keys.toSet(), tickers.toSet());
      expect(allEmissions[1]['TICK0'], isA<Object>()); // a MarketPrice entity, not the raw model
    });

    test('an empty ticker list short-circuits to an empty map, no Firestore/Hive call', () async {
      final result = await repository.watchPrices([]).single;
      expect(result, isEmpty);
      verifyZeroInteractions(mockFirestore);
      verifyZeroInteractions(mockHive);
    });
  });
}

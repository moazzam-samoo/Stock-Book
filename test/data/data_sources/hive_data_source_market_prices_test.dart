import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_investment_tracker/data/data_sources/local/hive_data_source.dart';
import 'package:stock_investment_tracker/data/models/market_price_model.dart';

/// AGENTS.md §8: Hive returns nested maps as `Map<dynamic, dynamic>`, which
/// crashes a generated `fromJson` expecting `Map<String, dynamic>`. This uses
/// **real** Hive I/O (not a mock) so the dynamic-keyed shape is genuine —
/// mocking `HiveDataSource` would just hand back whatever type the test
/// wrote, defeating the point.
void main() {
  late Directory tempDir;
  late HiveDataSource dataSource;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_market_prices_test');
    Hive.init(tempDir.path);
    dataSource = HiveDataSource();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('getMarketPrices does not crash on Hive\'s native Map<dynamic,dynamic> shape', () async {
    final box = await Hive.openBox('market_prices_cache');
    // Written as a genuinely dynamic-keyed nested map — what Hive actually
    // returns on read, not what saveMarketPrices happens to write.
    await box.put('market_prices', <dynamic, dynamic>{
      'ENGRO': <dynamic, dynamic>{
        'ticker': 'ENGRO',
        'price': 350.25,
        'previousClose': 347.10,
        'updatedAt': '2026-09-04T10:30:00.000Z',
      },
    });

    final result = await dataSource.getMarketPrices();

    expect(result, contains('ENGRO'));
    expect(result['ENGRO']!.price, 350.25);
  });

  test('save then read round-trips correctly (test 5: a later cold start sees the newer value)', () async {
    final first = MarketPriceModel(
      ticker: 'SYS',
      price: 500.0,
      previousClose: 495.0,
      updatedAt: DateTime.parse('2026-09-04T09:00:00.000Z'),
    );
    await dataSource.saveMarketPrices({'SYS': first});
    expect((await dataSource.getMarketPrices())['SYS']!.price, 500.0);

    // A later write (simulating a subsequent Firestore emission)...
    final updated = MarketPriceModel(
      ticker: 'SYS',
      price: 512.0,
      previousClose: 495.0,
      updatedAt: DateTime.parse('2026-09-04T09:15:00.000Z'),
    );
    await dataSource.saveMarketPrices({'SYS': updated});

    // ...and a fresh HiveDataSource instance (a "cold start") must see it.
    final freshDataSource = HiveDataSource();
    final result = await freshDataSource.getMarketPrices();
    expect(result['SYS']!.price, 512.0);
  });

  test('malformed cached data returns an empty map rather than throwing', () async {
    final box = await Hive.openBox('market_prices_cache');
    await box.put('market_prices', 'not a map at all');

    expect(await dataSource.getMarketPrices(), isEmpty);
  });
}

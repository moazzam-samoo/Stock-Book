import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_investment_tracker/data/data_sources/local/hive_data_source.dart';

/// Mirrors hive_data_source_market_prices_test.dart's pattern exactly:
/// Hive.init() with a real temp directory, not Hive.initFlutter(), which
/// needs path_provider's platform channel — unavailable in a plain unit test
/// and the reason this file's setUpAll/tearDownAll were failing outright.
void main() {
  late Directory tempDir;
  late HiveDataSource dataSource;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_tickers_test');
    Hive.init(tempDir.path);
    dataSource = HiveDataSource();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('HiveDataSource - Tickers', () {
    final validTickersData = [
      {'symbol': 'SYS', 'name': 'Systems Limited', 'sector': 'Technology'},
      {'symbol': 'ENGRO', 'name': 'Engro Corp', 'sector': 'Fertilizer'},
    ];

    test('getTickers on an empty cache returns an empty list, not a crash', () async {
      final initial = await dataSource.getTickers();
      expect(initial, isEmpty);
    });

    test('saveTickers and getTickers round-trip correctly', () async {
      await dataSource.saveTickers(validTickersData);

      final retrieved = await dataSource.getTickers();
      expect(retrieved.length, 2);
      expect(retrieved[0]['symbol'], 'SYS');
      expect(retrieved[0]['name'], 'Systems Limited');
      expect(retrieved[0]['sector'], 'Technology');
      expect(retrieved[1]['symbol'], 'ENGRO');
      expect(retrieved[1]['name'], 'Engro Corp');
      expect(retrieved[1]['sector'], 'Fertilizer');
    });

    test('a sector-less ticker round-trips with sector absent, not crashing', () async {
      await dataSource.saveTickers([
        {'symbol': 'XYZ', 'name': 'No Sector Co'},
      ]);

      final retrieved = await dataSource.getTickers();
      expect(retrieved.single['symbol'], 'XYZ');
      expect(retrieved.single['sector'], isNull);
    });
  });
}

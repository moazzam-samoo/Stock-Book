import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/data/data_sources/remote/firestore_data_source.dart';

/// Firestore's `whereIn` accepts at most 30 values per query, so
/// `FirestoreDataSource.watchMarketPrices` splits a longer ticker list and
/// merges the resulting streams. `chunkTickers` is the pure piece of that —
/// tested directly here rather than through a real/mocked Firestore, so the
/// batch-boundary behaviour is verified deterministically and without
/// needing a Firestore test double.
void main() {
  group('FirestoreDataSource.chunkTickers', () {
    test('exactly 30 tickers -> a single chunk (1 query)', () {
      final tickers = List.generate(30, (i) => 'T$i');
      final chunks = FirestoreDataSource.chunkTickers(tickers);

      expect(chunks.length, 1);
      expect(chunks.single.length, 30);
      expect(chunks.single.toSet(), tickers.toSet());
    });

    test('31 tickers -> two chunks (2 queries), every ticker present exactly once', () {
      final tickers = List.generate(31, (i) => 'T$i');
      final chunks = FirestoreDataSource.chunkTickers(tickers);

      expect(chunks.length, 2);
      expect(chunks[0].length, 30);
      expect(chunks[1].length, 1);

      final merged = chunks.expand((c) => c).toList();
      expect(merged.length, 31);
      expect(merged.toSet(), tickers.toSet());
    });

    test('60 tickers -> two full chunks', () {
      final tickers = List.generate(60, (i) => 'T$i');
      final chunks = FirestoreDataSource.chunkTickers(tickers);

      expect(chunks.length, 2);
      expect(chunks[0].length, 30);
      expect(chunks[1].length, 30);
    });

    test('empty list -> no chunks', () {
      expect(FirestoreDataSource.chunkTickers([]), isEmpty);
    });

    test('a single ticker -> a single chunk of one', () {
      final chunks = FirestoreDataSource.chunkTickers(['ENGRO']);
      expect(chunks, [
        ['ENGRO'],
      ]);
    });
  });
}

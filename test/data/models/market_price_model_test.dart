import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/data/models/market_price_model.dart';

/// `updatedAt` must tolerate every shape it can actually arrive in:
/// a Firestore `Timestamp` (the real write path), an ISO string or epoch-ms
/// int (the Hive round trip, since `toJson` writes an ISO string for the
/// cache), matching the tolerant-parsing pattern `sale_model.dart` already
/// uses for exactly this reason.
void main() {
  group('MarketPriceModel.fromJson', () {
    test('parses a Firestore Timestamp', () {
      final now = DateTime.now();
      final model = MarketPriceModel.fromJson({
        'ticker': 'ENGRO',
        'price': 350.25,
        'previousClose': 347.10,
        'updatedAt': Timestamp.fromDate(now),
      });

      expect(model.ticker, 'ENGRO');
      expect(model.price, 350.25);
      expect(model.previousClose, 347.10);
      // Timestamp truncates to microsecond precision like DateTime, so this
      // should be exact.
      expect(model.updatedAt, now);
    });

    test('parses an ISO 8601 string (the Hive cache round trip)', () {
      final model = MarketPriceModel.fromJson({
        'ticker': 'SYS',
        'price': 520.0,
        'previousClose': 515.0,
        'updatedAt': '2026-09-04T10:30:00.000Z',
      });

      expect(model.updatedAt, DateTime.parse('2026-09-04T10:30:00.000Z'));
    });

    test('parses an epoch-millisecond int', () {
      final millis = DateTime(2026, 9, 4).millisecondsSinceEpoch;
      final model = MarketPriceModel.fromJson({
        'ticker': 'OGDC',
        'price': 105.0,
        'previousClose': 100.0,
        'updatedAt': millis,
      });

      expect(model.updatedAt, DateTime.fromMillisecondsSinceEpoch(millis));
    });

    test('falls back to now() rather than throwing on an unrecognised updatedAt shape', () {
      expect(
        () => MarketPriceModel.fromJson({
          'ticker': 'ENGRO',
          'price': 350.0,
          'previousClose': 340.0,
          'updatedAt': null,
        }),
        returnsNormally,
      );
    });

    test('defaults ticker to empty string rather than throwing when absent', () {
      final model = MarketPriceModel.fromJson({
        'price': 100.0,
        'previousClose': 95.0,
        'updatedAt': '2026-09-04T10:30:00.000Z',
      });
      expect(model.ticker, '');
    });
  });

  group('MarketPriceModel round trip', () {
    test('toJson -> fromJson preserves every field (the Hive cache path)', () {
      final original = MarketPriceModel(
        ticker: 'STPL',
        price: 8.48,
        previousClose: 8.40,
        updatedAt: DateTime.parse('2026-09-04T10:30:00.000Z'),
      );

      final restored = MarketPriceModel.fromJson(original.toJson());

      expect(restored.ticker, original.ticker);
      expect(restored.price, original.price);
      expect(restored.previousClose, original.previousClose);
      expect(restored.updatedAt, original.updatedAt);
    });
  });

  group('MarketPriceModelExtension.toEntity', () {
    test('maps every field across to the domain entity unchanged', () {
      final model = MarketPriceModel(
        ticker: 'ENGRO',
        price: 350.25,
        previousClose: 347.10,
        updatedAt: DateTime.parse('2026-09-04T10:30:00.000Z'),
      );

      final entity = model.toEntity();

      expect(entity.ticker, model.ticker);
      expect(entity.price, model.price);
      expect(entity.previousClose, model.previousClose);
      expect(entity.updatedAt, model.updatedAt);
    });
  });
}

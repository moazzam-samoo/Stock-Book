import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stock_investment_tracker/data/models/market_status_model.dart';

void main() {
  group('MarketStatusModel', () {
    test('fromJson handles standard string date', () {
      final json = {
        'isOpen': true,
        'label': 'Open',
        'checkedAt': '2023-01-01T10:00:00Z',
      };
      
      final model = MarketStatusModel.fromJson(json);

      expect(model.isOpen, true);
      expect(model.label, 'Open');
      // No .toLocal() — matches MarketPriceModel's established convention.
      // In production checkedAt only ever arrives as a Firestore Timestamp
      // (already local via .toDate()); this string branch is defensive
      // tolerance only, same as MarketPriceModel's.
      expect(model.checkedAt, DateTime.parse('2023-01-01T10:00:00Z'));
    });

    test('fromJson handles Firestore Timestamp', () {
      final timestamp = Timestamp.fromDate(DateTime(2023, 1, 1, 10, 0, 0));
      final json = {
        'isOpen': false,
        'label': 'Closed',
        'checkedAt': timestamp,
      };
      
      final model = MarketStatusModel.fromJson(json);
      
      expect(model.isOpen, false);
      expect(model.checkedAt, timestamp.toDate());
    });

    test('fromJson handles an epoch-millisecond int', () {
      final millis = DateTime(2026, 9, 4).millisecondsSinceEpoch;
      final json = {
        'isOpen': true,
        'label': 'Open',
        'checkedAt': millis,
      };

      final model = MarketStatusModel.fromJson(json);

      expect(model.checkedAt, DateTime.fromMillisecondsSinceEpoch(millis));
    });

    test('fromJson handles missing checkedAt gracefully by returning current time', () {
      final json = {
        'isOpen': true,
        'label': 'Open',
      };
      
      final now = DateTime.now();
      final model = MarketStatusModel.fromJson(json);
      
      expect(model.isOpen, true);
      // Should be roughly now
      expect(model.checkedAt.difference(now).inSeconds.abs(), lessThan(5));
    });

    test('toEntity maps correctly', () {
      final model = MarketStatusModel(
        isOpen: true,
        label: 'Open',
        checkedAt: DateTime(2023, 1, 1, 10, 0, 0),
      );
      
      final entity = model.toEntity();
      
      expect(entity.isOpen, true);
      expect(entity.label, 'Open');
      expect(entity.checkedAt, DateTime(2023, 1, 1, 10, 0, 0));
    });
  });
}

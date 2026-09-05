import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/data/models/price_alert_model.dart';

void main() {
  group('PriceAlertModel Serialization', () {
    test('roundtrips to JSON and back', () {
      final now = DateTime(2026, 9, 5, 12, 0, 0);
      final model = PriceAlertModel(
        id: 'test-id',
        ticker: 'GUSM',
        targetPrice: 8.60,
        tolerancePercent: 1.5,
        isActive: true,
        alertSent: false,
        alertSentAt: null,
        createdAt: now,
      );

      final json = model.toJson();
      final fromJson = PriceAlertModel.fromJson(json);

      expect(fromJson, model);
      expect(json['alertSentAt'], isNull);
    });

    test('handles String dates defensively', () {
      final json = {
        'id': 'test-id',
        'ticker': 'GUSM',
        'targetPrice': 8.60,
        'tolerancePercent': 1.0,
        'isActive': true,
        'alertSent': true,
        'alertSentAt': '2026-09-05T12:00:00.000',
        'createdAt': '2026-09-01T12:00:00.000',
      };

      final model = PriceAlertModel.fromJson(json);
      
      expect(model.alertSentAt, DateTime(2026, 9, 5, 12, 0, 0));
      expect(model.createdAt, DateTime(2026, 9, 1, 12, 0, 0));
    });

    test('a fired-but-still-watching alert round-trips (alertSent: true, isActive: true)', () {
      // Alerts aren't one-shot: a buy alert stays isActive after firing so it
      // can keep notifying on a further favorable move — isActive: false now
      // only ever means the user edited the target (re-arming it back to
      // true) or the alert doesn't exist. This combination is what the
      // backend actually produces after a real fire.
      final now = DateTime(2026, 9, 5, 12, 0, 0);
      final firedAt = DateTime(2026, 9, 5, 13, 30, 0);
      final model = PriceAlertModel(
        id: 'test-id',
        ticker: 'GUSM',
        targetPrice: 8.60,
        tolerancePercent: 1.0,
        isActive: true,
        alertSent: true,
        alertSentAt: firedAt,
        lastAlertPrice: 8.55,
        createdAt: now,
      );

      final decoded = PriceAlertModel.fromJson(model.toJson());

      expect(decoded.alertSent, true);
      expect(decoded.isActive, true);
      expect(decoded.alertSentAt, firedAt);
      expect(decoded.lastAlertPrice, 8.55);
    });

    test('a null lastAlertPrice (never fired) round-trips as null', () {
      final model = PriceAlertModel(
        id: 'test-id',
        ticker: 'GUSM',
        targetPrice: 8.60,
        createdAt: DateTime(2026, 9, 5),
      );

      final json = model.toJson();
      expect(json['lastAlertPrice'], isNull);

      final decoded = PriceAlertModel.fromJson(json);
      expect(decoded.lastAlertPrice, isNull);
    });

    test('defaults lastAlertPrice to null when reading a pre-existing doc that lacks it', () {
      final legacyJson = {
        'id': 'test-id',
        'ticker': 'GUSM',
        'targetPrice': 8.60,
        'tolerancePercent': 1.0,
        'isActive': true,
        'alertSent': false,
        'createdAt': '2026-09-01T12:00:00.000',
        // lastAlertPrice intentionally absent, as any alert created before
        // this field existed would be.
      };

      final model = PriceAlertModel.fromJson(legacyJson);
      expect(model.lastAlertPrice, isNull);
    });

    test('handles Timestamp dates defensively', () {
      final alertSentAt = Timestamp.fromDate(DateTime(2026, 9, 5, 12, 0, 0));
      final createdAt = Timestamp.fromDate(DateTime(2026, 9, 1, 12, 0, 0));
      final json = {
        'id': 'test-id',
        'ticker': 'GUSM',
        'targetPrice': 8.60,
        'tolerancePercent': 1.0,
        'isActive': true,
        'alertSent': true,
        'alertSentAt': alertSentAt,
        'createdAt': createdAt,
      };

      final model = PriceAlertModel.fromJson(json);
      
      expect(model.alertSentAt, alertSentAt.toDate());
      expect(model.createdAt, createdAt.toDate());
    });
  });
}

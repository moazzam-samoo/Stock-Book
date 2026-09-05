import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/data/models/position_model.dart';

void main() {
  group('PositionModel Serialization', () {
    test('roundtrips to JSON successfully', () {
      final date = DateTime.parse('2026-09-01T00:00:00.000Z');

      final position = PositionModel(
        id: 'pos1',
        ticker: 'TEST',
        status: 'open',
        openedAt: date,
        buys: [
          PositionBuyModel(id: 'b1', date: date, shares: 100, pricePerShare: 10.0),
        ],
        sales: [
          PositionSaleModel(id: 's1', date: date, shares: 50, pricePerShare: 12.0, costBasisAtSale: 10.0),
        ],
        targetPrice: 15.0,
        targetAlertSent: true,
        targetAlertSentAt: date,
      );

      final json = position.toJson();

      expect(json['id'], 'pos1');
      expect(json['ticker'], 'TEST');
      expect(json['status'], 'open');
      expect(json['targetPrice'], 15.0);
      expect(json['targetAlertSent'], true);
      expect(json['targetAlertSentAt'], isNotNull);
      expect(json['buys'].length, 1);
      expect(json['sales'].length, 1);

      final decoded = PositionModel.fromJson(json);

      expect(decoded.id, position.id);
      expect(decoded.ticker, position.ticker);
      expect(decoded.status, position.status);
      expect(decoded.targetPrice, position.targetPrice);
      expect(decoded.targetAlertSent, position.targetAlertSent);
      expect(decoded.targetAlertSentAt?.isAtSameMomentAs(position.targetAlertSentAt!), isTrue);

      expect(decoded.buys.first.id, position.buys.first.id);
      expect(decoded.buys.first.date.isAtSameMomentAs(position.buys.first.date), isTrue);
      expect(decoded.buys.first.shares, position.buys.first.shares);
      expect(decoded.buys.first.pricePerShare, position.buys.first.pricePerShare);

      expect(decoded.sales.first.id, position.sales.first.id);
      expect(decoded.sales.first.date.isAtSameMomentAs(position.sales.first.date), isTrue);
      expect(decoded.sales.first.shares, position.sales.first.shares);
      expect(decoded.sales.first.costBasisAtSale, position.sales.first.costBasisAtSale);
    });

    test('closedAt survives a round trip when the position is closed', () {
      final openedAt = DateTime.parse('2026-08-01T00:00:00.000Z');
      final closedAt = DateTime.parse('2026-08-15T00:00:00.000Z');

      final position = PositionModel(
        id: 'pos2',
        ticker: 'ENGRO',
        status: 'closed',
        openedAt: openedAt,
        closedAt: closedAt,
        buys: const [],
        sales: const [],
      );

      final decoded = PositionModel.fromJson(position.toJson());
      expect(decoded.closedAt?.isAtSameMomentAs(closedAt), isTrue);
      expect(decoded.status, 'closed');
    });

    test('a null targetPrice round-trips as null, not omitted or zero', () {
      final position = PositionModel(
        id: 'pos3',
        ticker: 'OGDC',
        status: 'open',
        openedAt: DateTime.parse('2026-08-10T00:00:00.000Z'),
        buys: const [],
        sales: const [],
      );

      final json = position.toJson();
      expect(json.containsKey('targetPrice'), isTrue);
      expect(json['targetPrice'], isNull);

      final decoded = PositionModel.fromJson(json);
      expect(decoded.targetPrice, isNull);
    });

    test('targetAlertSent/targetAlertSentAt round-trip with a null timestamp', () {
      final position = PositionModel(
        id: 'pos4',
        ticker: 'PSO',
        status: 'open',
        openedAt: DateTime.parse('2026-08-10T00:00:00.000Z'),
        buys: const [],
        sales: const [],
        targetAlertSent: false,
      );

      final json = position.toJson();
      expect(json['targetAlertSent'], false);
      expect(json.containsKey('targetAlertSentAt'), isTrue);
      expect(json['targetAlertSentAt'], isNull);

      final decoded = PositionModel.fromJson(json);
      expect(decoded.targetAlertSent, false);
      expect(decoded.targetAlertSentAt, isNull);
    });

    test('defaults targetAlertSent/targetAlertSentAt when reading a pre-Phase-06 '
        'doc that lacks both fields entirely', () {
      final legacyJson = <String, dynamic>{
        'id': 'pos5',
        'ticker': 'HUBC',
        'status': 'open',
        'openedAt': Timestamp.fromDate(DateTime.parse('2026-08-10T00:00:00.000Z')),
        'targetPrice': 30.0,
        'buys': <Map<String, dynamic>>[],
        'sales': <Map<String, dynamic>>[],
        // targetAlertSent / targetAlertSentAt intentionally absent, as any
        // position written before this phase would be.
      };

      final decoded = PositionModel.fromJson(legacyJson);

      expect(decoded.targetAlertSent, false);
      expect(decoded.targetAlertSentAt, isNull);
      expect(decoded.targetPrice, 30.0);
    });

    // PositionBuyModel / PositionSaleModel have hand-written fromJson (like
    // sale_model.dart / withdrawal_model.dart), so per AGENTS.md §4.1 they
    // must tolerate a Firestore Timestamp *or* an ISO-8601 string for their
    // date field.
    group('PositionBuyModel date parsing', () {
      test('parses a Firestore Timestamp', () {
        final date = DateTime.parse('2026-08-31T00:00:00.000Z');
        final json = {
          'id': 'b1',
          'date': Timestamp.fromDate(date),
          'shares': 100,
          'pricePerShare': 10.0,
        };
        final model = PositionBuyModel.fromJson(json);
        expect(model.date.isAtSameMomentAs(date), isTrue);
      });

      test('parses an ISO-8601 string', () {
        final date = DateTime.parse('2026-08-31T00:00:00.000Z');
        final json = {
          'id': 'b1',
          'date': date.toIso8601String(),
          'shares': 100,
          'pricePerShare': 10.0,
        };
        final model = PositionBuyModel.fromJson(json);
        expect(model.date.isAtSameMomentAs(date), isTrue);
      });
    });

    group('PositionSaleModel date parsing', () {
      test('parses a Firestore Timestamp', () {
        final date = DateTime.parse('2026-09-08T00:00:00.000Z');
        final json = {
          'id': 's1',
          'date': Timestamp.fromDate(date),
          'shares': 200,
          'pricePerShare': 9.0,
          'costBasisAtSale': 8.48,
        };
        final model = PositionSaleModel.fromJson(json);
        expect(model.date.isAtSameMomentAs(date), isTrue);
        expect(model.costBasisAtSale, 8.48);
      });

      test('parses an ISO-8601 string, and a missing costBasisAtSale as null', () {
        final date = DateTime.parse('2026-09-08T00:00:00.000Z');
        final json = {
          'id': 's1',
          'date': date.toIso8601String(),
          'shares': 200,
          'pricePerShare': 9.0,
        };
        final model = PositionSaleModel.fromJson(json);
        expect(model.date.isAtSameMomentAs(date), isTrue);
        expect(model.costBasisAtSale, isNull);
      });
    });

    test('nested buys/sales serialise as plain maps, not model instances', () {
      final position = PositionModel(
        id: 'pos1',
        ticker: 'STPL',
        status: 'open',
        openedAt: DateTime.parse('2026-08-31T00:00:00.000Z'),
        buys: [
          PositionBuyModel(id: 'b1', date: DateTime.parse('2026-08-31T00:00:00.000Z'), shares: 100, pricePerShare: 10.0),
        ],
        sales: [
          PositionSaleModel(id: 's1', date: DateTime.parse('2026-09-01T00:00:00.000Z'), shares: 50, pricePerShare: 12.0, costBasisAtSale: 10.0),
        ],
      );

      final json = position.toJson();
      final rawBuy = (json['buys'] as List).first;
      final rawSale = (json['sales'] as List).first;

      // Firestore's SDK rejects writing arbitrary Dart objects — nested
      // entries must already be plain Map<String, dynamic>, exactly like
      // LotModel's sales[] (see FirestoreDataSource.addLot's explicit
      // re-serialisation and AGENTS.md §4.1).
      expect(rawBuy, isA<Map<String, dynamic>>());
      expect(rawBuy, isNot(isA<PositionBuyModel>()));
      expect(rawSale, isA<Map<String, dynamic>>());
      expect(rawSale, isNot(isA<PositionSaleModel>()));
      expect(rawBuy['id'], 'b1');
      expect(rawSale['costBasisAtSale'], 10.0);
    });
  });
}

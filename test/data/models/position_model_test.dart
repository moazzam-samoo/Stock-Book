import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/data/models/position_model.dart';
import 'package:stock_investment_tracker/domain/enums/position_status.dart';

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
      );

      final json = position.toJson();
      
      expect(json['id'], 'pos1');
      expect(json['ticker'], 'TEST');
      expect(json['targetPrice'], 15.0);
      expect(json['buys'].length, 1);
      expect(json['sales'].length, 1);
      
      final decoded = PositionModel.fromJson(json);
      
      expect(decoded.id, position.id);
      expect(decoded.ticker, position.ticker);
      expect(decoded.targetPrice, position.targetPrice);
      
      expect(decoded.buys.first.id, position.buys.first.id);
      expect(decoded.buys.first.date.isAtSameMomentAs(position.buys.first.date), isTrue);
      expect(decoded.buys.first.shares, position.buys.first.shares);
      
      expect(decoded.sales.first.id, position.sales.first.id);
      expect(decoded.sales.first.date.isAtSameMomentAs(position.sales.first.date), isTrue);
      expect(decoded.sales.first.shares, position.sales.first.shares);
      expect(decoded.sales.first.costBasisAtSale, position.sales.first.costBasisAtSale);
    });
  });
}

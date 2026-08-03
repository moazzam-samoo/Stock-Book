import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/data/models/lot_model.dart';
import 'package:stock_investment_tracker/data/models/sale_model.dart';

void main() {
  group('Model Serialization Tests', () {
    test('LotModel roundtrip serialization', () {
      final lot = LotModel(
        id: 'lot_123',
        ticker: 'SYS',
        shares: 100,
        pricePerShare: 550.0,
        date: DateTime(2023, 10, 1),
      );

      final json = lot.toJson();
      final fromJson = LotModel.fromJson(json);

      expect(fromJson.id, lot.id);
      expect(fromJson.ticker, lot.ticker);
      expect(fromJson.shares, lot.shares);
      expect(fromJson.pricePerShare, lot.pricePerShare);
      expect(fromJson.date, lot.date);
      expect(fromJson, lot); // Freezed models support equality
    });

    test('SaleModel roundtrip serialization', () {
      final sale = SaleModel(
        id: 'sale_123',
        lotId: 'lot_123',
        shares: 50,
        pricePerShare: 600.0,
        date: DateTime(2023, 10, 15),
      );

      final json = sale.toJson();
      final fromJson = SaleModel.fromJson(json);

      expect(fromJson.id, sale.id);
      expect(fromJson.lotId, sale.lotId);
      expect(fromJson.shares, sale.shares);
      expect(fromJson.pricePerShare, sale.pricePerShare);
      expect(fromJson.date, sale.date);
      expect(fromJson, sale); // Freezed models support equality
    });
  });
}

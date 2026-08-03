import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/data/models/lot_model.dart';
import 'package:stock_investment_tracker/data/models/sale_model.dart';

void main() {
  group('Model Serialization Tests', () {
    test('LotModel roundtrip serialization', () {
      final lot = LotModel(
        id: 'lot_123',
        ticker: 'SYS',
        sharesPurchased: 100,
        buyPricePerShare: 550.0,
        buyDate: DateTime(2023, 10, 1),
      );

      final json = lot.toJson();
      final fromJson = LotModel.fromJson(json);

      expect(fromJson.id, lot.id);
      expect(fromJson.ticker, lot.ticker);
      expect(fromJson.sharesPurchased, lot.sharesPurchased);
      expect(fromJson.buyPricePerShare, lot.buyPricePerShare);
      expect(fromJson.buyDate, lot.buyDate);
      expect(fromJson, lot); // Freezed models support equality
    });

    test('SaleModel roundtrip serialization', () {
      final sale = SaleModel(
        id: 'sale_123',
        sharesSold: 50,
        sellPricePerShare: 600.0,
        sellDate: DateTime(2023, 10, 15),
      );

      final json = sale.toJson();
      final fromJson = SaleModel.fromJson(json);

      expect(fromJson.id, sale.id);
      expect(fromJson.sharesSold, sale.sharesSold);
      expect(fromJson.sellPricePerShare, sale.sellPricePerShare);
      expect(fromJson.sellDate, sale.sellDate);
      expect(fromJson, sale); // Freezed models support equality
    });
  });
}

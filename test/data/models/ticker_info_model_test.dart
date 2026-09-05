import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/data/models/ticker_info_model.dart';
import 'package:stock_investment_tracker/domain/entities/ticker_info.dart';

void main() {
  group('TickerInfoModel', () {
    test('toJson and fromJson work correctly with all fields', () {
      const model = TickerInfoModel(
        symbol: 'SYS',
        name: 'Systems Limited',
        sector: 'Technology',
      );

      final json = model.toJson();
      expect(json['symbol'], 'SYS');
      expect(json['name'], 'Systems Limited');
      expect(json['sector'], 'Technology');

      final fromJson = TickerInfoModel.fromJson(json);
      expect(fromJson, model);
    });

    test('toJson and fromJson work correctly with null sector', () {
      const model = TickerInfoModel(
        symbol: 'SYS',
        name: 'Systems Limited',
        sector: null,
      );

      final json = model.toJson();
      expect(json['symbol'], 'SYS');
      expect(json['name'], 'Systems Limited');
      expect(json['sector'], null);

      final fromJson = TickerInfoModel.fromJson(json);
      expect(fromJson, model);
    });

    test('fromEntity and toEntity work correctly', () {
      const entity = TickerInfo(
        symbol: 'SYS',
        name: 'Systems Limited',
        sector: 'Technology',
      );

      final model = TickerInfoModel.fromEntity(entity);
      expect(model.symbol, entity.symbol);
      expect(model.name, entity.name);
      expect(model.sector, entity.sector);

      final backToEntity = model.toEntity();
      expect(backToEntity, entity);
    });
  });
}

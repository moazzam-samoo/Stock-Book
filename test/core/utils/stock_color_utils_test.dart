import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/core/utils/stock_color_utils.dart';

void main() {
  group('StockColorUtils Tests', () {
    test('getColorForTicker generates consistent color for same ticker', () {
      final color1 = StockColorUtils.getColorForTicker('STPL');
      final color2 = StockColorUtils.getColorForTicker('STPL');
      expect(color1, equals(color2));
    });

    test('getColorForTicker generates distinct colors for different tickers', () {
      final colorSTPL = StockColorUtils.getColorForTicker('STPL');
      final colorBNL = StockColorUtils.getColorForTicker('BNL');
      expect(colorSTPL, isNot(equals(colorBNL)));
    });

    test('getColorForIndex generates distinct colors up to palette size', () {
      final colors = <Color>{};
      for (int i = 0; i < 16; i++) {
        colors.add(StockColorUtils.getColorForIndex(i));
      }
      expect(colors.length, equals(16));
    });
  });
}

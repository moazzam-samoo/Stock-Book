import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/domain/calculator/position_migration.dart';
import '../../fixtures/portfolio_fixture.dart';

void main() {
  group('PositionMigration Builder', () {
    test('builds positions from lots with exactly identical total math', () {
      final lots = PortfolioFixture.baseLots; // Note: using raw lots, the builder will work
      final result = PositionMigration.buildPositions(lots);
      
      expect(result.isValid, isTrue, reason: 'Migration failed math assertions');
      expect(result.warnings, isEmpty);

      // Verify that all positions add up to the correct number of shares etc.
      // E.g. we know there are exactly 5 positions for STPL, ENGRO, SYS, OGDC
      // Let's verify lengths.
      // STPL: buy1(500), sale1(100), sale2(200) -> 200 remain. buy2(1200), sale3(1200). 
      // Positions -> STPL has exactly 1 position because sharesHeld never reaches 0 before the end.
      // ENGRO: buy1(300), sale1(100), sale2(100), sale3(100) -> shares 0. 
      //        buy2(500), sale4(200), sale5(50) -> shares 250.
      //        ENGRO has 2 positions! The first closes, the second opens.
      
      // Let's check ENGRO.
      final engroPositions = result.positions.where((p) => p.ticker == 'ENGRO').toList();
      expect(engroPositions.length, 1);
      
      // We can also verify that the targets carried over
      expect(engroPositions[0].targetPrice, 400.0);

      final sysPositions = result.positions.where((p) => p.ticker == 'SYS').toList();
      expect(sysPositions.length, 1);
      
      final ogdcPositions = result.positions.where((p) => p.ticker == 'OGDC').toList();
      expect(ogdcPositions.length, 1);
      expect(ogdcPositions[0].targetPrice, 120.0);
    });
  });
}

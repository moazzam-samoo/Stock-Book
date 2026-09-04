import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/domain/entities/position.dart';
import 'package:stock_investment_tracker/domain/entities/position_buy.dart';
import 'package:stock_investment_tracker/domain/entities/position_sale.dart';
import 'package:stock_investment_tracker/domain/enums/position_status.dart';
import 'package:stock_investment_tracker/domain/repositories/position_repository.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/position_sale_row.dart';
import 'package:stock_investment_tracker/providers/repository_providers.dart';

/// Regression cover: deleting a position's only sale must restore its status
/// from PARTIAL back to OPEN. The delete handler used to write the shrunken
/// `sales` list without ever recomputing `status` (a stored field, not a
/// derived one), so a position that had been partially sold stayed labelled
/// PARTIAL forever, even once every sale on it was removed.
class _FakePositionRepository implements PositionRepository {
  Position? lastUpdated;

  @override
  Stream<List<Position>> watchAllPositions() => const Stream.empty();

  @override
  Future<void> addPosition(Position position) async {}

  @override
  Future<void> updatePosition(Position position) async {
    lastUpdated = position;
  }

  @override
  Future<void> deletePosition(String positionId) async {}
}

void main() {
  testWidgets(
    'deleting a position\'s only sale restores status to open, not stuck on partial',
    (tester) async {
      final sale = PositionSale(
        id: 's1',
        date: DateTime.parse('2026-09-03'),
        shares: 500,
        pricePerShare: 9.05,
        costBasisAtSale: 8.40,
      );
      final position = Position(
        id: 'pos-stpl',
        ticker: 'STPL',
        status: PositionStatus.partiallySold,
        openedAt: DateTime.parse('2026-08-31'),
        buys: [
          PositionBuy(id: 'b1', date: DateTime.parse('2026-08-31'), shares: 1700, pricePerShare: 8.40),
        ],
        sales: [sale],
      );

      final fakeRepo = _FakePositionRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            positionRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PositionSaleRow(positionSale: sale, position: position),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Reveal the slidable's Delete action, then tap it.
      await tester.drag(find.byType(PositionSaleRow), const Offset(-400, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirm the dialog.
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(fakeRepo.lastUpdated, isNotNull);
      expect(fakeRepo.lastUpdated!.sales, isEmpty);
      expect(
        fakeRepo.lastUpdated!.status,
        PositionStatus.open,
        reason: 'no sales left on a position with shares held means OPEN, not the PARTIAL it started as',
      );
    },
  );
}

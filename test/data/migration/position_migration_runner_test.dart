import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stock_investment_tracker/data/data_sources/remote/firestore_data_source.dart';
import 'package:stock_investment_tracker/data/migration/position_migration_runner.dart';
import 'package:stock_investment_tracker/data/models/lot_model.dart';
import 'package:stock_investment_tracker/data/models/position_model.dart';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import '../../fixtures/portfolio_fixture.dart';
import 'position_migration_runner_test.mocks.dart';

@GenerateMocks([FirestoreDataSource])
void main() {
  late MockFirestoreDataSource mockDataSource;
  late PositionMigrationRunner runner;
  
  const uid = 'test-uid';

  setUp(() {
    mockDataSource = MockFirestoreDataSource();
    runner = PositionMigrationRunner(mockDataSource, uid);
  });

  group('PositionMigrationRunner', () {
    test('returns immediately if schemaVersion >= 2', () async {
      when(mockDataSource.getUserSchemaVersion(uid)).thenAnswer((_) async => 2);
      
      final outcome = await runner.runIfNeeded();
      
      expect(outcome.success, isTrue);
      verify(mockDataSource.getUserSchemaVersion(uid)).called(1);
      verifyNever(mockDataSource.getAllLotsOnce(any));
    });

    test('stamps schemaVersion and returns if no lots exist', () async {
      when(mockDataSource.getUserSchemaVersion(uid)).thenAnswer((_) async => 1);
      when(mockDataSource.getAllLotsOnce(uid)).thenAnswer((_) async => []);
      when(mockDataSource.stampSchemaVersion(uid, 2)).thenAnswer((_) async {});
      
      final outcome = await runner.runIfNeeded();
      
      expect(outcome.success, isTrue);
      verify(mockDataSource.stampSchemaVersion(uid, 2)).called(1);
      verifyNever(mockDataSource.runPositionMigrationBatches(any, any, any));
    });

    test('runs migration successfully for existing lots', () async {
      when(mockDataSource.getUserSchemaVersion(uid)).thenAnswer((_) async => null);
      
      // We need LotModels to return
      final lotsModels = PortfolioFixture.baseLots.map((l) => LotModelExtension.fromEntity(l)).toList();
      when(mockDataSource.getAllLotsOnce(uid)).thenAnswer((_) async => lotsModels);
      
      when(mockDataSource.runPositionMigrationBatches(any, any, any)).thenAnswer((_) async {});
      
      final outcome = await runner.runIfNeeded();
      
      expect(outcome.success, isTrue);
      
      verify(mockDataSource.runPositionMigrationBatches(
        uid, 
        argThat(isNotEmpty), 
        2,
      )).called(1);
    });

    test('returns failure if migration validation fails', () async {
      when(mockDataSource.getUserSchemaVersion(uid)).thenAnswer((_) async => 1);

      // Make a broken lot that will fail validation (negative shares)
      final brokenLot = LotModelExtension.fromEntity(PortfolioFixture.baseLots.first).copyWith(
        sharesPurchased: -100,
      );

      when(mockDataSource.getAllLotsOnce(uid)).thenAnswer((_) async => [brokenLot]);

      final outcome = await runner.runIfNeeded();

      expect(outcome.success, isFalse);
      expect(outcome.errorMessage, contains('failed'));

      verifyNever(mockDataSource.runPositionMigrationBatches(any, any, any));
    });

    test('is idempotent: a second call after schemaVersion is stamped does nothing further', () async {
      // First call: needs migration, succeeds.
      when(mockDataSource.getUserSchemaVersion(uid)).thenAnswer((_) async => 1);
      final lotsModels = PortfolioFixture.baseLots.map((l) => LotModelExtension.fromEntity(l)).toList();
      when(mockDataSource.getAllLotsOnce(uid)).thenAnswer((_) async => lotsModels);
      when(mockDataSource.runPositionMigrationBatches(any, any, any)).thenAnswer((_) async {});

      final firstOutcome = await runner.runIfNeeded();
      expect(firstOutcome.success, isTrue);
      // Consume (mark verified) every call made by the first run, so the
      // verifyNever checks below only see calls made by the second run.
      verify(mockDataSource.runPositionMigrationBatches(any, any, any)).called(1);
      verify(mockDataSource.getAllLotsOnce(uid)).called(1);

      // Second call: the schemaVersion the runner reads now reflects what the
      // first call just stamped (in a real run, via the same WriteBatch).
      when(mockDataSource.getUserSchemaVersion(uid)).thenAnswer((_) async => 2);

      final secondOutcome = await runner.runIfNeeded();
      expect(secondOutcome.success, isTrue);

      // The idempotent second run must not touch lots or write positions again.
      verifyNever(mockDataSource.runPositionMigrationBatches(any, any, any));
      verifyNever(mockDataSource.getAllLotsOnce(uid));
    });

    test('hands the full position list to the data source even above the 450-write batch limit', () async {
      when(mockDataSource.getUserSchemaVersion(uid)).thenAnswer((_) async => null);

      // 500 distinct single-lot tickers -> 500 positions from one buildPositions() call.
      // The runner's job is just to pass all of them through in one call;
      // FirestoreDataSource.runPositionMigrationBatches owns the actual
      // >450 chunking (see its own implementation) and isn't re-tested here.
      final manyLots = List.generate(500, (i) {
        return LotModelExtension.fromEntity(Lot(
          id: 'lot-$i',
          ticker: 'TICK$i',
          buyDate: DateTime.parse('2026-01-01'),
          sharesPurchased: 100,
          buyPricePerShare: 10.0,
          amountInvested: 1000.0,
        ));
      });
      when(mockDataSource.getAllLotsOnce(uid)).thenAnswer((_) async => manyLots);

      List<PositionModel>? capturedPositions;
      when(mockDataSource.runPositionMigrationBatches(any, any, any)).thenAnswer((invocation) async {
        capturedPositions = invocation.positionalArguments[1] as List<PositionModel>;
      });

      final outcome = await runner.runIfNeeded();

      expect(outcome.success, isTrue);
      expect(capturedPositions, isNotNull);
      expect(capturedPositions!.length, 500);
      verify(mockDataSource.runPositionMigrationBatches(uid, any, 2)).called(1);
    });
  });
}

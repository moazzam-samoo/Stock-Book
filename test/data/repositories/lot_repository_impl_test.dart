import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stock_investment_tracker/data/data_sources/remote/firestore_data_source.dart';
import 'package:stock_investment_tracker/data/models/lot_model.dart';
import 'package:stock_investment_tracker/data/repositories/lot_repository_impl.dart';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'lot_repository_impl_test.mocks.dart';

@GenerateMocks([FirestoreDataSource])
void main() {
  late LotRepositoryImpl repository;
  late MockFirestoreDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockFirestoreDataSource();
    repository = LotRepositoryImpl(
      uid: 'user_123',
      firestoreDataSource: mockDataSource,
    );
  });

  group('LotRepositoryImpl', () {
    final tLotModel = LotModel(
      id: 'lot1',
      ticker: 'SYS',
      sharesPurchased: 100,
      buyPricePerShare: 50.0,
      buyDate: DateTime(2023, 1, 1),
    );

    final tLot = Lot(
      id: 'lot1',
      ticker: 'SYS',
      sharesPurchased: 100,
      buyPricePerShare: 50.0,
      amountInvested: 5000.0,
      buyDate: DateTime(2023, 1, 1),
    );

    test('addLot calls addLot on dataSource', () async {
      when(mockDataSource.addLot(any, any)).thenAnswer((_) async {});

      await repository.addLot(tLot);

      verify(mockDataSource.addLot('user_123', tLotModel)).called(1);
    });

    test('deleteLot calls deleteLot on dataSource', () async {
      when(mockDataSource.deleteLot(any, any)).thenAnswer((_) async {});

      await repository.deleteLot('lot1');

      verify(mockDataSource.deleteLot('user_123', 'lot1')).called(1);
    });

    test('updateLot calls updateLot on dataSource', () async {
      when(mockDataSource.updateLot(any, any)).thenAnswer((_) async {});

      await repository.updateLot(tLot);

      verify(mockDataSource.updateLot('user_123', tLotModel)).called(1);
    });

    test('watchAllLots yields mapped entities', () {
      when(mockDataSource.watchAllLots('user_123')).thenAnswer((_) => Stream.value([tLotModel]));

      expect(
        repository.watchAllLots(),
        emits([tLot.copyWith(amountInvested: 5000.0)]),
      );
    });
  });
}

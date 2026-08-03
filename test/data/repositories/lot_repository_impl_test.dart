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
    repository = LotRepositoryImpl(mockDataSource);
  });

  group('LotRepositoryImpl', () {
    final tLotModel = LotModel(
      id: 'lot1',
      ticker: 'SYS',
      shares: 100,
      pricePerShare: 50.0,
      date: DateTime(2023, 1, 1),
    );

    final tLot = Lot(
      id: 'lot1',
      ticker: 'SYS',
      shares: 100,
      pricePerShare: 50.0,
      date: DateTime(2023, 1, 1),
    );

    test('addLot calls addDocument on dataSource', () async {
      when(mockDataSource.addDocument(any, any)).thenAnswer((_) async => 'lot1');

      await repository.addLot(tLot);

      verify(mockDataSource.addDocument('lots', tLotModel.toJson())).called(1);
    });

    test('deleteLot calls deleteDocument on dataSource', () async {
      when(mockDataSource.deleteDocument(any, any)).thenAnswer((_) async {});

      await repository.deleteLot('lot1');

      verify(mockDataSource.deleteDocument('lots', 'lot1')).called(1);
    });

    test('updateLot calls updateDocument on dataSource', () async {
      when(mockDataSource.updateDocument(any, any, any)).thenAnswer((_) async {});

      await repository.updateLot(tLot);

      verify(mockDataSource.updateDocument('lots', 'lot1', tLotModel.toJson())).called(1);
    });

    test('getLotsStream yields mapped entities', () {
      when(mockDataSource.getCollectionStream('lots')).thenAnswer((_) => Stream.value([
            {'id': 'lot1', ...tLotModel.toJson()}
          ]));

      expect(
        repository.getLotsStream(),
        emits([tLot]),
      );
    });
  });
}

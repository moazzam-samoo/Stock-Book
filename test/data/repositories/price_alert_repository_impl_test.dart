import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stock_investment_tracker/data/data_sources/remote/firestore_data_source.dart';
import 'package:stock_investment_tracker/data/models/price_alert_model.dart';
import 'package:stock_investment_tracker/data/repositories/price_alert_repository_impl.dart';

import 'price_alert_repository_impl_test.mocks.dart';

@GenerateMocks([FirestoreDataSource])
void main() {
  late MockFirestoreDataSource mockDataSource;
  late PriceAlertRepositoryImpl repository;
  const uid = 'test-uid';

  setUp(() {
    mockDataSource = MockFirestoreDataSource();
    repository = PriceAlertRepositoryImpl(mockDataSource, uid);
  });

  group('PriceAlertRepositoryImpl', () {
    final alertModel = PriceAlertModel(
      id: '1',
      ticker: 'GUSM',
      targetPrice: 10,
      tolerancePercent: 1.0,
      isActive: true,
      alertSent: false,
      alertSentAt: null,
      createdAt: DateTime(2026, 9, 5),
    );

    test('addAlert maps entity to model and calls data source', () async {
      when(mockDataSource.addPriceAlert(uid, any))
          .thenAnswer((_) async => {});

      await repository.addAlert(alertModel.toEntity());

      verify(mockDataSource.addPriceAlert(uid, any)).called(1);
    });

    test('updateAlert calls data source with updated model', () async {
      when(mockDataSource.updatePriceAlert(uid, any))
          .thenAnswer((_) async => {});

      await repository.updateAlert(alertModel.toEntity());

      verify(mockDataSource.updatePriceAlert(uid, any)).called(1);
    });

    test('deleteAlert calls data source with correct path', () async {
      when(mockDataSource.deletePriceAlert(uid, '1'))
          .thenAnswer((_) async => {});

      await repository.deleteAlert('1');

      verify(mockDataSource.deletePriceAlert(uid, '1')).called(1);
    });

    test('watchAllAlerts streams models mapped to entities', () {
      when(mockDataSource.watchAllPriceAlerts(uid))
          .thenAnswer((_) => Stream.value([alertModel]));

      expect(
        repository.watchAllAlerts(),
        emits([alertModel.toEntity()]),
      );
    });
  });
}

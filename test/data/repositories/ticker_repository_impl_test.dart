import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stock_investment_tracker/data/data_sources/local/hive_data_source.dart';
import 'package:stock_investment_tracker/data/repositories/ticker_repository_impl.dart';

import 'ticker_repository_impl_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  DocumentReference,
  DocumentSnapshot,
  HiveDataSource,
])
void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockDocumentReference<Map<String, dynamic>> mockDocRef;
  late MockDocumentSnapshot<Map<String, dynamic>> mockDocSnapshot;
  late MockHiveDataSource mockHiveDataSource;
  late TickerRepositoryImpl repository;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockDocRef = MockDocumentReference();
    mockDocSnapshot = MockDocumentSnapshot();
    mockHiveDataSource = MockHiveDataSource();

    when(mockFirestore.doc(any)).thenReturn(mockDocRef);

    repository = TickerRepositoryImpl(
      firestore: mockFirestore,
      hiveDataSource: mockHiveDataSource,
    );
  });

  group('TickerRepositoryImpl', () {
    // Regression: this fixture must match what the backend actually writes
    // (scripts/price_alerts/firestore_io.py::write_tickers_doc uses the key
    // `companies`) — a fixture using the wrong key would pass against a repo
    // implementation with the same wrong key without ever proving it reads
    // the real document.
    final validFirestoreData = {
      'companies': [
        {'symbol': 'SYS', 'name': 'Systems Limited', 'sector': 'Technology'},
        {'symbol': 'ENGRO', 'name': 'Engro Corp', 'sector': 'Fertilizer'},
      ]
    };

    final validHiveData = [
      {'symbol': 'SYS', 'name': 'Systems Limited', 'sector': 'Technology'},
      {'symbol': 'ENGRO', 'name': 'Engro Corp', 'sector': 'Fertilizer'},
    ];

    test('getAll fetches from Firestore and saves to Hive on success', () async {
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
      when(mockDocSnapshot.exists).thenReturn(true);
      when(mockDocSnapshot.data()).thenReturn(validFirestoreData);
      
      when(mockHiveDataSource.saveTickers(any)).thenAnswer((_) async {});

      final result = await repository.getAll();

      expect(result.length, 2);
      expect(result.first.symbol, 'SYS');
      expect(result.first.name, 'Systems Limited');
      expect(result.last.symbol, 'ENGRO');

      verify(mockFirestore.doc('tickers/all')).called(1);
      verify(mockDocRef.get()).called(1);
      verify(mockHiveDataSource.saveTickers(validHiveData)).called(1);
      verifyNever(mockHiveDataSource.getTickers());
    });

    test('getAll falls back to Hive cache on Firestore failure', () async {
      when(mockDocRef.get()).thenThrow(Exception('Network Error'));
      when(mockHiveDataSource.getTickers()).thenAnswer((_) async => validHiveData);

      final result = await repository.getAll();

      expect(result.length, 2);
      expect(result.first.symbol, 'SYS');

      verify(mockDocRef.get()).called(1);
      verify(mockHiveDataSource.getTickers()).called(1);
      verifyNever(mockHiveDataSource.saveTickers(any));
    });

    test('getAll returns empty list when both Firestore and Hive fail', () async {
      when(mockDocRef.get()).thenThrow(Exception('Network Error'));
      when(mockHiveDataSource.getTickers()).thenThrow(Exception('Hive Error'));

      final result = await repository.getAll();

      expect(result, isEmpty);

      verify(mockDocRef.get()).called(1);
      verify(mockHiveDataSource.getTickers()).called(1);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stock_investment_tracker/data/repositories/market_status_repository_impl.dart';
import 'package:stock_investment_tracker/core/constants/firestore_paths.dart';

import 'market_status_repository_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  DocumentReference,
  DocumentSnapshot,
])
void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockDocumentReference<Map<String, dynamic>> mockDocRef;
  late MarketStatusRepositoryImpl repository;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockDocRef = MockDocumentReference<Map<String, dynamic>>();
    
    when(mockFirestore.doc(FirestorePaths.marketStatus()))
        .thenReturn(mockDocRef);

    repository = MarketStatusRepositoryImpl(
      firestore: mockFirestore,
    );
  });

  group('MarketStatusRepositoryImpl', () {
    test('watchStatus maps snapshot to entity', () async {
      final mockSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      final timestamp = Timestamp.fromDate(DateTime(2023, 1, 1, 10, 0, 0));
      
      when(mockSnapshot.exists).thenReturn(true);
      when(mockSnapshot.data()).thenReturn({
        'isOpen': true,
        'label': 'Open',
        'checkedAt': timestamp,
      });

      when(mockDocRef.snapshots()).thenAnswer((_) => Stream.value(mockSnapshot));

      final stream = repository.watchStatus();
      final result = await stream.first;

      expect(result, isNotNull);
      expect(result!.isOpen, true);
      expect(result.label, 'Open');
      expect(result.checkedAt, timestamp.toDate());
    });

    test('watchStatus returns null when document does not exist', () async {
      final mockSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      
      when(mockSnapshot.exists).thenReturn(false);
      when(mockSnapshot.data()).thenReturn(null);

      when(mockDocRef.snapshots()).thenAnswer((_) => Stream.value(mockSnapshot));

      final stream = repository.watchStatus();
      final result = await stream.first;

      expect(result, isNull);
    });

    test('watchStatus returns null on parsing error', () async {
      final mockSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      
      when(mockSnapshot.exists).thenReturn(true);
      when(mockSnapshot.data()).thenReturn({
        'isOpen': 'invalid_type', // Should cause parsing error
        'label': 'Open',
        'checkedAt': Timestamp.now(),
      });

      when(mockDocRef.snapshots()).thenAnswer((_) => Stream.value(mockSnapshot));

      final stream = repository.watchStatus();
      final result = await stream.first;

      expect(result, isNull);
    });
  });
}

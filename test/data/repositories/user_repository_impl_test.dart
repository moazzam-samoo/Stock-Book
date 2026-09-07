import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stock_investment_tracker/core/constants/firestore_paths.dart';
import 'package:stock_investment_tracker/data/data_sources/remote/firestore_data_source.dart';
import 'package:stock_investment_tracker/data/repositories/user_repository_impl.dart';

import 'user_repository_impl_test.mocks.dart';

@GenerateMocks([FirestoreDataSource, FirebaseFirestore, DocumentReference])
void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockDocumentReference<Map<String, dynamic>> mockDocRef;
  late UserRepositoryImpl repository;

  const uid = 'test_uid_123';
  const token = 'test_fcm_token_abc';

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockDocRef = MockDocumentReference<Map<String, dynamic>>();

    when(mockFirestore.doc(FirestorePaths.user(uid))).thenReturn(mockDocRef);

    repository = UserRepositoryImpl(
      uid: uid,
      firestore: mockFirestore,
    );
  });

  test('savePushToken sets token with merge options on users/{uid}', () async {
    when(mockDocRef.set(any, any)).thenAnswer((_) async => {});

    await repository.savePushToken(token);

    final captured = verify(mockDocRef.set(captureAny, captureAny)).captured;
    
    final data = captured[0] as Map<String, dynamic>;
    expect(data['fcmToken'], token);
    expect(data['fcmTokenUpdatedAt'], isA<FieldValue>()); // serverTimestamp

    final setOptions = captured[1] as SetOptions;
    expect(setOptions.merge, true);
  });

  test('savePushToken swallows timeout (offline tolerance)', () async {
    // The underlying Firestore write never resolves within the 4s timeout —
    // simulates a stuck/offline write.
    when(mockDocRef.set(any, any)).thenAnswer(
        (_) => Future.delayed(const Duration(seconds: 5), () => {}));

    final stopwatch = Stopwatch()..start();
    // Must resolve on its own — a hang here means the timeout didn't fire and
    // the whole app would freeze waiting on a stuck network write.
    await repository.savePushToken(token).timeout(const Duration(seconds: 6));
    stopwatch.stop();

    // The internal .timeout(4s) must be what ended this, not the 5s mock
    // delay resolving on its own — proves offline tolerance is actually the
    // timeout firing, not a coincidence of the mock's own timing.
    expect(
      stopwatch.elapsedMilliseconds,
      lessThan(4500),
      reason: 'savePushToken should give up at ~4s, not wait for the stuck 5s write',
    );
  });

  test('savePushToken swallows synchronous firestore errors instead of throwing', () async {
    // A save failure must never block sign-in/app startup — it's logged
    // (so the failure is no longer invisible) but never propagated.
    when(mockDocRef.set(any, any)).thenThrow(Exception('Firestore error'));

    await expectLater(repository.savePushToken(token), completes);
  });
}

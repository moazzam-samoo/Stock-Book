import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stock_investment_tracker/core/error/app_exception.dart';
import 'package:stock_investment_tracker/data/data_sources/local/hive_data_source.dart';
import 'package:stock_investment_tracker/data/repositories/firebase_auth_repository.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockUser extends Mock implements User {}
class MockHiveDataSource extends Mock implements HiveDataSource {}

void main() {
  group('FirebaseAuthRepository deleteAccount flow (C3)', () {
    late MockFirebaseAuth mockAuth;
    late MockGoogleSignIn mockGoogleSignIn;
    late MockHiveDataSource mockHive;
    late MockUser mockUser;
    late FirebaseAuthRepository repository;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockGoogleSignIn = MockGoogleSignIn();
      mockHive = MockHiveDataSource();
      mockUser = MockUser();

      when(() => mockUser.uid).thenReturn('test_uid_123');
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      repository = FirebaseAuthRepository(
        firebaseAuth: mockAuth,
        googleSignIn: mockGoogleSignIn,
        hiveDataSource: mockHive,
      );
    });

    test('re-authentication cancellation throws AuthException and does not delete user', () async {
      // Google Sign-In returns null (user cancelled the system account dialog)
      when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

      expect(
        () => repository.deleteAccount(),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('Re-authentication was cancelled'),
        )),
      );

      // Verify that user account deletion and local cache clearing were never invoked
      verifyNever(() => mockUser.delete());
      verifyNever(() => mockHive.clearSettings(any()));
    });

    test('returns immediately when currentUser is null', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      await repository.deleteAccount();

      verifyNever(() => mockGoogleSignIn.signIn());
      verifyNever(() => mockUser.delete());
    });
  });
}


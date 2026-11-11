import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/domain/repositories/auth_repository.dart';
import 'package:stock_investment_tracker/presentation/auth/controllers/auth_controller.dart';
import 'package:stock_investment_tracker/presentation/auth/providers/auth_providers.dart';

class _FakeAuthRepository implements AuthRepository {
  bool deleteAccountCalled = false;
  Object? deleteAccountError;

  @override
  Stream<User?> authStateChanges() => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  Future<UserCredential?> signInWithGoogle() async => null;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {
    deleteAccountCalled = true;
    if (deleteAccountError != null) throw deleteAccountError!;
  }
}

void main() {
  test('deleteAccount calls through to the repository and ends in data state on success', () async {
    final fakeRepo = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);

    final error = await container.read(authControllerProvider.notifier).deleteAccount();

    expect(fakeRepo.deleteAccountCalled, isTrue);
    expect(error, isNull);
    expect(container.read(authControllerProvider).hasError, isFalse);
  });

  test('deleteAccount returns the failure so callers never need to re-read provider state', () async {
    final fakeRepo = _FakeAuthRepository()
      ..deleteAccountError = Exception('boom');
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);

    final error = await container.read(authControllerProvider.notifier).deleteAccount();

    expect(error, isA<Exception>());
  });

  test('controller survives with no listeners (keepAlive) so state set after a long await is safe', () async {
    // Regression: autoDispose controller + only ref.read(...notifier) meant
    // the controller could be disposed while deleteAccount() was in flight.
    final fakeRepo = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);

    final future = container.read(authControllerProvider.notifier).deleteAccount();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await expectLater(future, completes);
  });

  test('deleteAccount surfaces a repository failure as controller error state, not a thrown exception', () async {
    final fakeRepo = _FakeAuthRepository()
      ..deleteAccountError = Exception('requires-recent-login');
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);

    // AsyncValue.guard inside the controller must catch this, not let it
    // propagate — a caller awaiting deleteAccount() should never see an
    // unhandled exception, only the resulting error state.
    await container.read(authControllerProvider.notifier).deleteAccount();

    expect(fakeRepo.deleteAccountCalled, isTrue);
    expect(container.read(authControllerProvider).hasError, isTrue);
  });
}

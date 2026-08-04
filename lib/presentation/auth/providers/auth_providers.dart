import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../data/repositories/firebase_auth_repository.dart';
import '../../../domain/repositories/auth_repository.dart';

part 'auth_providers.g.dart';


@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return FirebaseAuthRepository();
}

@riverpod
Stream<User?> authState(AuthStateRef ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
}

@riverpod
String? currentUserId(CurrentUserIdRef ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
}


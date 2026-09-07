import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Stream<User?> authStateChanges();
  User? get currentUser;
  Future<UserCredential?> signInWithGoogle();
  Future<void> signOut();

  /// Permanently deletes the signed-in user's Firestore data (positions,
  /// price alerts, withdrawals, lots, settings) and their Firebase Auth
  /// account. If the session is too old, Firebase requires a fresh
  /// re-authentication first — implementations should prompt for that
  /// (re-running Google Sign-In) and retry once, rather than surfacing the
  /// raw `requires-recent-login` error to the caller.
  Future<void> deleteAccount();
}

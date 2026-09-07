import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/error/app_exception.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_paths.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User canceled the sign-in
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user != null) {
        await FirebaseFirestore.instance
            .doc(FirestorePaths.user(user.uid))
            .set({
              'uid': user.uid,
              'email': user.email,
              'username': user.displayName ?? '',
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true))
            .timeout(const Duration(seconds: 5))
            .catchError((_) => null); // Ignore timeout/offline errors, local caching handles it
      }

      return userCredential;
    } catch (e) {
      throw AuthException('Failed to sign in with Google: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw AuthException('Failed to sign out: $e');
    }
  }

  @override
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    try {
      await _deleteAllFirestoreData(uid);
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') {
        throw AuthException('Failed to delete account: ${e.message}');
      }
      // Session too old for a destructive operation — Firebase requires a
      // fresh credential. Firestore data may already be gone from the first
      // attempt above; re-running it is safe since every delete here is
      // idempotent (deleting an already-absent doc is a no-op, not an error).
      await _reauthenticate(user);
      await _deleteAllFirestoreData(uid);
      await user.delete();
    } catch (e) {
      throw AuthException('Failed to delete account: $e');
    }

    await _googleSignIn.signOut();
  }

  Future<void> _reauthenticate(User user) async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw AuthException(
        'Re-authentication was cancelled. Please sign in again and retry deleting your account.',
      );
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await user.reauthenticateWithCredential(credential);
  }

  /// Deletes every Firestore doc under `users/{uid}` — must run **before**
  /// `user.delete()`, since `firestore.rules` gates every write on
  /// `request.auth.uid == userId`, which stops being true the instant the
  /// auth account itself is gone.
  Future<void> _deleteAllFirestoreData(String uid) async {
    final firestore = FirebaseFirestore.instance;

    Future<void> deleteCollection(String path) async {
      final snapshot = await firestore.collection(path).get();
      if (snapshot.docs.isEmpty) return;
      final batch = firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    // Firestore doesn't cascade-delete subcollections when a parent doc is
    // deleted — each one has to be cleared explicitly. `lots/{id}/sales` is
    // excluded: nothing writes there (see AGENTS.md §4.1), sales live
    // embedded in the lot doc itself.
    await Future.wait([
      deleteCollection(FirestorePaths.lots(uid)),
      deleteCollection(FirestorePaths.positions(uid)),
      deleteCollection(FirestorePaths.priceAlerts(uid)),
      deleteCollection(FirestorePaths.withdrawals(uid)),
    ]);

    await firestore.doc(FirestorePaths.settings(uid)).delete();
    await firestore.doc(FirestorePaths.user(uid)).delete();
  }
}

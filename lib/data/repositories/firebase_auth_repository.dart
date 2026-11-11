import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:stock_investment_tracker/core/constants/firestore_paths.dart';
import 'package:stock_investment_tracker/core/error/app_exception.dart';
import 'package:stock_investment_tracker/data/data_sources/local/hive_data_source.dart';
import 'package:stock_investment_tracker/domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final HiveDataSource _hiveDataSource;

  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    HiveDataSource? hiveDataSource,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _hiveDataSource = hiveDataSource ?? HiveDataSource();

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
      final currentUid = _firebaseAuth.currentUser?.uid;
      if (currentUid != null) {
        await _hiveDataSource.clearSettings(currentUid);
      }
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
      // 1. Re-authenticate FIRST before deleting anything.
      // If the user cancels the Google Sign-In prompt or re-auth fails,
      // it throws and stops execution — preserving all user data.
      await _reauthenticate(user);

      // 2. Only once credential is confirmed, delete all Firestore documents.
      await _deleteAllFirestoreData(uid);

      // 3. Delete the auth account itself.
      await user.delete();

      // 4. Clear local Hive cache for this user.
      await _hiveDataSource.clearSettings(uid);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to delete account: $e');
    }

    // 5. Sign out of Google.
    await _googleSignIn.signOut();
  }

  Future<void> _reauthenticate(User user) async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthException(
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../../core/constants/firestore_paths.dart';
import '../../core/utils/logger.dart';
import '../../domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final String uid;
  final FirebaseFirestore firestore;
  final Logger _logger = appLogger;

  UserRepositoryImpl({
    required this.uid,
    required this.firestore,
  });

  @override
  Future<void> savePushToken(String token) async {
    // Deliberately swallows the error rather than throwing (a token save
    // failing must never block sign-in/app startup), but a swallowed
    // failure used to leave zero trace anywhere — the backend would then
    // silently send push alerts to a stale/missing token forever, with
    // no error on either side. Logging it here at least makes that
    // failure mode visible instead of invisible.
    try {
      await firestore
          .doc(FirestorePaths.user(uid))
          .set(
        {
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      )
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      _logger.e('Failed to save push token for $uid: $e');
    }
  }
}

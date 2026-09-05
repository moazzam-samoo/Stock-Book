import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_paths.dart';
import '../../core/error/app_exception.dart';
import '../../domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final String uid;
  final FirebaseFirestore firestore;

  UserRepositoryImpl({
    required this.uid,
    required this.firestore,
  });

  @override
  Future<void> savePushToken(String token) async {
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
          .timeout(const Duration(seconds: 4))
          .catchError((_) => null); // Offline tolerance
    } catch (e) {
      throw NetworkException('Failed to save push token: $e');
    }
  }
}

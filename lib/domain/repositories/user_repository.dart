abstract class UserRepository {
  /// Saves the FCM push notification token for the user.
  /// Also updates the `fcmTokenUpdatedAt` timestamp.
  Future<void> savePushToken(String token);
}

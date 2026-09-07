import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../providers/auth_providers.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {}

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(authRepositoryProvider)
          .signInWithGoogle()
          .timeout(const Duration(seconds: 15));
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(authRepositoryProvider)
          .signOut()
          .timeout(const Duration(seconds: 15));
    });
  }

  /// No timeout, unlike the other two — this can involve a full
  /// re-authentication round trip (the user picking their Google account
  /// again) if the session is old, which a fixed 15s budget could cut off
  /// mid-flow on a slow connection.
  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).deleteAccount();
    });
  }
}

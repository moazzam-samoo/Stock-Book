import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../providers/auth_providers.dart';

part 'auth_controller.g.dart';

// keepAlive: this controller is only ever reached via
// `ref.read(authControllerProvider.notifier)` from Settings, so nothing
// watches it there. As autoDispose it was torn down mid-`deleteAccount()`:
// the moment `user.delete()` succeeds, auth state goes null and the router
// leaves Settings, and the later `state = ...` threw "Bad state" — surfacing
// a false "Could not delete account" for a deletion that had actually worked.
@Riverpod(keepAlive: true)
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
  ///
  /// Returns the failure (or `null` on success) directly instead of making the
  /// caller re-read it from provider state afterwards. On success the auth
  /// stream goes null and the router leaves Settings, so the calling widget is
  /// already disposed by the time this returns — any `ref.read(...)` on that
  /// widget's `ref` would throw "Cannot use ref after the widget was disposed".
  Future<Object?> deleteAccount() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).deleteAccount();
    });
    return state.error;
  }
}

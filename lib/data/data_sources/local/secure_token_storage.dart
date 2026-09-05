import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Device-only storage for the GitHub token used to trigger on-demand price
/// refreshes.
///
/// Deliberately *not* Firestore and *not* Hive: this is a credential. Firestore
/// would sync it off-device and expose it to anything holding the user's
/// Firebase session; Hive is unencrypted at rest by default. This uses the
/// platform keystore (Android Keystore / iOS Keychain), which is the only
/// option here that keeps a secret at rest properly.
///
/// It is also never committed and never compiled into the APK — the user
/// pastes their own token in Settings, so nothing secret exists in the build.
class SecureTokenStorage {
  static const String _githubTokenKey = 'github_actions_token';

  final FlutterSecureStorage _storage;

  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  Future<String?> readGithubToken() async {
    try {
      return await _storage.read(key: _githubTokenKey);
    } catch (_) {
      // A keystore read can fail outright after an OS restore-to-new-device or
      // a corrupted keystore entry. Treat it as "no token" rather than
      // crashing a pull-to-refresh — the user can just re-enter it.
      return null;
    }
  }

  Future<void> writeGithubToken(String token) async {
    await _storage.write(key: _githubTokenKey, value: token.trim());
  }

  Future<void> deleteGithubToken() async {
    await _storage.delete(key: _githubTokenKey);
  }

  Future<bool> hasGithubToken() async {
    final token = await readGithubToken();
    return token != null && token.trim().isNotEmpty;
  }
}

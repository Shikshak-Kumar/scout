import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_constants.dart';
import 'auth_token.dart';

/// Riverpod provider exposing [SecureTokenStorage].
final secureStorageProvider = Provider<SecureTokenStorage>((ref) {
  return SecureTokenStorage();
});

/// Thin typed wrapper around [FlutterSecureStorage] for token persistence.
///
/// On Web, flutter_secure_storage uses AES-encrypted localStorage.
/// On Android/iOS it uses Keystore / Keychain respectively.
class SecureTokenStorage {
  SecureTokenStorage()
      : _storage = const FlutterSecureStorage(
          // Android: use encrypted shared preferences (default on modern Android).
          aOptions: AndroidOptions.defaultOptions,
        );

  final FlutterSecureStorage _storage;

  Future<void> saveToken(AuthToken token) async {
    await Future.wait([
      _storage.write(
        key: AuthConstants.kAccessToken,
        value: token.accessToken,
      ),
      _storage.write(
        key: AuthConstants.kRefreshToken,
        value: token.refreshToken,
      ),
      _storage.write(
        key: AuthConstants.kIdToken,
        value: token.idToken,
      ),
      _storage.write(
        key: AuthConstants.kExpiresAt,
        value: token.expiresAt.toIso8601String(),
      ),
    ]);
  }

  Future<AuthToken?> loadToken() async {
    final results = await Future.wait([
      _storage.read(key: AuthConstants.kAccessToken),
      _storage.read(key: AuthConstants.kRefreshToken),
      _storage.read(key: AuthConstants.kIdToken),
      _storage.read(key: AuthConstants.kExpiresAt),
    ]);

    final accessToken = results[0];
    final expiresAtStr = results[3];

    if (accessToken == null || expiresAtStr == null) return null;

    return AuthToken(
      accessToken: accessToken,
      refreshToken: results[1],
      idToken: results[2],
      expiresAt: DateTime.parse(expiresAtStr),
    );
  }

  Future<void> clearToken() async {
    await Future.wait([
      _storage.delete(key: AuthConstants.kAccessToken),
      _storage.delete(key: AuthConstants.kRefreshToken),
      _storage.delete(key: AuthConstants.kIdToken),
      _storage.delete(key: AuthConstants.kExpiresAt),
    ]);
  }
}

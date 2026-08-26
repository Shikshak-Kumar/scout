import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();
final appAuth = FlutterAppAuth();

const String _clientId = 'scout-mobile';
const String _redirectUrl = 'com.scoutapp.scout_mobile://oauth2redirect';
const String _issuer = 'http://localhost:8080/realms/scout';
const String _discoveryUrl = '$_issuer/.well-known/openid-configuration';

final authStateProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<bool> {
  AuthNotifier() : super(false) {
    _checkToken();
  }

  Future<void> _checkToken() async {
    final token = await storage.read(key: 'access_token');
    if (token != null) {
      state = true;
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      final AuthorizationTokenResponse result = await appAuth
          .authorizeAndExchangeCode(
            AuthorizationTokenRequest(
              _clientId,
              _redirectUrl,
              discoveryUrl: _discoveryUrl,
              scopes: ['openid', 'profile', 'email', 'offline_access'],
              promptValues: ['login'],
              additionalParameters: {'kc_idp_hint': 'google'},
            ),
          );

      if (result.accessToken != null) {
        await storage.write(key: 'access_token', value: result.accessToken);
        if (result.refreshToken != null) {
          await storage.write(key: 'refresh_token', value: result.refreshToken);
        }
        state = true;
      }
    } catch (e) {
      // Handle login error (e.g., cancelled by user)
      state = false;
      rethrow;
    }
  }

  Future<bool> refreshToken() async {
    final refreshToken = await storage.read(key: 'refresh_token');
    if (refreshToken == null) {
      return false;
    }

    try {
      final TokenResponse result = await appAuth.token(
        TokenRequest(
          _clientId,
          _redirectUrl,
          discoveryUrl: _discoveryUrl,
          refreshToken: refreshToken,
          scopes: ['openid', 'profile', 'email', 'offline_access'],
        ),
      );

      if (result.accessToken != null) {
        await storage.write(key: 'access_token', value: result.accessToken);
        if (result.refreshToken != null) {
          await storage.write(key: 'refresh_token', value: result.refreshToken);
        }
        state = true;
        return true;
      }
    } catch (e) {
      await logout();
    }
    return false;
  }

  Future<void> logout() async {
    await storage.deleteAll();
    state = false;
  }
}

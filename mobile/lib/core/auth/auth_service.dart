import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();
const _appAuth = FlutterAppAuth();

const _clientId = String.fromEnvironment(
  'KEYCLOAK_CLIENT_ID',
  defaultValue: 'scout-mobile',
);
const _issuer = String.fromEnvironment(
  'KEYCLOAK_ISSUER',
  defaultValue: 'http://localhost:8080/realms/scout',
);
const _redirectUrl = 'scout://oauthredirect';
const _scopes = ['openid', 'profile', 'email', 'offline_access'];

const _serviceConfiguration = AuthorizationServiceConfiguration(
  authorizationEndpoint: '$_issuer/protocol/openid-connect/auth',
  tokenEndpoint: '$_issuer/protocol/openid-connect/token',
  endSessionEndpoint: '$_issuer/protocol/openid-connect/logout',
);

final authStateProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<bool> {
  AuthNotifier() : super(false) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    state = await storage.containsKey(key: 'access_token');
  }

  Future<void> loginWithGoogle() async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Flutter AppAuth is a native plugin. Run Scout on the Android device, not Chrome.',
      );
    }

    final result = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        _clientId,
        _redirectUrl,
        serviceConfiguration: _serviceConfiguration,
        scopes: _scopes,
        additionalParameters: const {'kc_idp_hint': 'google'},
        allowInsecureConnections: true,
      ),
    );

    final accessToken = result.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('Keycloak did not return an access token.');
    }
    await storage.write(key: 'access_token', value: accessToken);
    await storage.write(key: 'refresh_token', value: result.refreshToken);
    await storage.write(key: 'id_token', value: result.idToken);
    state = true;
  }

  Future<bool> refreshToken() async {
    final refreshToken = await storage.read(key: 'refresh_token');
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final result = await _appAuth.token(
        TokenRequest(
          _clientId,
          _redirectUrl,
          refreshToken: refreshToken,
          serviceConfiguration: _serviceConfiguration,
          scopes: _scopes,
          allowInsecureConnections: true,
        ),
      );
      final accessToken = result.accessToken;
      if (accessToken == null || accessToken.isEmpty) return false;
      await storage.write(key: 'access_token', value: accessToken);
      await storage.write(
        key: 'refresh_token',
        value: result.refreshToken ?? refreshToken,
      );
      await storage.write(key: 'id_token', value: result.idToken);
      state = true;
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  Future<void> logout() async {
    await storage.deleteAll();
    state = false;
  }
}

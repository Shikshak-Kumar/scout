import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'auth_constants.dart';
import 'auth_service.dart';
import 'auth_token.dart';
import 'secure_storage.dart';

/// Mobile (Android / iOS) implementation using [flutter_appauth].
///
/// flutter_appauth handles PKCE S256 generation and token exchange internally.
/// It opens the authorization URL in a Chrome Custom Tab (Android) or
/// SFSafariViewController (iOS), then receives the redirect via the custom
/// URI scheme registered in AndroidManifest.xml and Info.plist.
class MobileAuthService implements AuthService {
  MobileAuthService(this._storage);

  final SecureTokenStorage _storage;
  final FlutterAppAuth _appAuth = const FlutterAppAuth();

  @override
Future<bool> loginWithGoogle() {
  return _login('google');
}

@override
Future<bool> loginWithGithub() {
  return _login('github');
}

Future<bool> _login(String provider) async {
  try {
    final result = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        AuthConstants.clientId,
        AuthConstants.mobileRedirectUri,
        issuer: AuthConstants.issuer,
        scopes: AuthConstants.scopes,
        additionalParameters: {
          'kc_idp_hint': provider,
        },
        allowInsecureConnections: true,
      ),
    );

    final accessToken = result.accessToken;
    if (accessToken == null) return false;

    final expiresAt = result.accessTokenExpirationDateTime ??
        DateTime.now().toUtc().add(const Duration(minutes: 5));

    await _storage.saveToken(
      AuthToken(
        accessToken: accessToken,
        refreshToken: result.refreshToken,
        idToken: result.idToken,
        expiresAt: expiresAt,
      ),
    );

    return true;
  } catch (e) {
    debugPrint('[MobileAuthService] login error: $e');
    return false;
  }
}

  @override
  Future<String?> getAccessToken() async {
    final token = await getToken();
    if (token == null) return null;

    // Refresh if expiring within 60 seconds.
    if (token.expiresWithin(const Duration(seconds: 60)) &&
        token.refreshToken != null) {
      return _refresh(token.refreshToken!);
    }

    return token.isExpired ? null : token.accessToken;
  }

  Future<String?> _refresh(String refreshToken) async {
    try {
      final result = await _appAuth.token(
        TokenRequest(
          AuthConstants.clientId,
          AuthConstants.mobileRedirectUri,
          issuer: AuthConstants.issuer,
          refreshToken: refreshToken,
          scopes: AuthConstants.scopes,
          allowInsecureConnections: true,
        ),
      );

      final accessToken = result.accessToken;
      if (accessToken == null) {
        await _storage.clearToken();
        return null;
      }

      final expiresAt = result.accessTokenExpirationDateTime ??
          DateTime.now().toUtc().add(const Duration(minutes: 5));

      final newToken = AuthToken(
        accessToken: accessToken,
        refreshToken: result.refreshToken,
        idToken: result.idToken,
        expiresAt: expiresAt,
      );

      await _storage.saveToken(newToken);
      return newToken.accessToken;
    } catch (e) {
      debugPrint('[MobileAuthService] token refresh error: $e');
      await _storage.clearToken();
      return null;
    }
  }

  @override
  Future<void> logout() async {
    final token = await _storage.loadToken();
    await _storage.clearToken();

    if (token?.idToken != null) {
      try {
        // End the Keycloak session via the end-session endpoint.
        await _appAuth.endSession(
          EndSessionRequest(
            idTokenHint: token!.idToken,
            issuer: AuthConstants.issuer,
            postLogoutRedirectUrl: AuthConstants.mobileRedirectUri,
            allowInsecureConnections: true,
          ),
        );
      } catch (e) {
        // Session end failure is non-fatal — tokens are already cleared.
        debugPrint('[MobileAuthService] logout session end error: $e');
      }
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final accessToken = await getAccessToken();
    return accessToken != null;
  }

  @override
  Future<AuthToken?> getToken() => _storage.loadToken();
}

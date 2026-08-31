// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pkce/pkce.dart';

import 'auth_constants.dart';
import 'auth_service.dart';
import 'auth_token.dart';
import 'secure_storage.dart';

/// Web implementation of [AuthService].
///
/// Flow:
///   1. Generate PKCE code verifier + challenge (S256) via the `pkce` package.
///   2. Open a popup window pointing at Keycloak with kc_idp_hint=google.
///   3. Keycloak redirects to /auth_callback.html which calls window.opener.postMessage.
///   4. We receive the authorization code via postMessage.
///   5. Exchange the code for tokens via a direct HTTP POST to the token endpoint
///      (CORS works because Web Origins is configured on the Keycloak client).
///   6. Persist tokens via flutter_secure_storage (encrypted localStorage on web).
class WebAuthService implements AuthService {
  WebAuthService(this._storage);

  final SecureTokenStorage _storage;

  // Derive the web redirect URI from the current window origin at runtime.
  // This avoids hardcoding the port and works with any --web-port value.
  String get _redirectUri =>
      '${html.window.location.origin}${AuthConstants.webRedirectPath}';

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
    final pkce = PkcePair.generate();

    final state = _generateState();

    final authUrl = Uri.parse(AuthConstants.authorizationEndpoint)
        .replace(queryParameters: {
      'response_type': 'code',
      'client_id': AuthConstants.clientId,
      'redirect_uri': _redirectUri,
      'scope': AuthConstants.scopes.join(' '),
      'state': state,
      'code_challenge': pkce.codeChallenge,
      'code_challenge_method': 'S256',
      'kc_idp_hint': provider,
    });

    final code = await _openPopupAndWaitForCode(
      authUrl.toString(),
      state,
    );

    if (code == null) return false;

    final token = await _exchangeCode(
      code: code,
      codeVerifier: pkce.codeVerifier,
    );

    if (token == null) return false;

    await _storage.saveToken(token);
    return true;
  } catch (e) {
    debugPrint('[WebAuthService] login error: $e');
    return false;
  }
}

  Future<String?> _openPopupAndWaitForCode(
    String authUrl,
    String expectedState,
  ) async {
    const popupFeatures =
        'width=520,height=640,left=200,top=100,resizable=yes,scrollbars=yes';

    final popup = html.window.open(authUrl, 'kc_oauth', popupFeatures);

    final completer = Completer<String?>();
    StreamSubscription<html.MessageEvent>? sub;

    // Safety timeout — if the popup is closed or never responds.
    Timer? timeoutTimer;
    Timer? closedCheckTimer;

    void cleanup() {
      sub?.cancel();
      timeoutTimer?.cancel();
      closedCheckTimer?.cancel();
    }

    // Detect if user manually closed the popup.
    closedCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (popup.closed == true && !completer.isCompleted) {
        cleanup();
        completer.complete(null);
      }
    });

    timeoutTimer = Timer(const Duration(minutes: 5), () {
      if (!completer.isCompleted) {
        cleanup();
        completer.complete(null);
      }
    });

    sub = html.window.onMessage.listen((event) {
      // Only accept messages from our own origin (the callback page).
      if (event.origin != html.window.location.origin) return;

      final data = event.data;
      if (data is! Map) return;

      final type = data['type'];
      if (type != 'oauth_callback') return;

      final receivedState = data['state'] as String?;
      final code = data['code'] as String?;
      final error = data['error'] as String?;

      cleanup();

      if (error != null) {
        debugPrint('[WebAuthService] OAuth error from popup: $error');
        completer.complete(null);
        return;
      }

      if (receivedState != expectedState || code == null) {
        debugPrint('[WebAuthService] State mismatch or missing code');
        completer.complete(null);
        return;
      }

      completer.complete(code);
    });

    return completer.future;
  }

  Future<AuthToken?> _exchangeCode({
    required String code,
    required String codeVerifier,
  }) async {
    final response = await http.post(
      Uri.parse(AuthConstants.tokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'client_id': AuthConstants.clientId,
        'redirect_uri': _redirectUri,
        'code': code,
        'code_verifier': codeVerifier,
      },
    );

    if (response.statusCode != 200) {
      debugPrint(
        '[WebAuthService] Token exchange failed ${response.statusCode}: ${response.body}',
      );
      return null;
    }

    return _parseTokenResponse(response.body);
  }

  Future<AuthToken?> _refreshTokens(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse(AuthConstants.tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'client_id': AuthConstants.clientId,
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode != 200) {
        await _storage.clearToken();
        return null;
      }

      final token = _parseTokenResponse(response.body);
      if (token != null) await _storage.saveToken(token);
      return token;
    } catch (e) {
      debugPrint('[WebAuthService] token refresh error: $e');
      await _storage.clearToken();
      return null;
    }
  }

  AuthToken? _parseTokenResponse(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;

    final accessToken = json['access_token'] as String?;
    if (accessToken == null) return null;

    final expiresIn = (json['expires_in'] as num?)?.toInt() ?? 300;
    final expiresAt =
        DateTime.now().toUtc().add(Duration(seconds: expiresIn));

    return AuthToken(
      accessToken: accessToken,
      refreshToken: json['refresh_token'] as String?,
      idToken: json['id_token'] as String?,
      expiresAt: expiresAt,
    );
  }

  @override
  Future<String?> getAccessToken() async {
    final token = await getToken();
    if (token == null) return null;

    if (token.expiresWithin(const Duration(seconds: 60)) &&
        token.refreshToken != null) {
      final refreshed = await _refreshTokens(token.refreshToken!);
      return refreshed?.accessToken;
    }

    return token.isExpired ? null : token.accessToken;
  }

  @override
  Future<void> logout() async {
    final token = await _storage.loadToken();
    await _storage.clearToken();

    if (token?.idToken != null) {
      // Redirect to Keycloak end-session endpoint to clear the SSO session.
      // We navigate the main window (not a popup) so the user sees it complete.
      final logoutUrl = Uri.parse(AuthConstants.endSessionEndpoint)
          .replace(queryParameters: {
        'id_token_hint': token!.idToken!,
        'post_logout_redirect_uri': html.window.location.origin,
        'client_id': AuthConstants.clientId,
      });
      html.window.location.replace(logoutUrl.toString());
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final accessToken = await getAccessToken();
    return accessToken != null;
  }

  @override
  Future<AuthToken?> getToken() => _storage.loadToken();

  /// Generates a cryptographically random state parameter.
  String _generateState() {
  final random = Random.secure();

  final bytes = List<int>.generate(
    32,
    (_) => random.nextInt(256),
  );

  return base64Url.encode(bytes).replaceAll('=', '');
}
}
AuthService createPlatformAuthService(SecureTokenStorage storage) {
  return WebAuthService(storage);
}
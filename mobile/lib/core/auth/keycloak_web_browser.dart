import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:web/web.dart' as web;

const _issuer = String.fromEnvironment(
  'KEYCLOAK_ISSUER',
  defaultValue: 'http://localhost:8080/realms/scout',
);
const _clientId = String.fromEnvironment(
  'KEYCLOAK_CLIENT_ID',
  defaultValue: 'scout-mobile',
);
const _verifierKey = 'scout_oidc_verifier';
const _stateKey = 'scout_oidc_state';

String get _redirectUri {
  final current = Uri.base;
  return Uri(
    scheme: current.scheme,
    host: current.host,
    port: current.hasPort ? current.port : null,
    path: '/',
  ).toString();
}

String _randomUrlSafe(int length) {
  final random = Random.secure();
  final bytes = List<int>.generate(length, (_) => random.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}

Future<void> startKeycloakWebLogin() async {
  final verifier = _randomUrlSafe(64);
  final state = _randomUrlSafe(32);
  final challenge = base64Url
      .encode(sha256.convert(utf8.encode(verifier)).bytes)
      .replaceAll('=', '');

  web.window.sessionStorage.setItem(_verifierKey, verifier);
  web.window.sessionStorage.setItem(_stateKey, state);

  final authorizationUrl = Uri.parse('$_issuer/protocol/openid-connect/auth')
      .replace(
        queryParameters: {
          'client_id': _clientId,
          'redirect_uri': _redirectUri,
          'response_type': 'code',
          'scope': 'openid profile email offline_access',
          'state': state,
          'code_challenge': challenge,
          'code_challenge_method': 'S256',
          'kc_idp_hint': 'google',
        },
      );
  web.window.location.href = authorizationUrl.toString();
}

Future<Map<String, String>?> handleKeycloakWebCallback() async {
  final parameters = Uri.base.queryParameters;
  final providerError = parameters['error'];
  if (providerError != null) {
    _clearCallbackState();
    throw StateError(parameters['error_description'] ?? providerError);
  }

  final code = parameters['code'];
  if (code == null) return null;

  final expectedState = web.window.sessionStorage.getItem(_stateKey);
  final verifier = web.window.sessionStorage.getItem(_verifierKey);
  if (expectedState == null ||
      verifier == null ||
      parameters['state'] != expectedState) {
    _clearCallbackState();
    throw StateError('Keycloak login state validation failed.');
  }

  final tokens = await _tokenRequest({
    'grant_type': 'authorization_code',
    'client_id': _clientId,
    'redirect_uri': _redirectUri,
    'code': code,
    'code_verifier': verifier,
  });
  _clearCallbackState();
  web.window.history.replaceState(null, '', _redirectUri);
  return tokens;
}

Future<Map<String, String>?> refreshKeycloakWebToken(
  String refreshToken,
) async {
  return _tokenRequest({
    'grant_type': 'refresh_token',
    'client_id': _clientId,
    'refresh_token': refreshToken,
  });
}

Future<Map<String, String>> _tokenRequest(Map<String, String> data) async {
  final response = await Dio().post<Map<String, dynamic>>(
    '$_issuer/protocol/openid-connect/token',
    data: data,
    options: Options(contentType: Headers.formUrlEncodedContentType),
  );
  final body = response.data;
  if (body == null || body['access_token'] is! String) {
    throw const FormatException('Keycloak did not return an access token.');
  }
  return {
    'access_token': body['access_token'] as String,
    if (body['refresh_token'] is String)
      'refresh_token': body['refresh_token'] as String,
    if (body['id_token'] is String) 'id_token': body['id_token'] as String,
  };
}

void _clearCallbackState() {
  web.window.sessionStorage.removeItem(_verifierKey);
  web.window.sessionStorage.removeItem(_stateKey);
}

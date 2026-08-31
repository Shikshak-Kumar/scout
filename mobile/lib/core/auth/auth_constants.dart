import 'package:flutter/foundation.dart';

// Single source of truth for Keycloak configuration.
class AuthConstants {
  AuthConstants._();

  static const String realm = 'scout';
  static const String clientId = 'scout-mobile';

  static const String mobileHost = String.fromEnvironment(
    'DEV_HOST',
    defaultValue: 'localhost',
  );

  static String get keycloakHost {
    if (kIsWeb) {
      return 'localhost';
    }

    return mobileHost;
  }

  static String get keycloakUrl => 'http://$keycloakHost:8080';

  static String get issuer => '$keycloakUrl/realms/$realm';

  static String get _oidcBase =>
      '$keycloakUrl/realms/$realm/protocol/openid-connect';

  static String get authorizationEndpoint => '$_oidcBase/auth';

  static String get tokenEndpoint => '$_oidcBase/token';

  static String get endSessionEndpoint => '$_oidcBase/logout';

  static const String mobileRedirectUri = 'com.scoutapp.scoutmobile:/oauthredirect';

  static const String webRedirectPath = '/auth_callback.html';

  static const List<String> scopes = ['openid', 'profile', 'email'];

  static const String kAccessToken = 'kc_access_token';
  static const String kRefreshToken = 'kc_refresh_token';
  static const String kIdToken = 'kc_id_token';
  static const String kExpiresAt = 'kc_expires_at';
}
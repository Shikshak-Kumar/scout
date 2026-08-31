// Single source of truth for Keycloak configuration.
// Update these values if your realm or client settings change.
class AuthConstants {
  AuthConstants._();

  static const String keycloakUrl = 'http://localhost:8080';
  static const String realm = 'scout';
  static const String clientId = 'scout-mobile';

  /// The OpenID Connect issuer URL.
  static const String issuer = '$keycloakUrl/realms/$realm';

  /// Base URL for all OpenID Connect endpoints.
  static const String _oidcBase =
      '$keycloakUrl/realms/$realm/protocol/openid-connect';

  static const String authorizationEndpoint = '$_oidcBase/auth';
  static const String tokenEndpoint = '$_oidcBase/token';
  static const String endSessionEndpoint = '$_oidcBase/logout';

  /// Custom scheme redirect used by Android / iOS (flutter_appauth).
  static const String mobileRedirectUri =
      'com.scoutapp.scout_mobile:/oauthredirect';

  /// Web redirect served at this path relative to the Flutter web origin.
  /// Flutter web dev server must be started with --web-port 3000:
  ///   flutter run -d chrome --web-port 3000
  static const String webRedirectPath = '/auth_callback.html';

  static const List<String> scopes = ['openid', 'profile', 'email'];

  // Secure-storage keys
  static const String kAccessToken = 'kc_access_token';
  static const String kRefreshToken = 'kc_refresh_token';
  static const String kIdToken = 'kc_id_token';
  static const String kExpiresAt = 'kc_expires_at';
}

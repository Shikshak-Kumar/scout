import 'auth_token.dart';

/// Platform-agnostic authentication contract.
/// Concrete implementations live in auth_service_mobile.dart (flutter_appauth)
/// and auth_service_web.dart (dart:html popup + fetch).
abstract class AuthService {
  /// Starts the Google OAuth flow via kc_idp_hint=google.
  /// Returns [true] on success, [false] or throws on failure.
  Future<bool> loginWithGoogle();

  Future<bool> loginWithGithub();

  /// Returns the current access token, refreshing it if necessary.
  /// Returns [null] if the user is not authenticated.
  Future<String?> getAccessToken();

  /// Clears stored tokens and ends the Keycloak session.
  Future<void> logout();

  /// Returns [true] if a valid (non-expired) token is persisted.
  Future<bool> isAuthenticated();

  /// Returns the full token bundle or [null] if not authenticated.
  Future<AuthToken?> getToken();
}

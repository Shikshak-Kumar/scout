import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';
import 'auth_service_mobile.dart';
import 'secure_storage.dart';
import 'auth_service_factory.dart';

// Web import is conditional — only compiled when targeting web.
import 'auth_service_web.dart'
    if (dart.library.io) 'auth_service_mobile.dart';

/// Provides the correct [AuthService] implementation for the current platform.
///
///  • kIsWeb  →  [WebAuthService]  (dart:html popup + HTTP token exchange)
///  • mobile  →  [MobileAuthService] (flutter_appauth Chrome Custom Tabs / SFSafariViewController)
final authServiceProvider = Provider<AuthService>((ref) {
  final storage = SecureTokenStorage();
  return createAuthService(storage);
});

// ---------------------------------------------------------------------------
// Auth state notifier
// ---------------------------------------------------------------------------

/// Tracks whether the user is authenticated.
///
/// [AsyncValue.loading]  — initial check in progress
/// [AsyncValue.data(true)]  — authenticated
/// [AsyncValue.data(false)] — not authenticated
/// [AsyncValue.error]    — an unexpected error occurred during check/login
class AuthNotifier extends AsyncNotifier<bool> {
  late AuthService _service;

  @override
  Future<bool> build() async {
    _service = ref.watch(authServiceProvider);
    // On startup, check for a persisted valid token.
    return _service.isAuthenticated();
  }

  /// Triggers the Google login flow.
  /// Sets state to [AsyncValue.loading] during the flow, then resolves.
  Future<bool> loginWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final success = await _service.loginWithGoogle();
      state = AsyncValue.data(success);
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> loginWithGithub() async {
  state = const AsyncValue.loading();

  try {
    final success = await _service.loginWithGithub();
    state = AsyncValue.data(success);
    return success;
  } catch (e, st) {
    state = AsyncValue.error(e, st);
    return false;
  }
}

  /// Returns the current access token (refresh is handled internally).
  Future<String?> getAccessToken() => _service.getAccessToken();

  /// Logs out and clears state.
  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await _service.logout();
    } finally {
      state = const AsyncValue.data(false);
    }
  }
}

/// The main provider to watch for auth state throughout the app.
final authStateProvider = AsyncNotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
);

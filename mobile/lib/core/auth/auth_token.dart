import 'package:flutter/foundation.dart';

/// Immutable token bundle returned by both Web and Mobile auth paths.
@immutable
class AuthToken {
  const AuthToken({
    required this.accessToken,
    required this.refreshToken,
    required this.idToken,
    required this.expiresAt,
  });

  final String accessToken;
  final String? refreshToken;
  final String? idToken;

  /// UTC timestamp when the access token expires.
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);

  /// Returns true when the token will expire within [threshold].
  bool expiresWithin(Duration threshold) =>
      DateTime.now().toUtc().isAfter(expiresAt.subtract(threshold));

  @override
  String toString() =>
      'AuthToken(expires: $expiresAt, expired: $isExpired)';
}

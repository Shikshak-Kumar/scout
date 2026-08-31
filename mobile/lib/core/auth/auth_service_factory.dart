import 'auth_service.dart';
import 'secure_storage.dart';
import 'auth_service_mobile.dart'
    if (dart.library.html) 'auth_service_web.dart';

AuthService createAuthService(SecureTokenStorage storage) {
  return createPlatformAuthService(storage);
}
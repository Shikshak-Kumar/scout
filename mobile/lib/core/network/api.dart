import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();
final dioProvider = Provider<Dio>((ref) {
  const base = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/v1',
  );
  final dio = Dio(
    BaseOptions(
      baseUrl: base,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: 'access_token');
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) await storage.deleteAll();
        handler.next(error);
      },
    ),
  );
  return dio;
});

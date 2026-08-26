import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/opportunities/presentation/opportunity.dart';
import '../auth/auth_service.dart';

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
        if (error.response?.statusCode == 401) {
          final refreshed = await ref.read(authStateProvider.notifier).refreshToken();
          if (refreshed) {
            // Retry the request with the new token
            final token = await storage.read(key: 'access_token');
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final cloneReq = await dio.request(
              error.requestOptions.path,
              options: Options(
                method: error.requestOptions.method,
                headers: error.requestOptions.headers,
              ),
              data: error.requestOptions.data,
              queryParameters: error.requestOptions.queryParameters,
            );
            return handler.resolve(cloneReq);
          } else {
            await ref.read(authStateProvider.notifier).logout();
          }
        }
        handler.next(error);
      },
    ),
  );
  return dio;
});

// Discover screen state providers
final discoverSearchQueryProvider = StateProvider<String>((ref) => '');
final discoverCategoryProvider = StateProvider<String>((ref) => 'All');

final discoverFeedProvider = FutureProvider.autoDispose<List<Opportunity>>((ref) async {
  final query = ref.watch(discoverSearchQueryProvider);
  final category = ref.watch(discoverCategoryProvider);
  final dio = ref.watch(dioProvider);
  final params = <String, dynamic>{};
  if (query.isNotEmpty) params['q'] = query;
  if (category != 'All') {
    params['category'] = category.toLowerCase().replaceAll(' ', '_');
  }
  final response = await dio.get('/opportunities', queryParameters: params);
  return (response.data['items'] as List)
      .map((e) => Opportunity.fromJson(e))
      .toList();
});

// Saved opportunities provider
final savedFeedProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final response = await ref.watch(dioProvider).get('/opportunities/saved');
  return List<Map<String, dynamic>>.from(response.data);
});

// Tracked applications provider
final applicationsFeedProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final response = await ref.watch(dioProvider).get('/opportunities/applications');
  return List<Map<String, dynamic>>.from(response.data);
});

// Profile provider and notifier
class ProfileNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final Ref ref;
  ProfileNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = const AsyncValue.loading();
    try {
      final response = await ref.read(dioProvider).get('/auth/me');
      state = AsyncValue.data(response.data as Map<String, dynamic>);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile(Map<String, dynamic> profile) async {
    try {
      final response = await ref.read(dioProvider).patch(
        '/auth/me',
        data: {'profile': profile},
      );
      state = AsyncValue.data(response.data as Map<String, dynamic>);
    } catch (e) {
      // Keep existing state
    }
  }
}

final profileProvider = StateNotifierProvider.autoDispose<ProfileNotifier, AsyncValue<Map<String, dynamic>>>((ref) {
  return ProfileNotifier(ref);
});

// Opportunity Service for saved / application modifications
final opportunityServiceProvider = Provider((ref) => OpportunityService(ref));

class OpportunityService {
  final Ref _ref;
  OpportunityService(this._ref);

  Future<void> saveOpportunity({
    required String opportunityId,
    required String status,
    String? notes,
    String? applicationDate,
    String? interviewDate,
  }) async {
    final dio = _ref.read(dioProvider);
    await dio.put(
      '/opportunities/$opportunityId/saved',
      data: {
        'status': status,
        'notes': notes,
        'application_date': applicationDate,
        'interview_date': interviewDate,
      },
    );
    _ref.invalidate(savedFeedProvider);
    _ref.invalidate(applicationsFeedProvider);
  }
}

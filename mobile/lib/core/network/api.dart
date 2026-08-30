import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/opportunities/presentation/opportunity.dart';

final dioProvider = Provider<Dio>((ref) {
  const base = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
  final dio = Dio(
    BaseOptions(
      baseUrl: base,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  return dio;
});

// Discover screen state providers
final discoverSearchQueryProvider = StateProvider<String>((ref) => '');
final discoverCategoryProvider = StateProvider<String>((ref) => 'All');

final discoverFeedProvider = FutureProvider.autoDispose<List<Opportunity>>((
  ref,
) async {
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
final savedFeedProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final response = await ref.watch(dioProvider).get('/opportunities/saved');
      return List<Map<String, dynamic>>.from(response.data);
    });

// Tracked applications provider
final applicationsFeedProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final response = await ref
          .watch(dioProvider)
          .get('/opportunities/applications');
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
      final response = await ref
          .read(dioProvider)
          .patch('/auth/me', data: {'profile': profile});
      state = AsyncValue.data(response.data as Map<String, dynamic>);
    } catch (e) {
      // Keep existing state
    }
  }
}

final profileProvider =
    StateNotifierProvider.autoDispose<
      ProfileNotifier,
      AsyncValue<Map<String, dynamic>>
    >((ref) {
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api.dart';
import 'opportunity.dart';

// ---------------------------------------------------------------------------
// Shared API provider
// ---------------------------------------------------------------------------

final apiProvider = Provider<Api>((ref) => Api());

// ---------------------------------------------------------------------------
// Opportunity service provider
// ---------------------------------------------------------------------------

final opportunityServiceProvider = Provider<_OpportunityActions>((ref) {
  final api = ref.watch(apiProvider);
  return _OpportunityActions(api);
});

class _OpportunityActions {
  final Api _api;
  _OpportunityActions(this._api);

  Future<void> saveOpportunity({
    required String opportunityId,
    required String status,
    String? notes,
  }) async {
    await _api.post('/saved', {
      'opportunity_id': opportunityId,
      'status': status,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
  }
}

// ---------------------------------------------------------------------------
// Feed provider – used by HomeScreen
// ---------------------------------------------------------------------------

final feedProvider = FutureProvider.autoDispose<List<Opportunity>>((ref) async {
  final api = ref.watch(apiProvider);
  final response = await api.get('/opportunities');
  final rawItems = _toList(response['items'] ?? response['opportunities']);
  return rawItems
      .map((e) => Opportunity.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Saved opportunities provider – used by SavedScreen
// ---------------------------------------------------------------------------

final savedFeedProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiProvider);
  final response = await api.get('/saved');
  return _toList(response['items'] ?? response['saved'])
      .cast<Map<String, dynamic>>();
});

// ---------------------------------------------------------------------------
// Applications feed provider – used by ApplicationsScreen
// ---------------------------------------------------------------------------

final applicationsFeedProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiProvider);
  final response = await api.get('/applications');
  return _toList(response['items'] ?? response['applications'])
      .cast<Map<String, dynamic>>();
});

// ---------------------------------------------------------------------------
// Discover screen providers
// ---------------------------------------------------------------------------

final discoverSearchQueryProvider = StateProvider<String>((ref) => '');
final discoverCategoryProvider = StateProvider<String>((ref) => 'All');

final discoverFeedProvider =
    FutureProvider.autoDispose<List<Opportunity>>((ref) async {
  final api = ref.watch(apiProvider);
  final query = ref.watch(discoverSearchQueryProvider);
  final category = ref.watch(discoverCategoryProvider);

  final params = StringBuffer('/opportunities?');
  if (query.isNotEmpty) params.write('q=${Uri.encodeComponent(query)}&');
  if (category != 'All') {
    params.write('category=${Uri.encodeComponent(category)}&');
  }

  final response = await api.get(params.toString().replaceAll(RegExp(r'&$'), ''));
  final rawItems = _toList(response['items'] ?? response['opportunities']);
  return rawItems
      .map((e) => Opportunity.fromJson(e as Map<String, dynamic>))
      .toList();
});

// Safely coerce a value that should be a List to List,
// returning an empty list if it is null or not a List.
List<dynamic> _toList(dynamic value) {
  if (value is List) return value;
  return const [];
}

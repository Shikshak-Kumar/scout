import '../../../core/network/api.dart';
import 'opportunity.dart';

class OpportunityService {
  final Api _api = Api();

  Future<List<Opportunity>> getOpportunities({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get(
      '/opportunities?page=$page&limit=$limit',
    );

    final opportunities = response['opportunities'] as List;

    return opportunities
        .map(
          (item) => Opportunity.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}
import 'package:flutter/material.dart';

import '../opportunity.dart';
import '../opportunity_service.dart';


class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  State<OpportunitiesScreen> createState() =>
      _OpportunitiesScreenState();
}


class _OpportunitiesScreenState
    extends State<OpportunitiesScreen> {
  final OpportunityService _service = OpportunityService();

  late Future<List<Opportunity>> _opportunities;

  @override
  void initState() {
    super.initState();

    _opportunities = _service.getOpportunities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Opportunities'),
      ),
      body: FutureBuilder<List<Opportunity>>(
        future: _opportunities,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
              ),
            );
          }

          final opportunities = snapshot.data ?? [];

          if (opportunities.isEmpty) {
            return const Center(
              child: Text('No opportunities found'),
            );
          }

          return ListView.builder(
            itemCount: opportunities.length,
            itemBuilder: (context, index) {
              final opportunity = opportunities[index];

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  title: Text(
                    opportunity.title,
                  ),
                  subtitle: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      if (opportunity.company != null)
                        Text(opportunity.company!),

                      if (opportunity.location != null)
                        Text(opportunity.location!),
                    ],
                  ),
                  trailing: opportunity.source != null
                      ? Text(opportunity.source!)
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
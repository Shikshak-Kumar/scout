import 'package:flutter/material.dart';
import '../../opportunities/presentation/opportunity.dart';
import '../../home/presentation/home_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Internship',
    'Fellowship',
    'Open Source',
    'Hackathon',
  ];

  final List<Opportunity> _hardcodedOpportunities = [
    Opportunity(
      id: 'disc_1',
      title: 'Google Summer of Code 2026 Developer',
      organization: 'Google',
      category: 'Open Source',
      description:
          'Spend your summer contributing to open source software projects. Guided by mentors from open source organizations.',
      sourceUrl: 'https://summerofcode.withgoogle.com',
      applicationUrl: 'https://summerofcode.withgoogle.com',
      verification: 'verified',
      firstSeen: DateTime.now().subtract(const Duration(hours: 4)),
      lastSeen: DateTime.now(),
      qualityScore: 9.8,
      location: 'Global',
      deadlineText: 'Deadline: March 24, 2026',
      remote: true,
    ),
    Opportunity(
      id: 'disc_2',
      title: 'MLH Fellowship (Software Engineering)',
      organization: 'Major League Hacking',
      category: 'Fellowship',
      description:
          'A remote, 12-week internship alternative for aspiring software engineers. Collaborate on open source projects with expert guidance.',
      sourceUrl: 'https://fellowship.mlh.io',
      applicationUrl: 'https://fellowship.mlh.io',
      verification: 'verified',
      firstSeen: DateTime.now().subtract(const Duration(days: 1)),
      lastSeen: DateTime.now(),
      qualityScore: 9.5,
      location: 'Remote (Global)',
      deadlineText: 'Rolling applications',
      remote: true,
    ),
    Opportunity(
      id: 'disc_3',
      title: 'Autonomous Systems Intern',
      organization: 'SpaceX',
      category: 'Internship',
      description:
          'Develop flight software for Starship and Falcon rockets. Build reliable automation tools and real-time guidance algorithms.',
      sourceUrl: 'https://spacex.com/careers',
      applicationUrl: 'https://spacex.com/careers',
      verification: 'community_reported',
      firstSeen: DateTime.now().subtract(const Duration(days: 2)),
      lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
      qualityScore: 8.9,
      location: 'Hawthorne, CA',
      deadlineText: 'Deadline: September 15, 2026',
      remote: false,
    ),
    Opportunity(
      id: 'disc_4',
      title: 'Outreachy Cohort Developer',
      organization: 'Outreachy',
      category: 'Open Source',
      description:
          'Outreachy provides internships in open source and free software for people typically underrepresented in tech.',
      sourceUrl: 'https://outreachy.org',
      applicationUrl: 'https://outreachy.org',
      verification: 'verified',
      firstSeen: DateTime.now().subtract(const Duration(days: 5)),
      lastSeen: DateTime.now().subtract(const Duration(days: 1)),
      qualityScore: 9.2,
      location: 'Remote',
      deadlineText: 'Deadline: October 20, 2026',
      remote: true,
    ),
    Opportunity(
      id: 'disc_5',
      title: 'GitHub Externship 2026',
      organization: 'GitHub',
      category: 'Open Source',
      description:
          'Collaborate with industry leaders, build open source packages, and receive a handsome stipend while building your tech career.',
      sourceUrl: 'https://github.com',
      applicationUrl: 'https://github.com',
      verification: 'verified',
      firstSeen: DateTime.now().subtract(const Duration(hours: 12)),
      lastSeen: DateTime.now(),
      qualityScore: 9.6,
      location: 'India (Remote)',
      deadlineText: 'Deadline: September 05, 2026',
      remote: true,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Opportunity> get _filteredOpportunities {
    return _hardcodedOpportunities.where((opp) {
      final matchesCategory =
          _selectedCategory == 'All' ||
          opp.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch =
          opp.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          opp.organization.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          opp.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredOpportunities;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Discover',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Search & Filters Box
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search title, organization, or tech...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = cat;
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Explore Matches (${filtered.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Opportunity Cards
          if (filtered.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, size: 54, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No opportunities found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Try adjusting your search filters or check back later.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList.separated(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  return OpportunityCard(item: filtered[index]);
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
              ),
            ),
        ],
      ),
    );
  }
}

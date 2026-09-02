import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../opportunities/opportunity_providers.dart';
import '../../opportunities/presentation/opportunity_card.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Internship',
    'Fellowship',
    'Open Source',
    'Hackathon',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _searchController.text = ref.read(discoverSearchQueryProvider);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchQuery = ref.watch(discoverSearchQueryProvider);
    final selectedCategory = ref.watch(discoverCategoryProvider);
    final feedAsync = ref.watch(discoverFeedProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Discover',
          style: theme.textTheme.displayMedium?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
          ),
        ),
      ),
      body: Stack(
        children: [
          // 1. Top Soft Gradient Wash
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFDE7F3), // Soft pink
                    Color(0xFFFEF9E7), // Soft yellow
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          // 2. Main Scrollable Content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Search & Filters Box
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              ref.read(discoverSearchQueryProvider.notifier).state = val;
                            },
                            decoration: InputDecoration(
                              hintText: 'Search title, organization, or tech...',
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF75747C)),
                              suffixIcon: searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: Color(0xFF75747C)),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref.read(discoverSearchQueryProvider.notifier).state = '';
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _categories.map((cat) {
                              final isSelected = selectedCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(cat),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    ref.read(discoverCategoryProvider.notifier).state = cat;
                                  },
                                  labelStyle: TextStyle(
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                    color: isSelected ? const Color(0xFF1E1E24) : const Color(0xFF75747C),
                                  ),
                                  backgroundColor: Colors.white,
                                  selectedColor: const Color(0xFFFFF099), // Soft yellow pill
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                    side: BorderSide(
                                      color: isSelected ? const Color(0xFFFFF099) : const Color(0xFFEAE7E2),
                                      width: 1,
                                    ),
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

                // Explore Title
                feedAsync.when(
                  data: (items) => SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(
                        'Explore Matches (${items.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  error: (e, s) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                  loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                ),

                // Opportunity Cards Feed
                feedAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off_rounded, size: 54, color: Color(0xFF75747C)),
                                SizedBox(height: 16),
                                Text(
                                  'No opportunities found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Try adjusting your search filters or check back later.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF75747C)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      sliver: SliverList.separated(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return OpportunityCard(item: items[index]);
                        },
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                      ),
                    );
                  },
                  loading: () => SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList.builder(
                      itemCount: 4,
                      itemBuilder: (context, index) => Container(
                        height: 150,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: const Color(0xFFEAE7E2)),
                        ),
                      ),
                    ),
                  ),
                  error: (e, s) => SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 54, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text(
                              'Failed to load opportunities',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(e.toString(), textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => ref.invalidate(discoverFeedProvider),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

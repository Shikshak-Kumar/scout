import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api.dart';
import '../../opportunities/presentation/opportunity.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final savedAsync = ref.watch(savedFeedProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Saved',
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
          
          // 2. Main content
          SafeArea(
            child: savedAsync.when(
              data: (savedItems) {
                if (savedItems.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bookmark_outline_rounded, size: 54, color: Color(0xFF75747C)),
                          SizedBox(height: 16),
                          Text(
                            'No saved opportunities yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap the bookmark icon on any opportunity card to save it for quick access.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF75747C)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                        child: Text(
                          'Your Bookmarked Opportunities (${savedItems.length})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF75747C),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      sliver: SliverList.separated(
                        itemCount: savedItems.length,
                        itemBuilder: (context, index) {
                          final savedObj = savedItems[index];
                          final item = Opportunity.fromJson(savedObj['opportunity']);

                          return OpportunityCard(item: item);
                        },
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                      ),
                    ),
                  ],
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(color: theme.colorScheme.primary),
              ),
              error: (e, s) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 54, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load saved opportunities',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(e.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref.invalidate(savedFeedProvider),
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
    );
  }
}

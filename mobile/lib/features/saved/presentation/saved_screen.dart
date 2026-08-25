import 'package:flutter/material.dart';
import '../../opportunities/presentation/opportunity.dart';
import '../../home/presentation/home_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  // Hardcoded saved opportunities list
  final List<Opportunity> _savedOpportunities = [
    Opportunity(
      id: 'saved_1',
      title: 'Meta Production Engineer Intern',
      organization: 'Meta',
      category: 'Internship',
      description: 'Production engineering combines software engineering with systems engineering to build services that scale to billions.',
      sourceUrl: 'https://meta.com/careers',
      applicationUrl: 'https://meta.com/careers',
      verification: 'verified',
      firstSeen: DateTime.now().subtract(const Duration(days: 4)),
      lastSeen: DateTime.now(),
      qualityScore: 9.7,
      location: 'Menlo Park, CA',
      deadlineText: 'Deadline: Oct 15, 2026',
      remote: false,
    ),
    Opportunity(
      id: 'saved_2',
      title: 'Research Intern (Deep Learning)',
      organization: 'Microsoft Research',
      category: 'Fellowship',
      description: 'Collaborate with researchers to solve hard problems in generative AI, large language models, and neural architecture search.',
      sourceUrl: 'https://microsoft.com/research',
      applicationUrl: 'https://microsoft.com/research',
      verification: 'verified',
      firstSeen: DateTime.now().subtract(const Duration(days: 3)),
      lastSeen: DateTime.now(),
      qualityScore: 9.6,
      location: 'Redmond, WA',
      deadlineText: 'Deadline: Dec 01, 2026',
      remote: false,
    ),
    Opportunity(
      id: 'saved_3',
      title: 'Linux Foundation Kernel Mentorship',
      organization: 'Linux Foundation',
      category: 'Open Source',
      description: 'Work directly on the Linux kernel with veteran developers. Receive hands-on mentoring and a fellowship stipend.',
      sourceUrl: 'https://linuxfoundation.org',
      applicationUrl: 'https://linuxfoundation.org',
      verification: 'verified',
      firstSeen: DateTime.now().subtract(const Duration(days: 8)),
      lastSeen: DateTime.now().subtract(const Duration(days: 1)),
      qualityScore: 9.4,
      location: 'Remote',
      deadlineText: 'Deadline: Sep 10, 2026',
      remote: true,
    ),
  ];

  void _removeSaved(int index) {
    setState(() {
      _savedOpportunities.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _savedOpportunities.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bookmark_outline, size: 54, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No saved opportunities yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap the bookmark icon on any opportunity card to save it for quick access.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                    child: Text(
                      'Your Bookmarked Opportunities (${_savedOpportunities.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList.separated(
                    itemCount: _savedOpportunities.length,
                    itemBuilder: (context, index) {
                      final item = _savedOpportunities[index];
                      // Custom card wrapping to show remove interaction or customized style
                      return Stack(
                        children: [
                          OpportunityCard(item: item),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: IconButton(
                              icon: const Icon(Icons.bookmark, color: Colors.blueAccent),
                              onPressed: () {
                                _removeSaved(index);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${item.title} unsaved'),
                                    duration: const Duration(seconds: 2),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () {
                                        setState(() {
                                          _savedOpportunities.insert(index, item);
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                              tooltip: 'Unsave',
                            ),
                          ),
                        ],
                      );
                    },
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                  ),
                ),
              ],
            ),
    );
  }
}

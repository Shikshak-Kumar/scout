import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api.dart';
import '../../home/presentation/home_screen.dart';

class Opportunity {
  final String id,
      title,
      organization,
      category,
      description,
      sourceUrl,
      verification;
  final String? applicationUrl, location, deadlineText;
  final DateTime firstSeen, lastSeen;
  final double qualityScore;
  final bool? remote;
  const Opportunity({
    required this.id,
    required this.title,
    required this.organization,
    required this.category,
    required this.description,
    required this.sourceUrl,
    required this.verification,
    required this.firstSeen,
    required this.lastSeen,
    required this.qualityScore,
    this.applicationUrl,
    this.location,
    this.deadlineText,
    this.remote,
  });
  factory Opportunity.fromJson(Map<String, dynamic> j) => Opportunity(
    id: j['id'],
    title: j['title'],
    organization: j['organization'],
    category: j['category'],
    description: j['description'],
    sourceUrl: j['source_url'],
    verification: j['verification'],
    firstSeen: DateTime.parse(j['first_seen_at']),
    lastSeen: DateTime.parse(j['last_seen_at']),
    qualityScore: (j['quality_score'] as num).toDouble(),
    applicationUrl: j['application_url'],
    location: j['location'],
    deadlineText: j['deadline_text'],
    remote: j['remote'],
  );
}

class OpportunityCard extends ConsumerWidget {
  final Opportunity item;
  const OpportunityCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isNew = DateTime.now().difference(item.firstSeen).inHours < 24;

    // Check if currently bookmarked
    final savedAsync = ref.watch(savedFeedProvider);
    final isBookmarked = savedAsync.asData?.value.any((e) => e['opportunity_id'] == item.id) ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Card(
        // Override default card background / border to keep clean
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Color(0xFFEAE7E2), width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => ShellScope.openOpportunity(context, item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Tag Chips Row
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (isNew)
                            _buildPillChip(
                              label: 'NEW',
                              bgColor: const Color(0xFFFDE7F3),
                              textColor: const Color(0xFFD06B9A),
                            ),
                          if (item.remote == true)
                            _buildPillChip(
                              label: 'REMOTE',
                              bgColor: const Color(0xFFE0F4F7),
                              textColor: const Color(0xFF1B6A78),
                            ),
                          _buildPillChip(
                            label: item.verification.replaceAll('_', ' ').toUpperCase(),
                            bgColor: item.verification == 'verified'
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFF9C4),
                            textColor: item.verification == 'verified'
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFE65100),
                          ),
                        ],
                      ),
                    ),
                    // Bookmark icon aligned top right
                    IconButton(
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: isBookmarked ? const Color(0xFFE08BB4) : const Color(0xFF75747C),
                      ),
                      onPressed: () async {
                        final service = ref.read(opportunityServiceProvider);
                        if (isBookmarked) {
                          await service.saveOpportunity(
                            opportunityId: item.id,
                            status: 'not_interested',
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Unsaved opportunity')),
                            );
                          }
                        } else {
                          await service.saveOpportunity(
                            opportunityId: item.id,
                            status: 'saved',
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Saved to bookmarks')),
                            );
                          }
                        }
                      },
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // 2. Bold Title
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                    letterSpacing: -0.4,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),

                // 3. Company Name in Accent Color
                Text(
                  item.organization,
                  style: TextStyle(
                    color: const Color(0xFFE08BB4),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Divider Line
                Container(
                  height: 1,
                  color: const Color(0xFFF0EDE8),
                ),
                const SizedBox(height: 14),

                // 5. Deadline and Details footer
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      size: 16,
                      color: Color(0xFF75747C),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.deadlineText ?? 'Deadline not specified',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF75747C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF75747C),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillChip({
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

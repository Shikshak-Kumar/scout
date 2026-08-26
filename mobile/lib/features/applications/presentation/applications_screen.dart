import 'package:flutter/material.dart';

class ApplicationItem {
  final String id;
  final String title;
  final String organization;
  final String
  status; // 'Draft' | 'Applied' | 'Interviewing' | 'Offer' | 'Rejected'
  final String appliedDate;
  final String nextAction;
  final double progress; // 0.0 to 1.0

  const ApplicationItem({
    required this.id,
    required this.title,
    required this.organization,
    required this.status,
    required this.appliedDate,
    required this.nextAction,
    required this.progress,
  });
}

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  final List<ApplicationItem> _applications = [
    const ApplicationItem(
      id: 'app_1',
      title: 'Frontend Engineering Intern',
      organization: 'Stripe',
      status: 'Interviewing',
      appliedDate: 'Applied: Aug 10, 2026',
      nextAction: 'Technical Interview on Aug 30, 2026',
      progress: 0.6,
    ),
    const ApplicationItem(
      id: 'app_2',
      title: 'Google STEP Intern',
      organization: 'Google',
      status: 'Applied',
      appliedDate: 'Applied: Aug 15, 2026',
      nextAction: 'Resume currently under review',
      progress: 0.3,
    ),
    const ApplicationItem(
      id: 'app_3',
      title: 'GitHub Octernship Program',
      organization: 'GitHub',
      status: 'Draft',
      appliedDate: 'Last modified: Aug 24, 2026',
      nextAction: 'Complete project proposal task',
      progress: 0.1,
    ),
    const ApplicationItem(
      id: 'app_4',
      title: 'Next.js Framework Engineer Intern',
      organization: 'Vercel',
      status: 'Offer',
      appliedDate: 'Applied: Jul 20, 2026',
      nextAction: 'Review offer package by Sep 01, 2026',
      progress: 1.0,
    ),
  ];

  Color _getStatusColor(String status, ColorScheme colors) {
    switch (status) {
      case 'Offer':
        return Colors.green;
      case 'Interviewing':
        return Colors.orange;
      case 'Applied':
        return colors.primary;
      case 'Draft':
        return Colors.grey;
      case 'Rejected':
        return Colors.red;
      default:
        return colors.primary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Offer':
        return Icons.emoji_events_outlined;
      case 'Interviewing':
        return Icons.forum_outlined;
      case 'Applied':
        return Icons.send_outlined;
      case 'Draft':
        return Icons.edit_note_outlined;
      case 'Rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.work_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Applications',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Add new application',
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Manual tracking is coming soon!'),
                ),
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Application Statistics Card
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Total',
                    _applications.length.toString(),
                    colors.onPrimaryContainer,
                  ),
                  _buildStatDivider(
                    colors.onPrimaryContainer.withValues(alpha: 0.2),
                  ),
                  _buildStatItem(
                    'Interviewing',
                    _applications
                        .where((e) => e.status == 'Interviewing')
                        .length
                        .toString(),
                    Colors.orange,
                  ),
                  _buildStatDivider(
                    colors.onPrimaryContainer.withValues(alpha: 0.2),
                  ),
                  _buildStatItem(
                    'Offers',
                    _applications
                        .where((e) => e.status == 'Offer')
                        .length
                        .toString(),
                    Colors.green,
                  ),
                ],
              ),
            ),
          ),

          // List header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Text(
                'Tracked Applications',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Application list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: _applications.length,
              itemBuilder: (context, index) {
                final app = _applications[index];
                final statusColor = _getStatusColor(app.status, colors);
                final statusIcon = _getStatusIcon(app.status);

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              app.organization.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: colors.primary,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    statusIcon,
                                    size: 14,
                                    color: statusColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    app.status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          app.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: app.progress,
                          backgroundColor: colors.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                          color: statusColor,
                          borderRadius: BorderRadius.circular(4),
                          minHeight: 6,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              app.appliedDate,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.bolt,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                app.nextAction,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 12),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color textColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider(Color color) {
    return Container(height: 30, width: 1, color: color);
  }
}

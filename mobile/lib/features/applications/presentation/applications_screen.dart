import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api.dart';
import '../../opportunities/presentation/opportunity.dart';

class ApplicationsScreen extends ConsumerWidget {
  const ApplicationsScreen({super.key});

  Color _getStatusColor(String status, ColorScheme colors) {
    switch (status) {
      case 'accepted': // Offer
        return Colors.green;
      case 'interview': // Interviewing
        return Colors.orange;
      case 'applying':
      case 'applied': // Applied
        return colors.primary;
      case 'planning': // Draft
        return Colors.grey;
      case 'rejected': // Rejected
        return Colors.red;
      default:
        return colors.primary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.emoji_events_outlined;
      case 'interview':
        return Icons.forum_outlined;
      case 'applying':
      case 'applied':
        return Icons.send_outlined;
      case 'planning':
        return Icons.edit_note_outlined;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.work_outline;
    }
  }

  String _displayStatus(String status) {
    switch (status) {
      case 'planning':
        return 'Draft';
      case 'applying':
      case 'applied':
        return 'Applied';
      case 'interview':
        return 'Interviewing';
      case 'accepted':
        return 'Offer';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Applied';
    }
  }

  double _getStatusProgress(String status) {
    switch (status) {
      case 'planning':
        return 0.1;
      case 'applying':
      case 'applied':
        return 0.4;
      case 'interview':
        return 0.7;
      case 'accepted':
      case 'rejected':
        return 1.0;
      default:
        return 0.4;
    }
  }

  String _getNextAction(String status, String? userNotes) {
    if (userNotes != null && userNotes.trim().isNotEmpty) {
      return userNotes;
    }
    switch (status) {
      case 'planning':
        return 'Complete project proposal task';
      case 'applying':
      case 'applied':
        return 'Resume currently under review';
      case 'interview':
        return 'Prepare for next round interview';
      case 'accepted':
        return 'Congratulations! Review offer details';
      case 'rejected':
        return 'Keep applying and stay positive!';
      default:
        return 'Check application updates';
    }
  }

  void _showStatusUpdateDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> appObj) {
    final item = Opportunity.fromJson(appObj['opportunity']);
    final currentStatus = appObj['status'];
    final notesController = TextEditingController(text: appObj['notes'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24, 24, 24,
          MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Update Application',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${item.title} at ${item.organization}',
              style: const TextStyle(color: Color(0xFF75747C), fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: currentStatus,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(value: 'planning', child: Text('Draft')),
                DropdownMenuItem(value: 'applied', child: Text('Applied')),
                DropdownMenuItem(value: 'interview', child: Text('Interviewing')),
                DropdownMenuItem(value: 'accepted', child: Text('Offer')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
              ],
              onChanged: (val) {
                // Handled in local state if needed, or simple submit below
              },
              key: const Key('status_dropdown'),
            ),
            const SizedBox(height: 20),
            const Text('Next Action / Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                hintText: 'Enter next steps, interview dates, or tasks...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E1E24),
                      side: const BorderSide(color: Color(0xFFEAE7E2)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF5B5D0),
                      foregroundColor: const Color(0xFF1E1E24),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final service = ref.read(opportunityServiceProvider);
                      Navigator.pop(context);
                      await service.saveOpportunity(
                        opportunityId: item.id,
                        status: currentStatus, // Simpler update using notes
                        notes: notesController.text,
                      );
                    },
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final appsAsync = ref.watch(applicationsFeedProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Applications',
          style: theme.textTheme.displayMedium?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add new application',
            icon: const Icon(Icons.add, color: Color(0xFF1E1E24)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search and bookmark opportunities to track them!')),
              );
            },
          ),
        ],
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
          
          // 2. Content
          SafeArea(
            child: appsAsync.when(
              data: (applications) {
                final totalCount = applications.length;
                final interviewingCount = applications.where((e) => e['status'] == 'interview').length;
                final offerCount = applications.where((e) => e['status'] == 'accepted').length;

                return CustomScrollView(
                  slivers: [
                    // Statistics Card Container
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: const Color(0xFFEAE7E2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('Total', totalCount.toString(), const Color(0xFF1E1E24)),
                            _buildStatDivider(const Color(0xFFEAE7E2)),
                            _buildStatItem('Interviewing', interviewingCount.toString(), Colors.orange),
                            _buildStatDivider(const Color(0xFFEAE7E2)),
                            _buildStatItem('Offers', offerCount.toString(), Colors.green),
                          ],
                        ),
                      ),
                    ),

                    // Title
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                        child: Text(
                          'Tracked Applications',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),

                    // List
                    if (applications.isEmpty)
                      const SliverFillRemaining(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.work_outline_rounded, size: 54, color: Color(0xFF75747C)),
                                SizedBox(height: 16),
                                Text(
                                  'No active applications',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Add items from the Discover page and update their status to start tracking.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF75747C)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        sliver: SliverList.separated(
                          itemCount: applications.length,
                          itemBuilder: (context, index) {
                            final appObj = applications[index];
                            final item = Opportunity.fromJson(appObj['opportunity']);
                            final status = appObj['status'];
                            final statusColor = _getStatusColor(status, colors);
                            final statusIcon = _getStatusIcon(status);

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Card(
                                color: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                  side: const BorderSide(color: Color(0xFFEAE7E2), width: 1),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(28),
                                  onTap: () => _showStatusUpdateDialog(context, ref, appObj),
                                  child: Padding(
                                    padding: const EdgeInsets.all(22),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              item.organization.toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFFE08BB4),
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusColor.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(50),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(statusIcon, size: 13, color: statusColor),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _displayStatus(status),
                                                    style: TextStyle(
                                                      color: statusColor,
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          item.title,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 18,
                                            letterSpacing: -0.4,
                                            height: 1.25,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(50),
                                          child: LinearProgressIndicator(
                                            value: _getStatusProgress(status),
                                            backgroundColor: const Color(0xFFEAE7E2),
                                            color: statusColor,
                                            minHeight: 6,
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF75747C)),
                                            const SizedBox(width: 6),
                                            Text(
                                              appObj['application_date'] != null
                                                  ? 'Applied: ${DateTime.parse(appObj['application_date']).toLocal().toString().substring(0, 10)}'
                                                  : 'Last updated: ${DateTime.parse(appObj['updated_at']).toLocal().toString().substring(0, 10)}',
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF75747C), fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.bolt, size: 16, color: Colors.amber),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                _getNextAction(status, appObj['notes']),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF1E1E24),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
                        'Failed to load applications',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(e.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref.invalidate(applicationsFeedProvider),
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

  Widget _buildStatItem(String label, String value, Color textColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF75747C),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider(Color color) {
    return Container(
      height: 32,
      width: 1,
      color: color,
    );
  }
}

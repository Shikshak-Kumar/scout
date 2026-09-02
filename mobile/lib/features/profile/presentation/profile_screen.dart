import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../opportunities/opportunity_providers.dart';
import '../profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  void _addSkill(String skill, Map<String, dynamic> currentProfileData) {
    final currentSkills = List<String>.from(
      currentProfileData['skills'] ?? ['Flutter', 'Dart', 'Python', 'Git'],
    );
    if (skill.trim().isNotEmpty && !currentSkills.contains(skill.trim())) {
      final newSkills = [...currentSkills, skill.trim()];
      ref.read(profileProvider.notifier).updateProfile({
        ...currentProfileData,
        'skills': newSkills,
      });
    }
  }

  void _removeSkill(String skill, Map<String, dynamic> currentProfileData) {
    final currentSkills = List<String>.from(currentProfileData['skills'] ?? []);
    if (currentSkills.contains(skill)) {
      final newSkills = currentSkills.where((e) => e != skill).toList();
      ref.read(profileProvider.notifier).updateProfile({
        ...currentProfileData,
        'skills': newSkills,
      });
    }
  }

  void _showAddSkillDialog(Map<String, dynamic> currentProfileData) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text(
          'Add Skill',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter skill (e.g., Go, React, Kubernetes)',
            filled: true,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF5B5D0),
              foregroundColor: const Color(0xFF1E1E24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              elevation: 0,
            ),
            onPressed: () {
              _addSkill(controller.text, currentProfileData);
              Navigator.pop(context);
            },
            child: const Text(
              'Add',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final profileAsync = ref.watch(profileProvider);
    final savedAsync = ref.watch(savedFeedProvider);
    final appsAsync = ref.watch(applicationsFeedProvider);

    final savedCount = savedAsync.asData?.value.length ?? 0;
    final appliedCount = appsAsync.asData?.value.length ?? 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile',
          style: theme.textTheme.displayMedium?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF1E1E24)),
            onPressed: () {},
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

          // 2. Content list
          SafeArea(
            child: profileAsync.when(
              data: (profileData) {
                final email = profileData['email'] ?? 'user@example.com';
                final profileDetails = Map<String, dynamic>.from(
                  profileData['profile'] ?? {},
                );

                final skills = List<String>.from(
                  profileDetails['skills'] ??
                      ['Flutter', 'Dart', 'Python', 'Git', 'Open Source'],
                );
                final emailAlerts = profileDetails['email_alerts'] ?? true;
                final pushNotifications =
                    profileDetails['push_notifications'] ?? false;
                final weeklyDigest = profileDetails['weekly_digest'] ?? true;
                final resumeName =
                    profileDetails['resume_name'] ?? 'alex_resume_2026.pdf';

                final initials = email.length >= 2
                    ? email.substring(0, 2).toUpperCase()
                    : 'US';

                return ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  children: [
                    // Header: Avatar & Main Info
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFDE7F3), Color(0xFFFFF099)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.primary.withValues(alpha: 0.1),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Color(0xFF1E1E24),
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Developer Profile',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF75747C),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Applied',
                            appliedCount.toString(),
                            Icons.send_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Saved',
                            savedCount.toString(),
                            Icons.bookmark_border,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Skills',
                            skills.length.toString(),
                            Icons.bolt_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Resume
                    _buildSectionHeader('Resume & Portfolio'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.picture_as_pdf,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    resumeName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Sync active via profile settings',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF75747C),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.sync_outlined,
                                color: Color(0xFF75747C),
                              ),
                              tooltip: 'Update Resume',
                              onPressed: () {
                                ref.read(profileProvider.notifier).updateProfile({
                                  ...profileDetails,
                                  'resume_name':
                                      'resume_updated_${DateTime.now().millisecondsSinceEpoch ~/ 1000}.pdf',
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Resume meta updated successfully!',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Skills Chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader('My Interests & Skills'),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            size: 20,
                            color: Color(0xFF75747C),
                          ),
                          onPressed: () => _showAddSkillDialog(profileDetails),
                          tooltip: 'Add skill',
                        ),
                      ],
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: skills.map((skill) {
                            return InputChip(
                              label: Text(skill),
                              onDeleted: () =>
                                  _removeSkill(skill, profileDetails),
                              backgroundColor: const Color(0xFFF7F5F2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                                side: const BorderSide(
                                  color: Color(0xFFEAE7E2),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Preferences
                    _buildSectionHeader('Radar Preferences'),
                    Card(
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text(
                              'Email Alerts',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: const Text(
                              'Receive matches immediately in your inbox',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: emailAlerts,
                            onChanged: (val) {
                              ref.read(profileProvider.notifier).updateProfile({
                                ...profileDetails,
                                'email_alerts': val,
                              });
                            },
                          ),
                          const Divider(height: 1, color: Color(0xFFEAE7E2)),
                          SwitchListTile(
                            title: const Text(
                              'Push Notifications',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: const Text(
                              'Instant alerts for high-priority matches',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: pushNotifications,
                            onChanged: (val) {
                              ref.read(profileProvider.notifier).updateProfile({
                                ...profileDetails,
                                'push_notifications': val,
                              });
                            },
                          ),
                          const Divider(height: 1, color: Color(0xFFEAE7E2)),
                          SwitchListTile(
                            title: const Text(
                              'Weekly Digest',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: const Text(
                              'A summary of top engineering matches',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: weeklyDigest,
                            onChanged: (val) {
                              ref.read(profileProvider.notifier).updateProfile({
                                ...profileDetails,
                                'weekly_digest': val,
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Account
                    _buildSectionHeader('Account'),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.help_outline,
                              color: Color(0xFF75747C),
                            ),
                            title: const Text(
                              'Help & Support',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF75747C),
                            ),
                            onTap: () {},
                          ),
                          const Divider(height: 1, color: Color(0xFFEAE7E2)),
                          ListTile(
                            leading: const Icon(
                              Icons.info_outline,
                              color: Color(0xFF75747C),
                            ),
                            title: const Text(
                              'About Scout',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF75747C),
                            ),
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(color: colors.primary),
              ),
              error: (e, s) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 54,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(e.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref.invalidate(profileProvider),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: Color(0xFF75747C),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFFE08BB4), size: 20),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
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
          ),
        ),
      ),
    );
  }
}

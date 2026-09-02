import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, Map<String, dynamic>>(
  ProfileNotifier.new,
);

class ProfileNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    return {
      'email': 'user@example.com',
      'profile': {
        'skills': [
          'Flutter',
          'Dart',
          'Python',
          'Git',
          'Open Source',
        ],
        'email_alerts': true,
        'push_notifications': false,
        'weekly_digest': true,
        'resume_name': 'resume.pdf',
      },
    };
  }

  void updateProfile(Map<String, dynamic> profileData) {
    state = AsyncData(profileData);
  }
}
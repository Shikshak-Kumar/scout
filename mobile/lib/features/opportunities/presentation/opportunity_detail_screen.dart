import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../opportunity.dart';

class OpportunityDetailScreen extends StatelessWidget {
  final Opportunity item;
  const OpportunityDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: theme.colorScheme.onSurface,
        ),
      ),
      body: Stack(
        children: [
          // Top wash
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 250,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFDE7F3), Color(0xFFFEF9E7), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.organization,
                  style: const TextStyle(
                    color: Color(0xFFE08BB4),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                if (item.location != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: Color(0xFF75747C)),
                      const SizedBox(width: 4),
                      Text(
                        item.location!,
                        style: const TextStyle(
                            color: Color(0xFF75747C), fontSize: 14),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                if (item.description != null &&
                    item.description!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFEAE7E2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About this Opportunity',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.verified_outlined,
                        color: Color(0xFF2E7D32)),
                  ),
                  title: Text(
                    item.verification
                        .replaceAll('_', ' ')
                        .toUpperCase(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Text(
                      'Last updated ${item.lastSeen.toLocal().toString().substring(0, 10)}'),
                ),
                const SizedBox(height: 32),
                if (item.applicationUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF5B5D0),
                        foregroundColor: const Color(0xFF1E1E24),
                        padding:
                            const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final Uri url =
                            Uri.parse(item.applicationUrl!);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.open_in_new_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Apply on official site',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                if (item.sourceUrl.isNotEmpty)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E1E24),
                      side:
                          const BorderSide(color: Color(0xFFEAE7E2)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    onPressed: () async {
                      final Uri url = Uri.parse(item.sourceUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.link, size: 18),
                        SizedBox(width: 8),
                        Text('View source link',
                            style:
                                TextStyle(fontWeight: FontWeight.bold)),
                      ],
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

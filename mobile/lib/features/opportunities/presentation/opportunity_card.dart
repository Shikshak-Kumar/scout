import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../opportunity.dart';
import 'opportunity_detail_screen.dart';

/// A premium card widget displaying a single [Opportunity].
class OpportunityCard extends StatelessWidget {
  final Opportunity item;
  const OpportunityCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OpportunityDetailScreen(item: item)),
      ),
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Organization label
              Text(
                item.organization.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE08BB4),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              // Title
              Text(
                item.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  letterSpacing: -0.3,
                  height: 1.25,
                ),
              ),
              if (item.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: Color(0xFF75747C)),
                    const SizedBox(width: 4),
                    Text(
                      item.location!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF75747C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              if (item.description != null && item.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  item.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF75747C),
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  if (item.source != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3F0),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        item.source!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF75747C),
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (item.applicationUrl != null)
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri.parse(item.applicationUrl!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5B5D0),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Text(
                          'Apply',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E1E24),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

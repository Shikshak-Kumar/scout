import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api.dart';
import '../../opportunities/presentation/opportunity.dart';

final feedProvider = FutureProvider.autoDispose<List<Opportunity>>((ref) async {
  final response = await ref.watch(dioProvider).get('/opportunities');
  return (response.data['items'] as List)
      .map((e) => Opportunity.fromJson(e))
      .toList();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scout', style: TextStyle(fontWeight: FontWeight.w800)),
            Text(
              'Your opportunity radar',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(feedProvider.future),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              sliver: SliverToBoxAdapter(
                child: SearchBar(
                  hintText: 'Search opportunities',
                  leading: const Icon(Icons.search),
                  onTap: () => ShellScope.goDiscover(context),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _DailyScout()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                child: Text(
                  'New for you',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            feed.when(
              data: (items) => items.isEmpty
                  ? const SliverFillRemaining(child: _Empty())
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList.separated(
                        itemCount: items.length,
                        itemBuilder: (c, i) => OpportunityCard(item: items[i]),
                        separatorBuilder: (c, i) => const SizedBox(height: 12),
                      ),
                    ),
              loading: () => SliverList.builder(
                itemCount: 5,
                itemBuilder: (c, i) => const _Skeleton(),
              ),
              error: (e, s) => SliverFillRemaining(
                child: Center(
                  child: FilledButton.icon(
                    onPressed: () => ref.invalidate(feedProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyScout extends StatelessWidget {
  const _DailyScout();
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF3155E7), Color(0xFF7047EB)],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.radar, color: Colors.white),
        SizedBox(height: 20),
        Text(
          'Daily Scout',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Fresh matches appear here as monitored sources update.',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    ),
  );
}

class OpportunityCard extends StatelessWidget {
  final Opportunity item;
  const OpportunityCard({super.key, required this.item});
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => ShellScope.openOpportunity(context, item),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              children: [
                if (DateTime.now().difference(item.firstSeen).inHours < 24)
                  const Chip(label: Text('NEW')),
                if (item.remote == true) const Chip(label: Text('REMOTE')),
                Chip(
                  label: Text(
                    item.verification.replaceAll('_', ' ').toUpperCase(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              item.organization,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.schedule, size: 17),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(item.deadlineText ?? 'Deadline not specified'),
                ),
                IconButton(
                  tooltip: 'Save',
                  onPressed: () {},
                  icon: const Icon(Icons.bookmark_border),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.radar, size: 54),
          SizedBox(height: 16),
          Text(
            'No matches yet',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Scout will show opportunities here as connected sources discover relevant records.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) => Container(
    height: 180,
    margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
    ),
  );
}

abstract final class ShellScope {
  static void goDiscover(BuildContext context) {
    context.go('/discover');
  }

  static void openOpportunity(BuildContext context, Opportunity item) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => OpportunityDetail(item: item)));
  }
}

class OpportunityDetail extends StatelessWidget {
  final Opportunity item;
  const OpportunityDetail({super.key, required this.item});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Opportunity')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          item.title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(item.organization, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 22),
        Text(item.description),
        const SizedBox(height: 24),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.verified_outlined),
          title: Text(item.verification.replaceAll('_', ' ')),
          subtitle: Text('Source checked ${item.lastSeen.toLocal()}'),
        ),
        if (item.applicationUrl != null)
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.open_in_new),
            label: const Text('Apply on official site'),
          ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.link),
          label: const Text('View source'),
        ),
      ],
    ),
  );
}

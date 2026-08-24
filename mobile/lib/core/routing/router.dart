import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/home_screen.dart';

final router = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) => _Shell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/discover',
          builder: (context, state) => const _Page(
            title: 'Discover',
            icon: Icons.travel_explore,
            description: 'Search real opportunities across connected sources.',
          ),
        ),
        GoRoute(
          path: '/saved',
          builder: (context, state) => const _Page(
            title: 'Saved',
            icon: Icons.bookmark_outline,
            description: 'Your saved opportunities will appear here.',
          ),
        ),
        GoRoute(
          path: '/applications',
          builder: (context, state) => const _Page(
            title: 'Applications',
            icon: Icons.work_outline,
            description: 'Track applications and upcoming deadlines.',
          ),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const _Page(
            title: 'Profile',
            icon: Icons.person_outline,
            description:
                'Tune your skills, interests, and notification preferences.',
          ),
        ),
      ],
    ),
  ],
);

class _Shell extends StatelessWidget {
  final Widget child;
  const _Shell({required this.child});
  int _index(BuildContext c) {
    final p = GoRouterState.of(c).uri.path;
    return [
      '/home',
      '/discover',
      '/saved',
      '/applications',
      '/profile',
    ].indexOf(p).clamp(0, 4);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: child,
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index(context),
      onDestinationSelected: (i) => context.go(
        ['/home', '/discover', '/saved', '/applications', '/profile'][i],
      ),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(icon: Icon(Icons.search), label: 'Discover'),
        NavigationDestination(
          icon: Icon(Icons.bookmark_outline),
          selectedIcon: Icon(Icons.bookmark),
          label: 'Saved',
        ),
        NavigationDestination(
          icon: Icon(Icons.work_outline),
          selectedIcon: Icon(Icons.work),
          label: 'Applications',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    ),
  );
}

class _Page extends StatelessWidget {
  final String title, description;
  final IconData icon;
  const _Page({
    required this.title,
    required this.icon,
    required this.description,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 18),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    ),
  );
}

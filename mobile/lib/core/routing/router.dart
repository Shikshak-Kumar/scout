import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/saved/presentation/saved_screen.dart';
import '../../features/applications/presentation/applications_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/opportunities/presentation/opportunities_screen.dart';
import '../auth/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    // Redirect unauthenticated users to /login.
    // Called on every navigation; GoRouter re-runs this when the listenable fires.
    redirect: (context, state) {
      // TEMPORARILY DISABLED: Login Page Bypass
      // final authAsync = ref.read(authStateProvider);

      // // While checking auth, don't redirect yet.
      // if (authAsync.isLoading) return null;

      // final isAuthenticated = authAsync.valueOrNull ?? false;
      // final onLoginPage = state.matchedLocation == '/login';

      // if (!isAuthenticated && !onLoginPage) return '/login';
      // if (isAuthenticated && onLoginPage) return '/home';
      return null;
    },
    // Refresh the router when auth state changes.
    refreshListenable: _AuthNotifierListenable(ref),
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => _Shell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/discover',
            builder: (context, state) => const OpportunitiesScreen(),
          ),
          GoRoute(
            path: '/saved',
            builder: (context, state) => const SavedScreen(),
          ),
          GoRoute(
            path: '/applications',
            builder: (context, state) => const ApplicationsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

/// Bridges Riverpod's [AsyncNotifier] to GoRouter's [Listenable] interface
/// so the router refreshes whenever auth state changes.
class _AuthNotifierListenable extends ChangeNotifier {
  _AuthNotifierListenable(Ref ref) {
    ref.listen<AsyncValue<bool>>(authStateProvider, (prev, next) {
      notifyListeners();
    });
  }
}


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

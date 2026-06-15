import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'src/screens/connection_page.dart';
import 'src/screens/home_page.dart';
import 'src/screens/login_page.dart';
import 'src/screens/product_pages.dart';
import 'src/services/health_sync_service.dart';
import 'src/state/app_state.dart';

void main() {
  runApp(const ProviderScope(child: SummaMoveApp()));
}

class SummaMoveApp extends ConsumerStatefulWidget {
  const SummaMoveApp({super.key});

  @override
  ConsumerState<SummaMoveApp> createState() => _SummaMoveAppState();
}

class _SummaMoveAppState extends ConsumerState<SummaMoveApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final session = ref.read(sessionProvider);
    _router = GoRouter(
      initialLocation: '/splash',
      refreshListenable: session,
      redirect: (context, state) {
        if (!session.initialized) {
          return state.matchedLocation == '/splash' ? null : '/splash';
        }
        if (!session.authenticated) {
          return state.matchedLocation == '/login' ? null : '/login';
        }
        if (state.matchedLocation == '/login' ||
            state.matchedLocation == '/splash') {
          return '/app';
        }
        if (state.matchedLocation.startsWith('/admin') && !session.isAdmin) {
          return '/app';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
        GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
        GoRoute(path: '/app', builder: (_, __) => const MainShell()),
        GoRoute(
            path: '/quick', builder: (_, __) => const QuickChallengesPage()),
        GoRoute(
          path: '/challenge/:id',
          builder: (_, state) =>
              ChallengeDetailPage(id: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(path: '/avatar', builder: (_, __) => const AvatarPage()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
        GoRoute(path: '/menu', builder: (_, __) => const MenuPage()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
        GoRoute(
            path: '/privacy',
            builder: (_, __) => const InfoPage(
                title: 'Privacy',
                body:
                    'SummaMove gebruikt health-data alleen voor jouw beweegdoelen en challenges.')),
        GoRoute(
            path: '/help',
            builder: (_, __) => const InfoPage(
                title: 'Help & Support',
                body:
                    'Controleer je health-permissies en synchroniseer opnieuw. Neem bij vragen contact op met het SummaMove-team.')),
        GoRoute(
          path: '/messages/:id',
          builder: (_, state) =>
              MessagesPage(friendId: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/health-sync',
          builder: (_, __) {
            final api = ref.read(apiClientProvider);
            return ConnectionPage(
              api: api,
              sync: HealthSyncService(
                  api: api, deviceId: 'summamove-demo-device'),
              onAuthenticated: (_) {},
              onLoggedOut: () => ref.read(sessionProvider).logout(),
            );
          },
        ),
        GoRoute(path: '/admin', builder: (_, __) => const AdminPage()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider).mode;
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'SummaMove',
      routerConfig: _router,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F8F8),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE91E63)),
        cardTheme: const CardThemeData(color: Colors.white),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE91E63), brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: themeMode,
    );
  }
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(productRepositoryProvider);
    final pages = [
      HomePage(
        repository: repository,
        userName: ref.watch(sessionProvider).name,
        onOpenMenu: () => context.push('/menu'),
        onOpenChallenges: () => setState(() => index = 1),
        onOpenAvatar: () => context.push('/avatar'),
        onOpenQuick: () => context.push('/quick'),
      ),
      const ChallengesPage(),
      const FriendsPage(),
      const ShopPage(),
      const RankingsPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined), label: 'Challenges'),
          NavigationDestination(
              icon: Icon(Icons.people_outline), label: 'Vrienden'),
          NavigationDestination(
              icon: Icon(Icons.shopping_bag_outlined), label: 'Shop'),
          NavigationDestination(
              icon: Icon(Icons.leaderboard_outlined), label: 'Ranking'),
        ],
      ),
    );
  }
}

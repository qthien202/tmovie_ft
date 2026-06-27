import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import '../features/home/desktop_home_page.dart';
import '../features/detail/desktop_detail_page.dart';
import '../features/search/desktop_search_page.dart';
import '../features/player/desktop_player_page.dart';
import '../features/profile/desktop_profile_page.dart';
import '../features/profile/desktop_history_page.dart';
import '../features/profile/desktop_favorites_page.dart';
import '../shared/widgets/desktop_shell.dart';

final desktopRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) => DesktopShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const DesktopHomePage(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const DesktopSearchPage(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const DesktopHistoryPage(),
        ),
        GoRoute(
          path: '/favorites',
          builder: (context, state) => const DesktopFavoritesPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const DesktopProfilePage(),
        ),
      ],
    ),
    GoRoute(
      path: '/detail/:slug',
      builder: (context, state) => DesktopDetailPage(
        slug: state.pathParameters['slug']!,
      ),
    ),
    GoRoute(
      path: '/player',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return DesktopPlayerPage(
          videoUrl: extra['videoUrl'] as String,
          filmName: extra['filmName'] as String,
          episode: extra['episode'] as String,
          slug: extra['slug'] as String,
          episodes: extra['episodes'] as List<Episode>? ?? [],
        );
      },
    ),
  ],
);

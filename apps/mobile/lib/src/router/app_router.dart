import 'package:go_router/go_router.dart';
import '../features/splash/splash_page.dart';
import '../features/home/home_page.dart';
import '../features/search/search_page.dart';
import '../features/detail/detail_page.dart';
import '../features/player/player_page.dart';
import '../features/film_list/film_list_page.dart';
import '../features/catalog_tabs/catalog_tab_pages.dart';
import '../features/genre/genre_page.dart';
import '../features/profile/profile_page.dart';
import '../features/profile/history_page.dart';
import '../features/profile/favorites_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/auth/login_page.dart';
import '../shell/main_shell.dart';
import 'package:core/core.dart';
import 'route_names.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: RouteNames.splash,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/onboarding',
      name: RouteNames.onboarding,
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/login',
      name: RouteNames.login,
      builder: (context, state) => const LoginPage(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          name: RouteNames.home,
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/phim-bo',
          name: RouteNames.tabSeries,
          builder: (context, state) => const SeriesTabPage(),
        ),
        GoRoute(
          path: '/phim-le',
          name: RouteNames.tabSingle,
          builder: (context, state) => const FilmListPage(
            typeSlug: 'phim-le',
            title: 'Phim lẻ',
            isRootTab: true,
          ),
        ),
        GoRoute(
          path: '/tv-shows',
          name: RouteNames.tabTvShows,
          builder: (context, state) => const TvShowsTabPage(),
        ),
        GoRoute(
          path: '/profile',
          name: RouteNames.profile,
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    ),
    // Search is reached from a top-bar icon (Home), not a bottom tab — each
    // film tab already has its own inline search.
    GoRoute(
      path: '/search',
      name: RouteNames.search,
      builder: (context, state) => const SearchPage(),
    ),
    GoRoute(
      path: '/history',
      name: RouteNames.watchHistory,
      builder: (context, state) => const HistoryPage(),
    ),
    GoRoute(
      path: '/favorites',
      name: RouteNames.favorites,
      builder: (context, state) => const FavoritesPage(),
    ),
    GoRoute(
      path: '/detail/:slug',
      name: RouteNames.detail,
      builder: (context, state) => DetailPage(
        slug: state.pathParameters['slug']!,
        name: state.uri.queryParameters['name'],
      ),
    ),
    GoRoute(
      path: '/player',
      name: RouteNames.player,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return PlayerPage(
          videoUrl: extra['videoUrl'] as String,
          filmName: extra['filmName'] as String,
          episode: extra['episode'] as String,
          slug: extra['slug'] as String,
          episodes: extra['episodes'] as List<Episode>,
        );
      },
    ),
    GoRoute(
      path: '/film-list/:typeSlug',
      name: RouteNames.filmList,
      builder: (context, state) => FilmListPage(
        typeSlug: state.pathParameters['typeSlug']!,
        title: state.uri.queryParameters['title'] ?? '',
      ),
    ),
    GoRoute(
      path: '/genre/:slug',
      name: RouteNames.genre,
      builder: (context, state) => GenrePage(
        slug: state.pathParameters['slug']!,
        title: state.uri.queryParameters['title'] ?? '',
      ),
    ),
  ],
);

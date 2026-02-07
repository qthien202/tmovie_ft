import 'package:go_router/go_router.dart';
import '../features/splash/splash_page.dart';
import '../features/home/home_page.dart';
import '../features/search/search_page.dart';
import '../features/detail/detail_page.dart';
import '../features/player/player_page.dart';
import '../features/film_list/film_list_page.dart';
import '../features/genre/genre_page.dart';
import '../shell/main_shell.dart';
import 'route_names.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: RouteNames.splash,
      builder: (context, state) => const SplashPage(),
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
          path: '/search',
          name: RouteNames.search,
          builder: (context, state) => const SearchPage(),
        ),
      ],
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
        final extra = state.extra as Map<String, String>;
        return PlayerPage(
          videoUrl: extra['videoUrl']!,
          filmName: extra['filmName']!,
          episode: extra['episode']!,
          slug: extra['slug']!,
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

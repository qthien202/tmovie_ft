import 'package:go_router/go_router.dart';
import '../features/home/tv_home_page.dart';
import '../features/detail/tv_detail_page.dart';
import '../features/player/tv_player_page.dart';
import '../features/search/tv_search_page.dart';

final tvRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      builder: (context, state) => const TvHomePage(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const TvSearchPage(),
    ),
    GoRoute(
      path: '/detail/:slug',
      builder: (context, state) => TvDetailPage(
        slug: state.pathParameters['slug']!,
      ),
    ),
    GoRoute(
      path: '/player',
      builder: (context, state) {
        final extra = state.extra as Map<String, String>;
        return TvPlayerPage(
          videoUrl: extra['videoUrl']!,
          filmName: extra['filmName']!,
          episode: extra['episode']!,
          slug: extra['slug']!,
        );
      },
    ),
  ],
);

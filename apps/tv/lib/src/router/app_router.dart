import 'package:core/core.dart';
import 'package:go_router/go_router.dart';
import '../features/home/tv_home_page.dart';
import '../features/detail/tv_detail_page.dart';
import '../features/detail/tv_season_page.dart';
import '../features/player/tv_player_page.dart';
import '../features/search/tv_search_page.dart';
import '../features/auth/tv_login_page.dart';
import '../features/profile/tv_profile_page.dart';

final tvRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      builder: (context, state) => const TvHomePage(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return TvSearchPage(initialGenre: extra?['genre'] as String?);
      },
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
        final extra = state.extra as Map<String, dynamic>;
        return TvPlayerPage(
          videoUrl: extra['videoUrl'] as String,
          filmName: extra['filmName'] as String,
          episode: extra['episode'] as String,
          slug: extra['slug'] as String,
          episodes: extra['episodes'] as List<Episode>? ?? [],
        );
      },
    ),
    GoRoute(
      path: '/season/:slug',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return TvSeasonPage(
          slug: state.pathParameters['slug']!,
          filmName: extra['filmName'] as String,
          thumbUrl: extra['thumbUrl'] as String,
          episodes: extra['episodes'] as List<Episode>,
        );
      },
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const TvLoginPage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const TvProfilePage(),
    ),
  ],
);

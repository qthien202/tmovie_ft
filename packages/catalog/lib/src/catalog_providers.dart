import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';

final filmsByTypeProvider =
    FutureProvider.family<
      FilmListResponse,
      ({String typeSlug, int page, String? sortField, int? year})
    >((ref, params) {
      final repo = ref.watch(filmRepositoryProvider);
      return repo.getFilmsByType(
        params.typeSlug,
        page: params.page,
        sortField: params.sortField,
        year: params.year,
      );
    });

final searchFilmsProvider = FutureProvider.family
    .autoDispose<FilmListResponse, ({String keyword, int page})>((ref, params) {
      final repo = ref.watch(filmRepositoryProvider);
      return repo.searchFilms(params.keyword, page: params.page);
    });

final filmsByGenreProvider = FutureProvider.family
    .autoDispose<FilmListResponse, ({String slug, int page})>((ref, params) {
      final repo = ref.watch(filmRepositoryProvider);
      return repo.getFilmsByGenre(params.slug, page: params.page);
    });

final filmsByCountryProvider = FutureProvider.family
    .autoDispose<FilmListResponse, ({String slug, int page})>((ref, params) {
      final repo = ref.watch(filmRepositoryProvider);
      return repo.getFilmsByCountry(params.slug, page: params.page);
    });

/// Films shown in the home hero carousel.
///
/// Delegates to [HeroRepository], which serves a local → Firestore → OPhim
/// cache (refreshed at most once per day). For an explicit pull-to-refresh,
/// call `ref.read(heroRepositoryProvider).getHero(forceRefresh: true)` then
/// invalidate this provider.
final heroFilmsProvider = FutureProvider.autoDispose<List<FilmItem>>((ref) {
  return ref.watch(heroRepositoryProvider).getHero();
});

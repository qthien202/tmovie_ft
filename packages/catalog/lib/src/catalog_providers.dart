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
/// Prioritises the three regions our audience watches most — Korea, China and
/// the West (Âu Mỹ) — for the current year, then orders them by rating so the
/// hero always leads with the highest-scored new titles. Falls back gracefully
/// when this year has too few rated films, or when the regional calls fail.
final heroFilmsProvider = FutureProvider.autoDispose<List<FilmItem>>((
  ref,
) async {
  final repo = ref.watch(filmRepositoryProvider);
  const countrySlugs = ['han-quoc', 'trung-quoc', 'au-my'];
  final year = DateTime.now().year;

  double ratingOf(FilmItem f) =>
      f.tmdb?.voteAverage ?? f.imdb?.voteAverage ?? 0;

  Future<FilmListResponse?> fetch(String slug) async {
    try {
      return await repo.getFilmsByCountry(
        slug,
        page: 1,
        year: year,
        sortField: 'view',
      );
    } catch (_) {
      return null;
    }
  }

  final responses = await Future.wait(countrySlugs.map(fetch));

  final seen = <String>{};
  final items = <FilmItem>[];
  for (final res in responses) {
    for (final item in res?.data?.items ?? const <FilmItem>[]) {
      final slug = item.slug;
      if (slug == null || !seen.add(slug)) continue;
      items.add(item);
    }
  }

  // Highest rating first.
  items.sort((a, b) => ratingOf(b).compareTo(ratingOf(a)));

  // Prefer rated titles, but don't end up nearly empty if this year's films
  // haven't been scored yet.
  final rated = items.where((f) => ratingOf(f) > 0).toList();
  final pool = rated.length >= 5 ? rated : items;

  if (pool.isNotEmpty) return pool.take(10).toList();

  // Last resort (offline cold start / no regional results): newest updates.
  try {
    final fallback = await repo.getFilmsByType('phim-moi-cap-nhat', page: 1);
    return fallback.data?.items ?? const <FilmItem>[];
  } catch (_) {
    return const <FilmItem>[];
  }
});

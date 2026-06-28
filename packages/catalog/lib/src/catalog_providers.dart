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
/// Leads with what's hot right now — the platform's freshest updates
/// (`phim-moi-cap-nhat`, the same feed as the "Mới cập nhật" row) — while
/// prioritising the three regions our audience watches most: Korea, China and
/// the West (Âu Mỹ). Region titles come first (in their trending order), then
/// everything else, so the hero is current AND on-brand.
final heroFilmsProvider = FutureProvider.autoDispose<List<FilmItem>>((
  ref,
) async {
  final repo = ref.watch(filmRepositoryProvider);
  const preferred = {'han-quoc', 'trung-quoc', 'au-my'};

  Future<List<FilmItem>> fetchPage(int page) async {
    try {
      final res = await repo.getFilmsByType('phim-moi-cap-nhat', page: page);
      return res.data?.items ?? const <FilmItem>[];
    } catch (_) {
      return const <FilmItem>[];
    }
  }

  // A couple of pages of the freshest titles to prioritise from.
  final pages = await Future.wait([fetchPage(1), fetchPage(2)]);
  final all = [for (final p in pages) ...p];

  bool isPreferred(FilmItem f) =>
      (f.country ?? const <FilmCountry>[]).any((c) => preferred.contains(c.slug));

  final region = <FilmItem>[];
  final rest = <FilmItem>[];
  final seen = <String>{};
  for (final f in all) {
    final slug = f.slug;
    if (slug == null || !seen.add(slug)) continue;
    (isPreferred(f) ? region : rest).add(f);
  }

  // Region titles first; top up with other fresh titles so the hero is full.
  final ordered = [...region, ...rest];
  return ordered.take(10).toList();
});

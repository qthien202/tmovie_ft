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

/// Films shown in the home hero carousel — what's actually trending now.
///
/// Pipeline: TMDB (the intermediary "what's hot globally" source) → match each
/// trending title against OPhim via search (so we only show titles that are
/// actually playable here) → the searches are cached in the local Drift DB
/// (offline-first). Korea/China/West originals are prioritised. Falls back to
/// OPhim's freshest-updates feed if TMDB is unavailable or nothing matches.
final heroFilmsProvider = FutureProvider.autoDispose<List<FilmItem>>((
  ref,
) async {
  final repo = ref.watch(filmRepositoryProvider);
  final tmdb = ref.watch(tmdbServiceProvider);

  List<TmdbTrendingTitle> trending;
  try {
    trending = await tmdb.getTrending();
  } catch (_) {
    trending = const [];
  }
  if (trending.isEmpty) return _freshestFallback(repo);

  // Prioritise the regions our audience watches most.
  const prefLangs = {'ko', 'zh', 'cn', 'en'};
  trending.sort((a, b) {
    final ap = prefLangs.contains(a.language) ? 0 : 1;
    final bp = prefLangs.contains(b.language) ? 0 : 1;
    return ap.compareTo(bp);
  });

  // Look the top trending titles up on OPhim in parallel (cached per keyword).
  final candidates = trending.take(18).toList();
  final matches = await Future.wait(
    candidates.map((t) => _matchOnOphim(repo, t)),
  );

  final seen = <String>{};
  final result = <FilmItem>[];
  for (final m in matches) {
    final slug = m?.slug;
    if (m == null || slug == null || !seen.add(slug)) continue;
    result.add(m);
    if (result.length >= 10) break;
  }

  // Not enough playable matches — fall back to the freshest OPhim feed.
  if (result.length < 3) return _freshestFallback(repo);
  return result;
});

String _normalize(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

/// Find the OPhim film that best matches a TMDB trending title.
Future<FilmItem?> _matchOnOphim(
  FilmRepository repo,
  TmdbTrendingTitle t,
) async {
  for (final query in [t.name, t.originalName]) {
    if (query.trim().isEmpty) continue;
    try {
      final res = await repo.searchFilms(query);
      final items = res.data?.items ?? const <FilmItem>[];
      if (items.isEmpty) continue;
      final q = _normalize(query);
      for (final it in items) {
        final origin = _normalize(it.originName ?? '');
        final name = _normalize(it.name ?? '');
        if (origin == q ||
            name == q ||
            (origin.isNotEmpty && (origin.contains(q) || q.contains(origin)))) {
          return it;
        }
      }
      // No strong match — accept the top search hit for this title.
      return items.first;
    } catch (_) {
      // Try the next query form.
    }
  }
  return null;
}

/// OPhim's freshest-updates feed, Korea/China/West first. Offline-first cached.
Future<List<FilmItem>> _freshestFallback(FilmRepository repo) async {
  const preferred = {'han-quoc', 'trung-quoc', 'au-my'};
  Future<List<FilmItem>> page(int p) async {
    try {
      final res = await repo.getFilmsByType('phim-moi-cap-nhat', page: p);
      return res.data?.items ?? const <FilmItem>[];
    } catch (_) {
      return const <FilmItem>[];
    }
  }

  final pages = await Future.wait([page(1), page(2)]);
  final all = [for (final p in pages) ...p];
  final region = <FilmItem>[];
  final rest = <FilmItem>[];
  final seen = <String>{};
  for (final f in all) {
    final slug = f.slug;
    if (slug == null || !seen.add(slug)) continue;
    final pref = (f.country ?? const <FilmCountry>[])
        .any((c) => preferred.contains(c.slug));
    (pref ? region : rest).add(f);
  }
  return [...region, ...rest].take(10).toList();
}

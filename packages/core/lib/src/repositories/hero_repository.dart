import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../database/app_database.dart';
import '../models/country.dart';
import '../models/film_item.dart';
import '../network/tmdb_service.dart';
import '../services/shared_cache_service.dart';
import 'film_repository.dart';

/// Builds & caches the home hero list.
///
/// Read order is local → Firestore → OPhim, refreshed at most **once per day**:
/// * Local Drift cache from today → return immediately (no Firestore, no API).
/// * Else Firestore shared cache from today → backfill local, return.
/// * Else build it from the API (TMDB trending matched against OPhim), then
///   sync to BOTH local and Firestore stamped with today's date.
/// * [forceRefresh] (pull-to-refresh) skips the cache and always rebuilds from
///   the API, re-syncing both caches.
class HeroRepository {
  final FilmRepository _films;
  final TmdbService _tmdb;
  final AppDatabase _db;
  final SharedCacheService _cache;

  HeroRepository(this._films, this._tmdb, this._db, this._cache);

  // Bump the suffix whenever the build pipeline changes so stale day-caches
  // (local + Firestore) are invalidated immediately instead of lingering till
  // the next day. v2 = TMDB discover per-language, Hàn/Trung prioritized.
  static const _cacheKey = 'hero_hot_v2';
  static const _preferredCountries = {'han-quoc', 'trung-quoc', 'au-my'};

  int get _now => DateTime.now().millisecondsSinceEpoch;

  String _today() {
    final d = DateTime.now();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  Future<List<FilmItem>> getHero({bool forceRefresh = false}) async {
    final today = _today();

    if (!forceRefresh) {
      // 1. Local cache from today — cheapest, no network at all.
      final local = await _db.getAppCache(_cacheKey);
      if (local != null && local.dateKey == today) {
        final films = _decodeList(local.value);
        if (films.isNotEmpty) return films;
      }

      // 2. Firestore shared cache from today (only when local was missing).
      final remote = await _cache.read(_cacheKey);
      if (remote != null && remote['dateKey'] == today) {
        final films = _decodeRemote(remote);
        if (films.isNotEmpty) {
          await _saveLocal(films, today); // backfill so next time is local-only
          return films;
        }
      }
    }

    // 3. Build from the API (once/day, or forced) and sync both caches.
    try {
      final films = await _buildFromApi();
      if (films.isNotEmpty) {
        await _saveLocal(films, today);
        await _cache.write(_cacheKey, {
          'dateKey': today,
          'updatedAt': _now,
          // Store as a JSON string: FilmItem.toJson keeps nested FilmCategory/
          // FilmCountry as objects (explicitToJson:false), which Firestore's
          // set() rejects. Encoding to a string sidesteps that entirely.
          'itemsJson': jsonEncode(films.map((f) => f.toJson()).toList()),
        });
        return films;
      }
    } catch (_) {
      // fall through to stale caches
    }

    // 4. Anything we have, even if stale.
    final local = await _db.getAppCache(_cacheKey);
    if (local != null) {
      final films = _decodeList(local.value);
      if (films.isNotEmpty) return films;
    }
    final remote = await _cache.read(_cacheKey);
    if (remote != null) {
      final films = _decodeItems(remote['items']);
      if (films.isNotEmpty) return films;
    }
    return _freshestFallback();
  }

  Future<void> _saveLocal(List<FilmItem> films, String today) {
    return _db.putAppCache(
      AppCacheEntriesCompanion.insert(
        cacheKey: _cacheKey,
        value: jsonEncode(films.map((f) => f.toJson()).toList()),
        dateKey: Value(today),
        updatedAt: _now,
      ),
    );
  }

  List<FilmItem> _decodeList(String raw) {
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => FilmItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Firestore payload → films. Prefers the `itemsJson` string field; falls
  /// back to a legacy `items` array if present.
  List<FilmItem> _decodeRemote(Map<String, dynamic> remote) {
    final raw = remote['itemsJson'];
    if (raw is String) return _decodeList(raw);
    return _decodeItems(remote['items']);
  }

  List<FilmItem> _decodeItems(Object? raw) {
    if (raw is! List) return const [];
    try {
      return raw
          .map((e) => FilmItem.fromJson(
                (e as Map).cast<String, dynamic>(),
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // ── API pipeline: TMDB trending → match on OPhim ──
  Future<List<FilmItem>> _buildFromApi() async {
    List<TmdbTrendingTitle> trending;
    try {
      trending = await _tmdb.getTrending();
    } catch (_) {
      trending = const [];
    }
    if (trending.isEmpty) return _freshestFallback();

    // [getTrending] already orders Hàn/Trung-hot first (TMDB discover per
    // language), then a global tail — so we keep that order and just match the
    // top candidates against OPhim. No re-sort here: Dart's sort is unstable
    // and would scramble the carefully prioritized ordering.
    final candidates = trending.take(24).toList();
    final matches = await Future.wait(candidates.map(_matchOnOphim));

    final seen = <String>{};
    final result = <FilmItem>[];
    for (final m in matches) {
      final slug = m?.slug;
      if (m == null || slug == null || !seen.add(slug)) continue;
      result.add(m);
      if (result.length >= 10) break;
    }

    if (result.length < 3) return _freshestFallback();
    return result;
  }

  String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

  Future<FilmItem?> _matchOnOphim(TmdbTrendingTitle t) async {
    for (final query in [t.name, t.originalName]) {
      if (query.trim().isEmpty) continue;
      try {
        final res = await _films.searchFilms(query);
        final items = res.data?.items ?? const <FilmItem>[];
        if (items.isEmpty) continue;
        final q = _normalize(query);
        for (final it in items) {
          final origin = _normalize(it.originName ?? '');
          final name = _normalize(it.name ?? '');
          if (origin == q ||
              name == q ||
              (origin.isNotEmpty &&
                  (origin.contains(q) || q.contains(origin)))) {
            return it;
          }
        }
        return items.first;
      } catch (_) {
        // try next query form
      }
    }
    return null;
  }

  Future<List<FilmItem>> _freshestFallback() async {
    Future<List<FilmItem>> page(int p) async {
      try {
        final res = await _films.getFilmsByType('phim-moi-cap-nhat', page: p);
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
          .any((c) => _preferredCountries.contains(c.slug));
      (pref ? region : rest).add(f);
    }
    return [...region, ...rest].take(10).toList();
  }
}

import 'package:dio/dio.dart';
import '../models/tmdb_season_response.dart';

/// One trending title from TMDB, used to look the film up on OPhim.
class TmdbTrendingTitle {
  /// English / localized title — usually matches OPhim's `origin_name`.
  final String name;

  /// Native original title.
  final String originalName;

  /// ISO language of the original (`ko`, `zh`, `cn`, `en`, ...).
  final String language;

  final int? year;

  const TmdbTrendingTitle({
    required this.name,
    required this.originalName,
    required this.language,
    this.year,
  });
}

/// Service to fetch episode stills directly from TMDB API v3.
/// Uses a free API key for read-only access to public movie/TV data.
class TmdbService {
  static const _baseUrl = 'https://api.themoviedb.org/3';
  static const _apiKey = '2b07206ac62c7bfbd40cf28044152e4f';

  final Dio _dio;

  TmdbService(Dio dio)
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: dio.options.connectTimeout,
          receiveTimeout: dio.options.receiveTimeout,
        ));

  /// Fetch season details including per-episode still images.
  /// [tmdbId] - The TMDB ID of the TV show
  /// [seasonNumber] - The season number (usually 1)
  Future<TmdbSeasonResponse> getSeasonDetails({
    required String tmdbId,
    required int seasonNumber,
  }) async {
    final response = await _dio.get(
      '/tv/$tmdbId/season/$seasonNumber',
      queryParameters: {'api_key': _apiKey, 'language': 'vi-VN'},
    );
    return TmdbSeasonResponse.fromJson(response.data);
  }

  /// Hot titles to seed the home hero, **Korean/Chinese first**.
  ///
  /// The global `/trending` feed is Western-dominated, so Korean/Chinese hits
  /// barely appear. Instead we hit TMDB **discover** per language sorted by
  /// `popularity.desc` (recently-airing only) so each region's currently-hot
  /// shows surface, interleave Hàn/Trung at the front, then append a global
  /// trending tail for variety. English titles are used to match OPhim's
  /// `origin_name`.
  Future<List<TmdbTrendingTitle>> getTrending() async {
    final now = DateTime.now();
    // Keep things "currently airing": any episode aired within the last year.
    final since = DateTime(now.year - 1, now.month, 1)
        .toIso8601String()
        .substring(0, 10);

    final results = await Future.wait([
      _discoverByLanguage('ko', since), // Hàn
      _discoverByLanguage('zh', since), // Trung (Quan thoại)
      _discoverByLanguage('cn', since), // Trung (Quảng Đông / TVB)
      _globalTrending(), // tail for variety (incl. Âu Mỹ)
    ]);
    final ko = results[0];
    final zh = results[1];
    final cn = results[2];
    final global = results[3];

    // Round-robin Hàn → Trung(zh) → Trung(cn) so both regions lead together.
    final asia = <TmdbTrendingTitle>[];
    final maxLen = [
      ko.length,
      zh.length,
      cn.length,
    ].fold(0, (m, l) => l > m ? l : m);
    for (var i = 0; i < maxLen; i++) {
      if (i < ko.length) asia.add(ko[i]);
      if (i < zh.length) asia.add(zh[i]);
      if (i < cn.length) asia.add(cn[i]);
    }
    return [...asia, ...global];
  }

  /// Most-popular recently-airing TV in a single original language.
  Future<List<TmdbTrendingTitle>> _discoverByLanguage(
    String lang,
    String airedSince,
  ) async {
    try {
      final res = await _dio.get(
        '/discover/tv',
        queryParameters: {
          'api_key': _apiKey,
          'with_original_language': lang,
          'sort_by': 'popularity.desc',
          'air_date.gte': airedSince,
          'vote_count.gte': 10,
          'page': 1,
        },
      );
      return _parseTitles(
        (res.data['results'] as List?) ?? const [],
        tv: true,
        fallbackLang: lang,
      );
    } catch (_) {
      return const [];
    }
  }

  /// Global weekly trending (TV + movie) — appended after the Asian leads.
  Future<List<TmdbTrendingTitle>> _globalTrending() async {
    final out = <TmdbTrendingTitle>[];
    for (final path in ['/trending/tv/week', '/trending/movie/week']) {
      try {
        final res = await _dio.get(
          path,
          queryParameters: {'api_key': _apiKey},
        );
        out.addAll(
          _parseTitles(
            (res.data['results'] as List?) ?? const [],
            tv: path.contains('/tv/'),
          ),
        );
      } catch (_) {
        // Skip this feed on error; the other may still return data.
      }
    }
    return out;
  }

  List<TmdbTrendingTitle> _parseTitles(
    List<dynamic> results, {
    required bool tv,
    String? fallbackLang,
  }) {
    final out = <TmdbTrendingTitle>[];
    for (final raw in results) {
      final it = raw as Map<String, dynamic>;
      final isTv = tv || it.containsKey('name');
      final name = (isTv ? it['name'] : it['title']) as String? ?? '';
      final orig =
          (isTv ? it['original_name'] : it['original_title']) as String? ?? '';
      final date =
          (isTv ? it['first_air_date'] : it['release_date']) as String? ?? '';
      final year = date.length >= 4 ? int.tryParse(date.substring(0, 4)) : null;
      if (name.isNotEmpty || orig.isNotEmpty) {
        out.add(
          TmdbTrendingTitle(
            name: name,
            originalName: orig,
            language: it['original_language'] as String? ?? fallbackLang ?? '',
            year: year,
          ),
        );
      }
    }
    return out;
  }
}

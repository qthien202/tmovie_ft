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

  /// Currently-trending TV shows + movies this week. We use English titles so
  /// they can be matched against OPhim's `origin_name`.
  Future<List<TmdbTrendingTitle>> getTrending() async {
    final out = <TmdbTrendingTitle>[];
    for (final path in ['/trending/tv/week', '/trending/movie/week']) {
      try {
        final res = await _dio.get(
          path,
          queryParameters: {'api_key': _apiKey},
        );
        final results = (res.data['results'] as List?) ?? const [];
        for (final raw in results) {
          final it = raw as Map<String, dynamic>;
          final isTv = it.containsKey('name');
          final name = (isTv ? it['name'] : it['title']) as String? ?? '';
          final orig =
              (isTv ? it['original_name'] : it['original_title']) as String? ??
              '';
          final date =
              (isTv ? it['first_air_date'] : it['release_date']) as String? ??
              '';
          final year = date.length >= 4
              ? int.tryParse(date.substring(0, 4))
              : null;
          if (name.isNotEmpty || orig.isNotEmpty) {
            out.add(
              TmdbTrendingTitle(
                name: name,
                originalName: orig,
                language: it['original_language'] as String? ?? '',
                year: year,
              ),
            );
          }
        }
      } catch (_) {
        // Skip this feed on error; the other may still return data.
      }
    }
    return out;
  }
}

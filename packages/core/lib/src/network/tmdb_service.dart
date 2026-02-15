import 'package:dio/dio.dart';
import '../models/tmdb_season_response.dart';

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
}

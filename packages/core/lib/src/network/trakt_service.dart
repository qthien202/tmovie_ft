import 'package:dio/dio.dart';

/// One hot title from Trakt, used to look the film up on OPhim.
class TraktTitle {
  /// English / primary title — matched against OPhim's name/origin_name.
  final String name;

  /// ISO 639-1 language of the title (`ko`, `zh`, `en`, ...).
  final String language;

  final int? year;

  const TraktTitle({required this.name, required this.language, this.year});
}

/// Fetches **currently-hot** titles from Trakt.tv.
///
/// Trakt's `trending` lists are ranked by how many people are watching a title
/// *right now*, which tracks real momentum far better than TMDB's internal
/// popularity score. We pull Korean + Chinese trending shows first (the user
/// wants drama series), then a Western (Âu Mỹ) tail, excluding animation.
///
/// Requires a free Trakt API client id (https://trakt.tv/oauth/applications).
/// When [_clientId] is empty every call short-circuits to an empty list so the
/// hero gracefully falls back to its OPhim "freshest" list instead of erroring.
class TraktService {
  static const _baseUrl = 'https://api.trakt.tv';

  /// Free Trakt application client id (read-only public data, like the TMDB
  /// key). Overridable at build time via --dart-define=TRAKT_CLIENT_ID=...
  static const _clientId = String.fromEnvironment(
    'TRAKT_CLIENT_ID',
    defaultValue:
        '68340f0dc06949031b10186f52aa0d3af90b6ec96189a1cb45ec7aa6fe5a9ffe',
  );

  final Dio _dio;

  TraktService(Dio dio)
      : _dio = Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: dio.options.connectTimeout,
            receiveTimeout: dio.options.receiveTimeout,
            headers: {
              'Content-Type': 'application/json',
              'trakt-api-version': '2',
              'trakt-api-key': _clientId,
            },
          ),
        );

  bool get _configured => _clientId.isNotEmpty;

  /// Hot titles, **Korean/Chinese drama series first**, then a Western tail.
  Future<List<TraktTitle>> getTrending() async {
    if (!_configured) return const [];

    final results = await Future.wait([
      _trendingShows(language: 'ko'), // Hàn
      _trendingShows(language: 'zh'), // Trung
      _trendingShows(), // global shows (Âu Mỹ-led)
      _trendingMovies(), // global movies (Âu Mỹ)
    ]);
    final ko = results[0];
    final zh = results[1];
    final globalShows = results[2];
    final globalMovies = results[3];

    // Interleave Hàn ↔ Trung so both lead together.
    final asia = <TraktTitle>[];
    final maxLen = ko.length > zh.length ? ko.length : zh.length;
    for (var i = 0; i < maxLen; i++) {
      if (i < ko.length) asia.add(ko[i]);
      if (i < zh.length) asia.add(zh[i]);
    }

    // Western tail = global trending minus anything already Korean/Chinese.
    final tail = [
      ...globalShows,
      ...globalMovies,
    ].where((t) => t.language != 'ko' && t.language != 'zh').toList();

    return [...asia, ...tail];
  }

  Future<List<TraktTitle>> _trendingShows({String? language}) =>
      _fetch('/shows/trending', isShow: true, language: language);

  Future<List<TraktTitle>> _trendingMovies() =>
      _fetch('/movies/trending', isShow: false);

  Future<List<TraktTitle>> _fetch(
    String path, {
    required bool isShow,
    String? language,
  }) async {
    try {
      final qp = <String, dynamic>{'extended': 'full', 'limit': 25};
      if (language != null) qp['languages'] = language;
      final res = await _dio.get(path, queryParameters: qp);
      final list = (res.data as List?) ?? const [];
      final out = <TraktTitle>[];
      for (final raw in list) {
        final wrap = raw as Map<String, dynamic>;
        final node = wrap[isShow ? 'show' : 'movie'] as Map<String, dynamic>?;
        if (node == null) continue;
        if (_isAnimation(node['genres'])) continue;
        final title = node['title'] as String? ?? '';
        if (title.isEmpty) continue;
        out.add(
          TraktTitle(
            name: title,
            language: node['language'] as String? ?? '',
            year: (node['year'] as num?)?.toInt(),
          ),
        );
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  bool _isAnimation(Object? genres) {
    if (genres is! List) return false;
    return genres.any((g) {
      final s = g.toString().toLowerCase();
      return s == 'anime' || s == 'animation';
    });
  }
}

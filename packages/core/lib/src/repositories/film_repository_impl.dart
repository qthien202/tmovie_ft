import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/film_detail_response.dart';
import '../models/film_images_response.dart';
import '../models/film_item.dart';
import '../models/film_list_response.dart';
import '../models/film_people_response.dart';
import '../network/api_service.dart';
import 'film_repository.dart';

/// Offline-first film repository.
///
/// Reads from the local Drift database first; only calls the network when the
/// stored data is missing or older than the TTL, then upserts the fresh data
/// back into the DB. On network failure it falls back to whatever the DB holds.
class FilmRepositoryImpl implements FilmRepository {
  final ApiService _apiService;
  final AppDatabase _db;

  static const _blockedCategorySlugs = {'18-plus'};
  static const _listTtl = Duration(minutes: 30);
  static const _detailTtl = Duration(hours: 24);

  FilmRepositoryImpl(this._apiService, this._db);

  int get _now => DateTime.now().millisecondsSinceEpoch;

  FilmListResponse _filterContent(FilmListResponse response) {
    final items = response.data?.items;
    if (items == null) return response;
    final filtered = items.where((item) {
      final categories = item.category ?? [];
      final isAdult =
          categories.any((c) => _blockedCategorySlugs.contains(c.slug));
      final isTrailer = item.episodeCurrent?.toLowerCase() == 'trailer';
      return !isAdult && !isTrailer;
    }).toList();
    if (filtered.length == items.length) return response;
    return FilmListResponse(
      status: response.status,
      data: FilmListData(
        items: filtered,
        params: response.data?.params,
        appDomainCdnImage: response.data?.appDomainCdnImage,
        titlePage: response.data?.titlePage,
      ),
    );
  }

  // ─────────────────────────── list helpers ───────────────────────────

  Future<FilmListResponse> _offlineFirstList(
    String key,
    Future<FilmListResponse> Function() fetch,
  ) async {
    final stored = await _db.getList(key);
    final fresh =
        stored != null && _now - stored.fetchedAt < _listTtl.inMilliseconds;
    if (fresh) return _listFromDb(stored);

    try {
      final response = _filterContent(await fetch());
      await _storeList(key, response);
      return response;
    } catch (_) {
      if (stored != null) return _listFromDb(stored); // offline fallback (DB)
      rethrow;
    }
  }

  FilmListResponse _listFromDb(FilmListRow c) =>
      FilmListResponse.fromJson(jsonDecode(c.meta) as Map<String, dynamic>);

  Future<void> _storeList(String key, FilmListResponse response) async {
    final items = response.data?.items ?? [];
    final now = _now;
    final rows = <FilmEntriesCompanion>[];
    final slugs = <String>[];
    for (final item in items) {
      final slug = item.slug;
      if (slug == null || slug.isEmpty) continue;
      rows.add(_filmCompanion(item, slug, now));
      slugs.add(slug);
    }
    if (rows.isNotEmpty) await _db.upsertFilms(rows);
    await _db.upsertList(FilmListsCompanion.insert(
      listKey: key,
      slugs: jsonEncode(slugs),
      meta: jsonEncode(response.toJson()),
      fetchedAt: now,
    ));
  }

  FilmEntriesCompanion _filmCompanion(FilmItem item, String slug, int now) {
    return FilmEntriesCompanion.insert(
      slug: slug,
      name: Value(item.name),
      type: Value(item.type),
      year: Value(item.year),
      posterUrl: Value(item.posterUrl),
      thumbUrl: Value(item.thumbUrl),
      episodeCurrent: Value(item.episodeCurrent),
      json: jsonEncode(item.toJson()),
      updatedAt: now,
    );
  }

  // ─────────────────────────── lists ───────────────────────────

  @override
  Future<FilmListResponse> getFilmsByType(
    String typeSlug, {
    int page = 1,
    String? category,
    String? country,
    int? year,
    String? sortField,
  }) {
    final key = 'type:$typeSlug|p:$page|c:$category|co:$country'
        '|y:$year|s:$sortField';
    return _offlineFirstList(
      key,
      () => _apiService.getFilmsByType(
        typeSlug: typeSlug,
        page: page,
        category: category,
        country: country,
        year: year,
        sortField: sortField,
      ),
    );
  }

  @override
  Future<FilmListResponse> searchFilms(String keyword, {int page = 1}) {
    final key = 'search:$keyword|p:$page';
    return _offlineFirstList(
      key,
      () => _apiService.searchFilms(keyword: keyword, page: page),
    );
  }

  @override
  Future<FilmListResponse> getFilmsByGenre(
    String slug, {
    int page = 1,
    String? country,
    int? year,
    String? sortField,
  }) {
    final key = 'genre:$slug|p:$page|co:$country|y:$year|s:$sortField';
    return _offlineFirstList(
      key,
      () => _apiService.getFilmsByGenre(
        slug: slug,
        page: page,
        country: country,
        year: year,
        sortField: sortField,
      ),
    );
  }

  @override
  Future<FilmListResponse> getFilmsByCountry(
    String slug, {
    int page = 1,
    String? category,
    int? year,
    String? sortField,
  }) {
    final key = 'country:$slug|p:$page|c:$category|y:$year|s:$sortField';
    return _offlineFirstList(
      key,
      () => _apiService.getFilmsByCountry(
        slug: slug,
        page: page,
        category: category,
        year: year,
        sortField: sortField,
      ),
    );
  }

  // ─────────────────────────── detail / peoples / images ───────────────────────────

  @override
  Future<FilmDetailResponse> getFilmDetail(String slug) async {
    final stored = await _db.getDetail(slug);
    final fresh =
        stored != null && _now - stored.fetchedAt < _detailTtl.inMilliseconds;
    if (fresh) {
      return FilmDetailResponse.fromJson(
          jsonDecode(stored.json) as Map<String, dynamic>);
    }
    try {
      final response = await _apiService.getFilmDetail(slug: slug);
      await _db.upsertDetail(FilmDetailsCompanion.insert(
        slug: slug,
        json: jsonEncode(response.toJson()),
        fetchedAt: _now,
      ));
      return response;
    } catch (_) {
      if (stored != null) {
        return FilmDetailResponse.fromJson(
            jsonDecode(stored.json) as Map<String, dynamic>);
      }
      rethrow;
    }
  }

  @override
  Future<FilmPeopleResponse> getFilmPeoples(String slug) async {
    final stored = await _db.getPeople(slug);
    final fresh =
        stored != null && _now - stored.fetchedAt < _detailTtl.inMilliseconds;
    if (fresh) {
      return FilmPeopleResponse.fromJson(
          jsonDecode(stored.json) as Map<String, dynamic>);
    }
    try {
      final response = await _apiService.getFilmPeoples(slug: slug);
      await _db.upsertPeople(FilmPeoplesCompanion.insert(
        slug: slug,
        json: jsonEncode(response.toJson()),
        fetchedAt: _now,
      ));
      return response;
    } catch (_) {
      if (stored != null) {
        return FilmPeopleResponse.fromJson(
            jsonDecode(stored.json) as Map<String, dynamic>);
      }
      rethrow;
    }
  }

  @override
  Future<FilmImagesResponse> getFilmImages(String slug) async {
    final stored = await _db.getImages(slug);
    final fresh =
        stored != null && _now - stored.fetchedAt < _detailTtl.inMilliseconds;
    if (fresh) {
      return FilmImagesResponse.fromJson(
          jsonDecode(stored.json) as Map<String, dynamic>);
    }
    try {
      final response = await _apiService.getFilmImages(slug: slug);
      await _db.upsertImages(FilmImagesCompanion.insert(
        slug: slug,
        json: jsonEncode(response.toJson()),
        fetchedAt: _now,
      ));
      return response;
    } catch (_) {
      if (stored != null) {
        return FilmImagesResponse.fromJson(
            jsonDecode(stored.json) as Map<String, dynamic>);
      }
      rethrow;
    }
  }
}

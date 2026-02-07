import '../network/api_service.dart';
import '../models/film_list_response.dart';
import '../models/film_detail_response.dart';
import '../models/film_people_response.dart';
import '../models/film_images_response.dart';
import 'film_repository.dart';

class FilmRepositoryImpl implements FilmRepository {
  final ApiService _apiService;

  static const _blockedCategorySlugs = {'18-plus'};

  FilmRepositoryImpl(this._apiService);

  FilmListResponse _filterAdultContent(FilmListResponse response) {
    final items = response.data?.items;
    if (items == null) return response;
    final filtered = items.where((item) {
      final categories = item.category ?? [];
      return !categories.any((c) => _blockedCategorySlugs.contains(c.slug));
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

  @override
  Future<FilmListResponse> getFilmsByType(
    String typeSlug, {
    int page = 1,
    String? category,
    String? country,
    int? year,
    String? sortField,
  }) async {
    final response = await _apiService.getFilmsByType(
      typeSlug: typeSlug,
      page: page,
      category: category,
      country: country,
      year: year,
      sortField: sortField,
    );
    return _filterAdultContent(response);
  }

  @override
  Future<FilmDetailResponse> getFilmDetail(String slug) =>
      _apiService.getFilmDetail(slug: slug);

  @override
  Future<FilmListResponse> searchFilms(String keyword, {int page = 1}) async {
    final response =
        await _apiService.searchFilms(keyword: keyword, page: page);
    return _filterAdultContent(response);
  }

  @override
  Future<FilmListResponse> getFilmsByGenre(
    String slug, {
    int page = 1,
    String? country,
    int? year,
    String? sortField,
  }) async {
    final response = await _apiService.getFilmsByGenre(
      slug: slug,
      page: page,
      country: country,
      year: year,
      sortField: sortField,
    );
    return _filterAdultContent(response);
  }

  @override
  Future<FilmListResponse> getFilmsByCountry(
    String slug, {
    int page = 1,
    String? category,
    int? year,
    String? sortField,
  }) async {
    final response = await _apiService.getFilmsByCountry(
      slug: slug,
      page: page,
      category: category,
      year: year,
      sortField: sortField,
    );
    return _filterAdultContent(response);
  }

  @override
  Future<FilmPeopleResponse> getFilmPeoples(String slug) =>
      _apiService.getFilmPeoples(slug: slug);

  @override
  Future<FilmImagesResponse> getFilmImages(String slug) =>
      _apiService.getFilmImages(slug: slug);
}

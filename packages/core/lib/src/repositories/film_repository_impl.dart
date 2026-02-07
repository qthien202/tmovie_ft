import '../network/api_service.dart';
import '../models/film_list_response.dart';
import '../models/film_detail_response.dart';
import 'film_repository.dart';

class FilmRepositoryImpl implements FilmRepository {
  final ApiService _apiService;

  FilmRepositoryImpl(this._apiService);

  @override
  Future<FilmListResponse> getFilmsByType(
    String typeSlug, {
    int page = 1,
    String? category,
    String? country,
    int? year,
    String? sortField,
  }) =>
      _apiService.getFilmsByType(
        typeSlug: typeSlug,
        page: page,
        category: category,
        country: country,
        year: year,
        sortField: sortField,
      );

  @override
  Future<FilmDetailResponse> getFilmDetail(String slug) =>
      _apiService.getFilmDetail(slug: slug);

  @override
  Future<FilmListResponse> searchFilms(String keyword, {int page = 1}) =>
      _apiService.searchFilms(keyword: keyword, page: page);

  @override
  Future<FilmListResponse> getFilmsByGenre(
    String slug, {
    int page = 1,
    String? country,
    int? year,
    String? sortField,
  }) =>
      _apiService.getFilmsByGenre(
        slug: slug,
        page: page,
        country: country,
        year: year,
        sortField: sortField,
      );

  @override
  Future<FilmListResponse> getFilmsByCountry(
    String slug, {
    int page = 1,
    String? category,
    int? year,
    String? sortField,
  }) =>
      _apiService.getFilmsByCountry(
        slug: slug,
        page: page,
        category: category,
        year: year,
        sortField: sortField,
      );
}

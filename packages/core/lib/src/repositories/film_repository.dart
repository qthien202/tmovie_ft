import '../models/film_list_response.dart';
import '../models/film_detail_response.dart';

abstract class FilmRepository {
  Future<FilmListResponse> getFilmsByType(String typeSlug, {int page = 1});
  Future<FilmDetailResponse> getFilmDetail(String slug);
  Future<FilmListResponse> searchFilms(String keyword, {int page = 1});
  Future<FilmListResponse> getFilmsByGenre(String slug, {int page = 1});
  Future<FilmListResponse> getFilmsByCountry(String slug, {int page = 1});
}

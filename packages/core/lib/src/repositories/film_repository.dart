import '../models/film_list_response.dart';
import '../models/film_detail_response.dart';
import '../models/film_people_response.dart';
import '../models/film_images_response.dart';

abstract class FilmRepository {
  Future<FilmListResponse> getFilmsByType(
    String typeSlug, {
    int page = 1,
    String? category,
    String? country,
    int? year,
    String? sortField,
  });
  Future<FilmDetailResponse> getFilmDetail(String slug);
  Future<FilmListResponse> searchFilms(String keyword, {int page = 1});
  Future<FilmListResponse> getFilmsByGenre(
    String slug, {
    int page = 1,
    String? country,
    int? year,
    String? sortField,
  });
  Future<FilmListResponse> getFilmsByCountry(
    String slug, {
    int page = 1,
    String? category,
    int? year,
    String? sortField,
  });
  Future<FilmPeopleResponse> getFilmPeoples(String slug);
  Future<FilmImagesResponse> getFilmImages(String slug);
}

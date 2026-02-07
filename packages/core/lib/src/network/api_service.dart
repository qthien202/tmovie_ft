import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../constants/api_constants.dart';
import '../models/film_list_response.dart';
import '../models/film_detail_response.dart';

part 'api_service.g.dart';

@RestApi(baseUrl: ApiConstants.apiBaseUrl)
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  @GET('/danh-sach/{type_slug}')
  Future<FilmListResponse> getFilmsByType({
    @Path('type_slug') required String typeSlug,
    @Query('page') int page = 1,
    @Query('category') String? category,
    @Query('country') String? country,
    @Query('year') int? year,
    @Query('sort_field') String? sortField,
  });

  @GET('/phim/{slug}')
  Future<FilmDetailResponse> getFilmDetail({
    @Path('slug') required String slug,
  });

  @GET('/tim-kiem')
  Future<FilmListResponse> searchFilms({
    @Query('keyword') required String keyword,
    @Query('page') int page = 1,
  });

  @GET('/the-loai/{slug}')
  Future<FilmListResponse> getFilmsByGenre({
    @Path('slug') required String slug,
    @Query('page') int page = 1,
    @Query('country') String? country,
    @Query('year') int? year,
    @Query('sort_field') String? sortField,
  });

  @GET('/quoc-gia/{slug}')
  Future<FilmListResponse> getFilmsByCountry({
    @Path('slug') required String slug,
    @Query('page') int page = 1,
    @Query('category') String? category,
    @Query('year') int? year,
    @Query('sort_field') String? sortField,
  });
}

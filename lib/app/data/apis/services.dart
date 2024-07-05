import 'dart:io';
import 'package:tmovie_app/app/core/global_data.dart';
import 'package:tmovie_app/app/data/repository/get_film_by_category.dart';
import 'package:tmovie_app/app/data/repository/get_film_details.dart';
import 'package:tmovie_app/app/data/repository/get_history_response.dart';
import 'package:tmovie_app/app/data/repository/get_new_film.dart';
import 'package:tmovie_app/app/data/repository/post_add_history.dart';
import 'package:tmovie_app/app/data/repository/post_create_token.dart';
import 'package:tmovie_app/app/data/repository/post_create_token_response.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'services.g.dart';

@RestApi(baseUrl: GlobalData.baseUrl)
abstract class Services {
  factory Services(Dio dio, {String baseUrl}) = _Services;
  @GET("/new-film")
  Future<GetNewFilm> getNewFilm();

  @GET("/list-film")
  Future<GetFilmByCategory> getFilmByCategory(
      {@Query('path') required String path,
      @Query('category') required String? category,
      @Query('page') required int? page,
      @Query('country') required String? country,
      @Query('year') required String? year});

  @GET("/genre")
  Future<GetFilmByCategory> getMovieGenre(
      {@Query('path') required String path,
      @Query('page') required int? page,
      @Query('country') required String? country,
      @Query('year') required String? year});

  @GET("/details/{path}")
  Future<GetFilmDetails> getFilmDetails({@Path('path') required String path});

  @GET("/search/{keyword}")
  Future<GetFilmByCategory> getSearch(
      {@Path("keyword") required String keyWord, @Query('page') int? page});

  @POST("/create-token")
  Future<PostCreateTokenResponse> postCreateToken(
      {@Body() PostCreateToken? body});

  @POST("/add-history")
  Future postAddHistory({@Body() PostAddHistory? body});

  @GET("/history")
  Future<GetHistoryRespone> getHistory(
      {@Query('limit') int? limit, @Header("Authorization") String? token});
}

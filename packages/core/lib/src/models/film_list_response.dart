import 'package:json_annotation/json_annotation.dart';
import 'film_item.dart';
import 'pagination.dart';

part 'film_list_response.g.dart';

@JsonSerializable()
class FilmListResponse {
  final String? status;
  final FilmListData? data;

  const FilmListResponse({this.status, this.data});

  factory FilmListResponse.fromJson(Map<String, dynamic> json) =>
      _$FilmListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$FilmListResponseToJson(this);
}

@JsonSerializable()
class FilmListData {
  final List<FilmItem>? items;
  final FilmListParams? params;
  @JsonKey(name: 'APP_DOMAIN_CDN_IMAGE')
  final String? appDomainCdnImage;
  final String? titlePage;

  const FilmListData({
    this.items,
    this.params,
    this.appDomainCdnImage,
    this.titlePage,
  });

  factory FilmListData.fromJson(Map<String, dynamic> json) =>
      _$FilmListDataFromJson(json);
  Map<String, dynamic> toJson() => _$FilmListDataToJson(this);
}

@JsonSerializable()
class FilmListParams {
  final Pagination? pagination;

  const FilmListParams({this.pagination});

  factory FilmListParams.fromJson(Map<String, dynamic> json) =>
      _$FilmListParamsFromJson(json);
  Map<String, dynamic> toJson() => _$FilmListParamsToJson(this);
}

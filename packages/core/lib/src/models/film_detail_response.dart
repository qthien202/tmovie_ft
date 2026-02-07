import 'package:json_annotation/json_annotation.dart';
import 'film_detail.dart';

part 'film_detail_response.g.dart';

@JsonSerializable()
class FilmDetailResponse {
  final String? status;
  final FilmDetailData? data;

  const FilmDetailResponse({this.status, this.data});

  factory FilmDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$FilmDetailResponseFromJson(json);
  Map<String, dynamic> toJson() => _$FilmDetailResponseToJson(this);
}

@JsonSerializable()
class FilmDetailData {
  final FilmDetail? item;

  const FilmDetailData({this.item});

  factory FilmDetailData.fromJson(Map<String, dynamic> json) =>
      _$FilmDetailDataFromJson(json);
  Map<String, dynamic> toJson() => _$FilmDetailDataToJson(this);
}

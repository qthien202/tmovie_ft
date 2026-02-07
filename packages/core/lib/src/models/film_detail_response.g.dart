// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'film_detail_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FilmDetailResponse _$FilmDetailResponseFromJson(Map<String, dynamic> json) =>
    FilmDetailResponse(
      status: json['status'] as String?,
      data: json['data'] == null
          ? null
          : FilmDetailData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FilmDetailResponseToJson(FilmDetailResponse instance) =>
    <String, dynamic>{'status': instance.status, 'data': instance.data};

FilmDetailData _$FilmDetailDataFromJson(Map<String, dynamic> json) =>
    FilmDetailData(
      item: json['item'] == null
          ? null
          : FilmDetail.fromJson(json['item'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FilmDetailDataToJson(FilmDetailData instance) =>
    <String, dynamic>{'item': instance.item};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'film_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FilmListResponse _$FilmListResponseFromJson(Map<String, dynamic> json) =>
    FilmListResponse(
      status: json['status'] as String?,
      data: json['data'] == null
          ? null
          : FilmListData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FilmListResponseToJson(FilmListResponse instance) =>
    <String, dynamic>{'status': instance.status, 'data': instance.data};

FilmListData _$FilmListDataFromJson(Map<String, dynamic> json) => FilmListData(
  items: (json['items'] as List<dynamic>?)
      ?.map((e) => FilmItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  params: json['params'] == null
      ? null
      : FilmListParams.fromJson(json['params'] as Map<String, dynamic>),
  appDomainCdnImage: json['APP_DOMAIN_CDN_IMAGE'] as String?,
  titlePage: json['titlePage'] as String?,
);

Map<String, dynamic> _$FilmListDataToJson(FilmListData instance) =>
    <String, dynamic>{
      'items': instance.items,
      'params': instance.params,
      'APP_DOMAIN_CDN_IMAGE': instance.appDomainCdnImage,
      'titlePage': instance.titlePage,
    };

FilmListParams _$FilmListParamsFromJson(Map<String, dynamic> json) =>
    FilmListParams(
      pagination: json['pagination'] == null
          ? null
          : Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FilmListParamsToJson(FilmListParams instance) =>
    <String, dynamic>{'pagination': instance.pagination};

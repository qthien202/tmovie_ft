// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'film_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FilmItem _$FilmItemFromJson(Map<String, dynamic> json) => FilmItem(
  id: json['_id'] as String?,
  name: json['name'] as String?,
  slug: json['slug'] as String?,
  originName: json['origin_name'] as String?,
  type: json['type'] as String?,
  thumbUrl: json['thumb_url'] as String?,
  posterUrl: json['poster_url'] as String?,
  subDocquyen: json['sub_docquyen'] as bool?,
  chieurap: json['chieurap'] as bool?,
  time: json['time'] as String?,
  episodeCurrent: json['episode_current'] as String?,
  quality: json['quality'] as String?,
  lang: json['lang'] as String?,
  year: (json['year'] as num?)?.toInt(),
  category: (json['category'] as List<dynamic>?)
      ?.map((e) => FilmCategory.fromJson(e as Map<String, dynamic>))
      .toList(),
  country: (json['country'] as List<dynamic>?)
      ?.map((e) => FilmCountry.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$FilmItemToJson(FilmItem instance) => <String, dynamic>{
  '_id': instance.id,
  'name': instance.name,
  'slug': instance.slug,
  'origin_name': instance.originName,
  'type': instance.type,
  'thumb_url': instance.thumbUrl,
  'poster_url': instance.posterUrl,
  'sub_docquyen': instance.subDocquyen,
  'chieurap': instance.chieurap,
  'time': instance.time,
  'episode_current': instance.episodeCurrent,
  'quality': instance.quality,
  'lang': instance.lang,
  'year': instance.year,
  'category': instance.category,
  'country': instance.country,
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'film_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FilmDetail _$FilmDetailFromJson(Map<String, dynamic> json) => FilmDetail(
  id: json['_id'] as String?,
  name: json['name'] as String?,
  slug: json['slug'] as String?,
  originName: json['origin_name'] as String?,
  content: json['content'] as String?,
  type: json['type'] as String?,
  status: json['status'] as String?,
  thumbUrl: json['thumb_url'] as String?,
  posterUrl: json['poster_url'] as String?,
  trailerUrl: json['trailer_url'] as String?,
  time: json['time'] as String?,
  episodeCurrent: json['episode_current'] as String?,
  episodeTotal: json['episode_total'] as String?,
  quality: json['quality'] as String?,
  lang: json['lang'] as String?,
  year: (json['year'] as num?)?.toInt(),
  view: (json['view'] as num?)?.toInt(),
  actor: (json['actor'] as List<dynamic>?)?.map((e) => e as String).toList(),
  director: (json['director'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  category: (json['category'] as List<dynamic>?)
      ?.map((e) => FilmCategory.fromJson(e as Map<String, dynamic>))
      .toList(),
  country: (json['country'] as List<dynamic>?)
      ?.map((e) => FilmCountry.fromJson(e as Map<String, dynamic>))
      .toList(),
  episodes: (json['episodes'] as List<dynamic>?)
      ?.map((e) => Episode.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$FilmDetailToJson(FilmDetail instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'origin_name': instance.originName,
      'content': instance.content,
      'type': instance.type,
      'status': instance.status,
      'thumb_url': instance.thumbUrl,
      'poster_url': instance.posterUrl,
      'trailer_url': instance.trailerUrl,
      'time': instance.time,
      'episode_current': instance.episodeCurrent,
      'episode_total': instance.episodeTotal,
      'quality': instance.quality,
      'lang': instance.lang,
      'year': instance.year,
      'view': instance.view,
      'actor': instance.actor,
      'director': instance.director,
      'category': instance.category,
      'country': instance.country,
      'episodes': instance.episodes,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tmdb_season_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TmdbSeasonResponse _$TmdbSeasonResponseFromJson(Map<String, dynamic> json) =>
    TmdbSeasonResponse(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      seasonNumber: (json['season_number'] as num?)?.toInt(),
      episodes: (json['episodes'] as List<dynamic>?)
          ?.map((e) => TmdbEpisode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TmdbSeasonResponseToJson(TmdbSeasonResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'overview': instance.overview,
      'poster_path': instance.posterPath,
      'season_number': instance.seasonNumber,
      'episodes': instance.episodes,
    };

TmdbEpisode _$TmdbEpisodeFromJson(Map<String, dynamic> json) => TmdbEpisode(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  overview: json['overview'] as String?,
  episodeNumber: (json['episode_number'] as num?)?.toInt(),
  seasonNumber: (json['season_number'] as num?)?.toInt(),
  stillPath: json['still_path'] as String?,
  airDate: json['air_date'] as String?,
  voteAverage: (json['vote_average'] as num?)?.toDouble(),
  runtime: (json['runtime'] as num?)?.toInt(),
);

Map<String, dynamic> _$TmdbEpisodeToJson(TmdbEpisode instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'overview': instance.overview,
      'episode_number': instance.episodeNumber,
      'season_number': instance.seasonNumber,
      'still_path': instance.stillPath,
      'air_date': instance.airDate,
      'vote_average': instance.voteAverage,
      'runtime': instance.runtime,
    };

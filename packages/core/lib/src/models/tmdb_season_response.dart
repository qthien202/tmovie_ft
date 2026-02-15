import 'package:json_annotation/json_annotation.dart';

part 'tmdb_season_response.g.dart';

@JsonSerializable()
class TmdbSeasonResponse {
  final int? id;
  final String? name;
  final String? overview;
  @JsonKey(name: 'poster_path')
  final String? posterPath;
  @JsonKey(name: 'season_number')
  final int? seasonNumber;
  final List<TmdbEpisode>? episodes;

  const TmdbSeasonResponse({
    this.id,
    this.name,
    this.overview,
    this.posterPath,
    this.seasonNumber,
    this.episodes,
  });

  factory TmdbSeasonResponse.fromJson(Map<String, dynamic> json) =>
      _$TmdbSeasonResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TmdbSeasonResponseToJson(this);
}

@JsonSerializable()
class TmdbEpisode {
  final int? id;
  final String? name;
  final String? overview;
  @JsonKey(name: 'episode_number')
  final int? episodeNumber;
  @JsonKey(name: 'season_number')
  final int? seasonNumber;
  @JsonKey(name: 'still_path')
  final String? stillPath;
  @JsonKey(name: 'air_date')
  final String? airDate;
  @JsonKey(name: 'vote_average')
  final double? voteAverage;
  final int? runtime;

  const TmdbEpisode({
    this.id,
    this.name,
    this.overview,
    this.episodeNumber,
    this.seasonNumber,
    this.stillPath,
    this.airDate,
    this.voteAverage,
    this.runtime,
  });

  /// Get the full still image URL at specified width
  String? getStillUrl({String size = 'w300'}) {
    if (stillPath == null || stillPath!.isEmpty) return null;
    return 'https://image.tmdb.org/t/p/$size$stillPath';
  }

  factory TmdbEpisode.fromJson(Map<String, dynamic> json) =>
      _$TmdbEpisodeFromJson(json);
  Map<String, dynamic> toJson() => _$TmdbEpisodeToJson(this);
}

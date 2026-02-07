import 'package:json_annotation/json_annotation.dart';
import 'category.dart';
import 'country.dart';
import 'episode.dart';

part 'film_detail.g.dart';

@JsonSerializable()
class FilmDetail {
  @JsonKey(name: '_id')
  final String? id;
  final String? name;
  final String? slug;
  @JsonKey(name: 'origin_name')
  final String? originName;
  final String? content;
  final String? type;
  final String? status;
  @JsonKey(name: 'thumb_url')
  final String? thumbUrl;
  @JsonKey(name: 'poster_url')
  final String? posterUrl;
  @JsonKey(name: 'trailer_url')
  final String? trailerUrl;
  final String? time;
  @JsonKey(name: 'episode_current')
  final String? episodeCurrent;
  @JsonKey(name: 'episode_total')
  final String? episodeTotal;
  final String? quality;
  final String? lang;
  final int? year;
  final int? view;
  final List<String>? actor;
  final List<String>? director;
  final List<FilmCategory>? category;
  final List<FilmCountry>? country;
  final List<Episode>? episodes;

  const FilmDetail({
    this.id,
    this.name,
    this.slug,
    this.originName,
    this.content,
    this.type,
    this.status,
    this.thumbUrl,
    this.posterUrl,
    this.trailerUrl,
    this.time,
    this.episodeCurrent,
    this.episodeTotal,
    this.quality,
    this.lang,
    this.year,
    this.view,
    this.actor,
    this.director,
    this.category,
    this.country,
    this.episodes,
  });

  String get fullThumbUrl {
    if (thumbUrl == null || thumbUrl!.isEmpty) return '';
    if (thumbUrl!.startsWith('http')) return thumbUrl!;
    return 'https://img.ophim.live/uploads/movies/$thumbUrl';
  }

  String get fullPosterUrl {
    if (posterUrl == null || posterUrl!.isEmpty) return '';
    if (posterUrl!.startsWith('http')) return posterUrl!;
    return 'https://img.ophim.live/uploads/movies/$posterUrl';
  }

  factory FilmDetail.fromJson(Map<String, dynamic> json) => _$FilmDetailFromJson(json);
  Map<String, dynamic> toJson() => _$FilmDetailToJson(this);
}

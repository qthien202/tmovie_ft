import 'package:json_annotation/json_annotation.dart';
import 'category.dart';
import 'country.dart';
import 'film_detail.dart';

part 'film_item.g.dart';

@JsonSerializable()
class FilmItem {
  @JsonKey(name: '_id')
  final String? id;
  final String? name;
  final String? slug;
  @JsonKey(name: 'origin_name')
  final String? originName;
  final String? type;
  @JsonKey(name: 'thumb_url')
  final String? thumbUrl;
  @JsonKey(name: 'poster_url')
  final String? posterUrl;
  @JsonKey(name: 'sub_docquyen')
  final bool? subDocquyen;
  final bool? chieurap;
  final String? time;
  @JsonKey(name: 'episode_current')
  final String? episodeCurrent;
  final String? quality;
  final String? lang;
  final int? year;
  final List<FilmCategory>? category;
  final List<FilmCountry>? country;
  final TmdbInfo? tmdb;
  final ImdbInfo? imdb;

  const FilmItem({
    this.id,
    this.name,
    this.slug,
    this.originName,
    this.type,
    this.thumbUrl,
    this.posterUrl,
    this.subDocquyen,
    this.chieurap,
    this.time,
    this.episodeCurrent,
    this.quality,
    this.lang,
    this.year,
    this.category,
    this.country,
    this.tmdb,
    this.imdb,
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

  factory FilmItem.fromJson(Map<String, dynamic> json) => _$FilmItemFromJson(json);
  Map<String, dynamic> toJson() => _$FilmItemToJson(this);
}

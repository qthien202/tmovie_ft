import 'package:json_annotation/json_annotation.dart';

part 'country.g.dart';

@JsonSerializable()
class FilmCountry {
  final String? id;
  final String? name;
  final String? slug;

  const FilmCountry({this.id, this.name, this.slug});

  factory FilmCountry.fromJson(Map<String, dynamic> json) => _$FilmCountryFromJson(json);
  Map<String, dynamic> toJson() => _$FilmCountryToJson(this);
}

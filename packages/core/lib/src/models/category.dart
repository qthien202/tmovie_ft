import 'package:json_annotation/json_annotation.dart';

part 'category.g.dart';

@JsonSerializable()
class FilmCategory {
  final String? id;
  final String? name;
  final String? slug;

  const FilmCategory({this.id, this.name, this.slug});

  factory FilmCategory.fromJson(Map<String, dynamic> json) => _$FilmCategoryFromJson(json);
  Map<String, dynamic> toJson() => _$FilmCategoryToJson(this);
}

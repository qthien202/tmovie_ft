import 'package:json_annotation/json_annotation.dart';

part 'film_people_response.g.dart';

@JsonSerializable()
class FilmPeopleResponse {
  final bool? success;
  final String? message;
  final FilmPeopleData? data;

  const FilmPeopleResponse({this.success, this.message, this.data});

  factory FilmPeopleResponse.fromJson(Map<String, dynamic> json) =>
      _$FilmPeopleResponseFromJson(json);
  Map<String, dynamic> toJson() => _$FilmPeopleResponseToJson(this);
}

@JsonSerializable()
class FilmPeopleData {
  @JsonKey(name: 'profile_sizes')
  final ProfileSizes? profileSizes;
  final List<FilmPerson>? peoples;

  const FilmPeopleData({this.profileSizes, this.peoples});

  factory FilmPeopleData.fromJson(Map<String, dynamic> json) =>
      _$FilmPeopleDataFromJson(json);
  Map<String, dynamic> toJson() => _$FilmPeopleDataToJson(this);
}

@JsonSerializable()
class ProfileSizes {
  final String? original;
  final String? w185;
  final String? h632;
  final String? w45;

  const ProfileSizes({this.original, this.w185, this.h632, this.w45});

  factory ProfileSizes.fromJson(Map<String, dynamic> json) =>
      _$ProfileSizesFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileSizesToJson(this);
}

@JsonSerializable()
class FilmPerson {
  @JsonKey(name: 'tmdb_people_id')
  final int? tmdbPeopleId;
  final String? name;
  @JsonKey(name: 'original_name')
  final String? originalName;
  final String? character;
  @JsonKey(name: 'known_for_department')
  final String? knownForDepartment;
  @JsonKey(name: 'profile_path')
  final String? profilePath;
  final int? gender;
  @JsonKey(name: 'gender_name')
  final String? genderName;

  const FilmPerson({
    this.tmdbPeopleId,
    this.name,
    this.originalName,
    this.character,
    this.knownForDepartment,
    this.profilePath,
    this.gender,
    this.genderName,
  });

  factory FilmPerson.fromJson(Map<String, dynamic> json) =>
      _$FilmPersonFromJson(json);
  Map<String, dynamic> toJson() => _$FilmPersonToJson(this);
}

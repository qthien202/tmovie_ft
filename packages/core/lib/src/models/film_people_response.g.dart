// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'film_people_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FilmPeopleResponse _$FilmPeopleResponseFromJson(Map<String, dynamic> json) =>
    FilmPeopleResponse(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : FilmPeopleData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FilmPeopleResponseToJson(FilmPeopleResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

FilmPeopleData _$FilmPeopleDataFromJson(Map<String, dynamic> json) =>
    FilmPeopleData(
      profileSizes: json['profile_sizes'] == null
          ? null
          : ProfileSizes.fromJson(
              json['profile_sizes'] as Map<String, dynamic>,
            ),
      peoples: (json['peoples'] as List<dynamic>?)
          ?.map((e) => FilmPerson.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FilmPeopleDataToJson(FilmPeopleData instance) =>
    <String, dynamic>{
      'profile_sizes': instance.profileSizes,
      'peoples': instance.peoples,
    };

ProfileSizes _$ProfileSizesFromJson(Map<String, dynamic> json) => ProfileSizes(
  original: json['original'] as String?,
  w185: json['w185'] as String?,
  h632: json['h632'] as String?,
  w45: json['w45'] as String?,
);

Map<String, dynamic> _$ProfileSizesToJson(ProfileSizes instance) =>
    <String, dynamic>{
      'original': instance.original,
      'w185': instance.w185,
      'h632': instance.h632,
      'w45': instance.w45,
    };

FilmPerson _$FilmPersonFromJson(Map<String, dynamic> json) => FilmPerson(
  tmdbPeopleId: (json['tmdb_people_id'] as num?)?.toInt(),
  name: json['name'] as String?,
  originalName: json['original_name'] as String?,
  character: json['character'] as String?,
  knownForDepartment: json['known_for_department'] as String?,
  profilePath: json['profile_path'] as String?,
  gender: (json['gender'] as num?)?.toInt(),
  genderName: json['gender_name'] as String?,
);

Map<String, dynamic> _$FilmPersonToJson(FilmPerson instance) =>
    <String, dynamic>{
      'tmdb_people_id': instance.tmdbPeopleId,
      'name': instance.name,
      'original_name': instance.originalName,
      'character': instance.character,
      'known_for_department': instance.knownForDepartment,
      'profile_path': instance.profilePath,
      'gender': instance.gender,
      'gender_name': instance.genderName,
    };

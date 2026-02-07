// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'film_images_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FilmImagesResponse _$FilmImagesResponseFromJson(Map<String, dynamic> json) =>
    FilmImagesResponse(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : FilmImagesData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FilmImagesResponseToJson(FilmImagesResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

FilmImagesData _$FilmImagesDataFromJson(Map<String, dynamic> json) =>
    FilmImagesData(
      imageSizes: json['image_sizes'] == null
          ? null
          : ImageSizes.fromJson(json['image_sizes'] as Map<String, dynamic>),
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => FilmImage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FilmImagesDataToJson(FilmImagesData instance) =>
    <String, dynamic>{
      'image_sizes': instance.imageSizes,
      'images': instance.images,
    };

ImageSizes _$ImageSizesFromJson(Map<String, dynamic> json) => ImageSizes(
  backdrop: json['backdrop'] == null
      ? null
      : BackdropSizes.fromJson(json['backdrop'] as Map<String, dynamic>),
  poster: json['poster'] == null
      ? null
      : PosterSizes.fromJson(json['poster'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ImageSizesToJson(ImageSizes instance) =>
    <String, dynamic>{'backdrop': instance.backdrop, 'poster': instance.poster};

BackdropSizes _$BackdropSizesFromJson(Map<String, dynamic> json) =>
    BackdropSizes(
      original: json['original'] as String?,
      w1280: json['w1280'] as String?,
      w780: json['w780'] as String?,
      w300: json['w300'] as String?,
    );

Map<String, dynamic> _$BackdropSizesToJson(BackdropSizes instance) =>
    <String, dynamic>{
      'original': instance.original,
      'w1280': instance.w1280,
      'w780': instance.w780,
      'w300': instance.w300,
    };

PosterSizes _$PosterSizesFromJson(Map<String, dynamic> json) => PosterSizes(
  original: json['original'] as String?,
  w780: json['w780'] as String?,
  w500: json['w500'] as String?,
  w342: json['w342'] as String?,
  w185: json['w185'] as String?,
  w154: json['w154'] as String?,
  w92: json['w92'] as String?,
);

Map<String, dynamic> _$PosterSizesToJson(PosterSizes instance) =>
    <String, dynamic>{
      'original': instance.original,
      'w780': instance.w780,
      'w500': instance.w500,
      'w342': instance.w342,
      'w185': instance.w185,
      'w154': instance.w154,
      'w92': instance.w92,
    };

FilmImage _$FilmImageFromJson(Map<String, dynamic> json) => FilmImage(
  width: (json['width'] as num?)?.toInt(),
  height: (json['height'] as num?)?.toInt(),
  aspectRatio: (json['aspect_ratio'] as num?)?.toDouble(),
  type: json['type'] as String?,
  filePath: json['file_path'] as String?,
  iso6391: json['iso_639_1'] as String?,
);

Map<String, dynamic> _$FilmImageToJson(FilmImage instance) => <String, dynamic>{
  'width': instance.width,
  'height': instance.height,
  'aspect_ratio': instance.aspectRatio,
  'type': instance.type,
  'file_path': instance.filePath,
  'iso_639_1': instance.iso6391,
};

import 'package:json_annotation/json_annotation.dart';

part 'film_images_response.g.dart';

@JsonSerializable()
class FilmImagesResponse {
  final bool? success;
  final String? message;
  final FilmImagesData? data;

  const FilmImagesResponse({this.success, this.message, this.data});

  factory FilmImagesResponse.fromJson(Map<String, dynamic> json) =>
      _$FilmImagesResponseFromJson(json);
  Map<String, dynamic> toJson() => _$FilmImagesResponseToJson(this);
}

@JsonSerializable()
class FilmImagesData {
  @JsonKey(name: 'image_sizes')
  final ImageSizes? imageSizes;
  final List<FilmImage>? images;

  const FilmImagesData({this.imageSizes, this.images});

  factory FilmImagesData.fromJson(Map<String, dynamic> json) =>
      _$FilmImagesDataFromJson(json);
  Map<String, dynamic> toJson() => _$FilmImagesDataToJson(this);
}

@JsonSerializable()
class ImageSizes {
  final BackdropSizes? backdrop;
  final PosterSizes? poster;

  const ImageSizes({this.backdrop, this.poster});

  factory ImageSizes.fromJson(Map<String, dynamic> json) =>
      _$ImageSizesFromJson(json);
  Map<String, dynamic> toJson() => _$ImageSizesToJson(this);
}

@JsonSerializable()
class BackdropSizes {
  final String? original;
  final String? w1280;
  final String? w780;
  final String? w300;

  const BackdropSizes({this.original, this.w1280, this.w780, this.w300});

  factory BackdropSizes.fromJson(Map<String, dynamic> json) =>
      _$BackdropSizesFromJson(json);
  Map<String, dynamic> toJson() => _$BackdropSizesToJson(this);
}

@JsonSerializable()
class PosterSizes {
  final String? original;
  final String? w780;
  final String? w500;
  final String? w342;
  final String? w185;
  final String? w154;
  final String? w92;

  const PosterSizes({
    this.original,
    this.w780,
    this.w500,
    this.w342,
    this.w185,
    this.w154,
    this.w92,
  });

  factory PosterSizes.fromJson(Map<String, dynamic> json) =>
      _$PosterSizesFromJson(json);
  Map<String, dynamic> toJson() => _$PosterSizesToJson(this);
}

@JsonSerializable()
class FilmImage {
  final int? width;
  final int? height;
  @JsonKey(name: 'aspect_ratio')
  final double? aspectRatio;
  final String? type;
  @JsonKey(name: 'file_path')
  final String? filePath;
  @JsonKey(name: 'iso_639_1')
  final String? iso6391;

  const FilmImage({
    this.width,
    this.height,
    this.aspectRatio,
    this.type,
    this.filePath,
    this.iso6391,
  });

  factory FilmImage.fromJson(Map<String, dynamic> json) =>
      _$FilmImageFromJson(json);
  Map<String, dynamic> toJson() => _$FilmImageToJson(this);
}

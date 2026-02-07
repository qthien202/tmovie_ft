import 'package:json_annotation/json_annotation.dart';

part 'server_data.g.dart';

@JsonSerializable()
class ServerData {
  final String? name;
  final String? slug;
  final String? filename;
  @JsonKey(name: 'link_embed')
  final String? linkEmbed;
  @JsonKey(name: 'link_m3u8')
  final String? linkM3u8;

  const ServerData({
    this.name,
    this.slug,
    this.filename,
    this.linkEmbed,
    this.linkM3u8,
  });

  factory ServerData.fromJson(Map<String, dynamic> json) => _$ServerDataFromJson(json);
  Map<String, dynamic> toJson() => _$ServerDataToJson(this);
}

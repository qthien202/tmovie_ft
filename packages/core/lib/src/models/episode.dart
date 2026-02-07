import 'package:json_annotation/json_annotation.dart';
import 'server_data.dart';

part 'episode.g.dart';

@JsonSerializable()
class Episode {
  @JsonKey(name: 'server_name')
  final String? serverName;
  @JsonKey(name: 'server_data')
  final List<ServerData>? serverData;

  const Episode({this.serverName, this.serverData});

  factory Episode.fromJson(Map<String, dynamic> json) => _$EpisodeFromJson(json);
  Map<String, dynamic> toJson() => _$EpisodeToJson(this);
}

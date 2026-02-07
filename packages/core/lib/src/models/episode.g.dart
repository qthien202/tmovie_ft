// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episode.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Episode _$EpisodeFromJson(Map<String, dynamic> json) => Episode(
  serverName: json['server_name'] as String?,
  serverData: (json['server_data'] as List<dynamic>?)
      ?.map((e) => ServerData.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$EpisodeToJson(Episode instance) => <String, dynamic>{
  'server_name': instance.serverName,
  'server_data': instance.serverData,
};

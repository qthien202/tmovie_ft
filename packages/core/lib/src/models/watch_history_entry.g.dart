// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_history_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchHistoryEntry _$WatchHistoryEntryFromJson(Map<String, dynamic> json) =>
    WatchHistoryEntry(
      slug: json['slug'] as String,
      name: json['name'] as String,
      originName: json['originName'] as String?,
      thumbUrl: json['thumbUrl'] as String?,
      episode: json['episode'] as String?,
      description: json['description'] as String?,
      timestamp: (json['timestamp'] as num?)?.toInt(),
    );

Map<String, dynamic> _$WatchHistoryEntryToJson(WatchHistoryEntry instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'name': instance.name,
      'originName': instance.originName,
      'thumbUrl': instance.thumbUrl,
      'episode': instance.episode,
      'description': instance.description,
      'timestamp': instance.timestamp,
    };

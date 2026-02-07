import 'package:json_annotation/json_annotation.dart';

part 'watch_history_entry.g.dart';

@JsonSerializable()
class WatchHistoryEntry {
  final String slug;
  final String name;
  final String? originName;
  final String? thumbUrl;
  final String? episode;
  final String? description;
  final int? timestamp;

  const WatchHistoryEntry({
    required this.slug,
    required this.name,
    this.originName,
    this.thumbUrl,
    this.episode,
    this.description,
    this.timestamp,
  });

  factory WatchHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$WatchHistoryEntryFromJson(json);
  Map<String, dynamic> toJson() => _$WatchHistoryEntryToJson(this);
}

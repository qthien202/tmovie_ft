import '../models/watch_history_entry.dart';

abstract class HistoryRepository {
  Future<List<WatchHistoryEntry>> getHistory();
  Future<void> addHistory(WatchHistoryEntry entry);
  Future<void> savePlaybackPosition(String filmSlug, String episodeSlug, int positionSeconds);
  Future<int?> getPlaybackPosition(String filmSlug, String episodeSlug);
}

import '../models/watch_history_entry.dart';
import 'history_repository.dart';

/// Used while signed out: watch history requires login, so nothing is stored.
class NoopHistoryRepository implements HistoryRepository {
  const NoopHistoryRepository();

  @override
  Future<List<WatchHistoryEntry>> getHistory() async => const [];

  @override
  Future<void> addHistory(WatchHistoryEntry entry) async {}

  @override
  Future<void> savePlaybackPosition(
    String filmSlug,
    String episodeSlug,
    int positionSeconds,
  ) async {}

  @override
  Future<int?> getPlaybackPosition(String filmSlug, String episodeSlug) async =>
      null;

  @override
  Future<void> clearHistory() async {}
}

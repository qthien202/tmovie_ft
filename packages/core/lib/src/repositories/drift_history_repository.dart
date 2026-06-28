import 'dart:convert';

import '../database/app_database.dart';
import '../models/watch_history_entry.dart';
import 'history_repository.dart';

/// Watch history backed by the local Drift database — works offline and stays
/// on the device regardless of sign-in state.
class DriftHistoryRepository implements HistoryRepository {
  final AppDatabase _db;
  DriftHistoryRepository(this._db);

  /// Cap so history can't grow without bound.
  static const _maxEntries = 100;

  @override
  Future<List<WatchHistoryEntry>> getHistory() async {
    final rows = await _db.getWatchHistory();
    return rows
        .map(
          (r) => WatchHistoryEntry.fromJson(
            json.decode(r.json) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  @override
  Future<void> addHistory(WatchHistoryEntry entry) async {
    final watchedAt = entry.timestamp ?? DateTime.now().millisecondsSinceEpoch;
    await _db.upsertWatchHistory(
      WatchHistoriesCompanion.insert(
        slug: entry.slug,
        json: json.encode(entry.toJson()),
        watchedAt: watchedAt,
      ),
    );
    await _db.trimWatchHistory(_maxEntries);
  }

  @override
  Future<void> savePlaybackPosition(
    String filmSlug,
    String episodeSlug,
    int positionSeconds,
  ) async {
    await _db.upsertPlayback(
      PlaybackPositionsCompanion.insert(
        id: '${filmSlug}_$episodeSlug',
        positionSeconds: positionSeconds,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<int?> getPlaybackPosition(String filmSlug, String episodeSlug) async {
    final row = await _db.getPlayback('${filmSlug}_$episodeSlug');
    return row?.positionSeconds;
  }

  @override
  Future<void> clearHistory() => _db.clearWatchHistory();
}

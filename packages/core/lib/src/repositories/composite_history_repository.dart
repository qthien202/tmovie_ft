import '../models/watch_history_entry.dart';
import 'history_repository.dart';

/// Watch history that is saved **both** locally (offline-first) and remotely
/// (cross-device sync) at the same time.
///
/// * [local] (Drift) is always written and is the source read offline.
/// * [remote] (Firestore) is present only while signed in. Remote writes are
///   best-effort — a network failure never blocks the local write.
/// * Reads merge remote into local (newest timestamp wins) so a freshly
///   signed-in device pulls history from the cloud, then keeps working offline.
class CompositeHistoryRepository implements HistoryRepository {
  final HistoryRepository local;
  final HistoryRepository? remote;

  CompositeHistoryRepository({required this.local, this.remote});

  @override
  Future<void> addHistory(WatchHistoryEntry entry) async {
    await local.addHistory(entry);
    final r = remote;
    if (r != null) {
      try {
        await r.addHistory(entry);
      } catch (_) {
        // Best-effort sync; local already has it.
      }
    }
  }

  @override
  Future<void> savePlaybackPosition(
    String filmSlug,
    String episodeSlug,
    int positionSeconds,
  ) async {
    await local.savePlaybackPosition(filmSlug, episodeSlug, positionSeconds);
    final r = remote;
    if (r != null) {
      try {
        await r.savePlaybackPosition(filmSlug, episodeSlug, positionSeconds);
      } catch (_) {}
    }
  }

  @override
  Future<int?> getPlaybackPosition(String filmSlug, String episodeSlug) async {
    final localPos = await local.getPlaybackPosition(filmSlug, episodeSlug);
    if (localPos != null && localPos > 0) return localPos;
    final r = remote;
    if (r != null) {
      try {
        final remotePos = await r.getPlaybackPosition(filmSlug, episodeSlug);
        if (remotePos != null && remotePos > 0) {
          // Cache for offline use next time.
          await local.savePlaybackPosition(filmSlug, episodeSlug, remotePos);
          return remotePos;
        }
      } catch (_) {}
    }
    return localPos;
  }

  @override
  Future<List<WatchHistoryEntry>> getHistory() async {
    final localList = await local.getHistory();
    final r = remote;
    if (r == null) return localList;

    try {
      final remoteList = await r.getHistory();

      // Merge by slug; the most recently watched copy wins.
      final bySlug = <String, WatchHistoryEntry>{};
      for (final e in [...localList, ...remoteList]) {
        final existing = bySlug[e.slug];
        if (existing == null ||
            (e.timestamp ?? 0) > (existing.timestamp ?? 0)) {
          bySlug[e.slug] = e;
        }
      }
      final merged = bySlug.values.toList()
        ..sort((a, b) => (b.timestamp ?? 0).compareTo(a.timestamp ?? 0));

      // Two-way reconcile (idempotent — only touches what's missing on a side):
      //  * remote-only entries get pulled down into the local DB;
      //  * local-only entries get pushed up to Firestore, so history that was
      //    saved locally while offline / signed out / against the wrong project
      //    still reaches the cloud the next time this screen loads.
      final localSlugs = localList.map((e) => e.slug).toSet();
      final remoteSlugs = remoteList.map((e) => e.slug).toSet();
      for (final e in merged) {
        if (!localSlugs.contains(e.slug)) {
          await local.addHistory(e);
        }
        if (!remoteSlugs.contains(e.slug)) {
          try {
            await r.addHistory(e);
          } catch (_) {}
        }
      }
      return merged;
    } catch (_) {
      return localList;
    }
  }

  @override
  Future<void> clearHistory() async {
    await local.clearHistory();
    final r = remote;
    if (r != null) {
      try {
        await r.clearHistory();
      } catch (_) {}
    }
  }
}

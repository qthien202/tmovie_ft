import '../models/watch_history_entry.dart';
import 'favorites_repository.dart';

/// Favourites saved **both** locally (offline-first) and remotely (cross-device
/// sync). Local is always written; remote (Firestore) writes are best-effort.
/// Reads merge remote into local so a freshly signed-in device pulls favourites
/// from the cloud, then keeps working offline.
class CompositeFavoritesRepository implements FavoritesRepository {
  final FavoritesRepository local;
  final FavoritesRepository? remote;

  CompositeFavoritesRepository({required this.local, this.remote});

  @override
  Future<void> addFavorite(WatchHistoryEntry entry) async {
    await local.addFavorite(entry);
    final r = remote;
    if (r != null) {
      try {
        await r.addFavorite(entry);
      } catch (_) {}
    }
  }

  @override
  Future<void> removeFavorite(String slug) async {
    await local.removeFavorite(slug);
    final r = remote;
    if (r != null) {
      try {
        await r.removeFavorite(slug);
      } catch (_) {}
    }
  }

  @override
  Future<bool> isFavorite(String slug) async {
    if (await local.isFavorite(slug)) return true;
    final r = remote;
    if (r != null) {
      try {
        return await r.isFavorite(slug);
      } catch (_) {}
    }
    return false;
  }

  @override
  Future<List<WatchHistoryEntry>> getFavorites() async {
    final localList = await local.getFavorites();
    final r = remote;
    if (r == null) return localList;

    try {
      final remoteList = await r.getFavorites();

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

      // Pull remote-only favourites into the local DB.
      final localSlugs = localList.map((e) => e.slug).toSet();
      for (final e in merged) {
        if (!localSlugs.contains(e.slug)) {
          await local.addFavorite(e);
        }
      }
      return merged;
    } catch (_) {
      return localList;
    }
  }

  @override
  Future<void> clearFavorites() async {
    await local.clearFavorites();
    final r = remote;
    if (r != null) {
      try {
        await r.clearFavorites();
      } catch (_) {}
    }
  }
}

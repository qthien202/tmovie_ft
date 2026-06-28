import 'dart:convert';

import '../database/app_database.dart';
import '../models/watch_history_entry.dart';
import 'favorites_repository.dart';

/// Favourites backed by the local Drift database — offline-first.
class DriftFavoritesRepository implements FavoritesRepository {
  final AppDatabase _db;
  DriftFavoritesRepository(this._db);

  @override
  Future<List<WatchHistoryEntry>> getFavorites() async {
    final rows = await _db.getFavorites();
    return rows
        .map(
          (r) => WatchHistoryEntry.fromJson(
            json.decode(r.json) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  @override
  Future<void> addFavorite(WatchHistoryEntry entry) async {
    await _db.upsertFavorite(
      FavoritesCompanion.insert(
        slug: entry.slug,
        json: json.encode(entry.toJson()),
        addedAt: entry.timestamp ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<void> removeFavorite(String slug) => _db.deleteFavorite(slug);

  @override
  Future<bool> isFavorite(String slug) => _db.favoriteExists(slug);

  @override
  Future<void> clearFavorites() => _db.clearFavorites();
}

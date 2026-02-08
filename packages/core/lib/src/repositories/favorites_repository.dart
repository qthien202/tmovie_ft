import '../models/watch_history_entry.dart';

abstract class FavoritesRepository {
  Future<List<WatchHistoryEntry>> getFavorites();
  Future<void> addFavorite(WatchHistoryEntry entry);
  Future<void> removeFavorite(String slug);
  Future<bool> isFavorite(String slug);
  Future<void> clearFavorites();
}

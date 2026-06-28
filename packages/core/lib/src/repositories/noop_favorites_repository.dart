import '../models/watch_history_entry.dart';
import 'favorites_repository.dart';

/// Used while signed out: favourites require login, so nothing is stored.
class NoopFavoritesRepository implements FavoritesRepository {
  const NoopFavoritesRepository();

  @override
  Future<List<WatchHistoryEntry>> getFavorites() async => const [];

  @override
  Future<void> addFavorite(WatchHistoryEntry entry) async {}

  @override
  Future<void> removeFavorite(String slug) async {}

  @override
  Future<bool> isFavorite(String slug) async => false;

  @override
  Future<void> clearFavorites() async {}
}

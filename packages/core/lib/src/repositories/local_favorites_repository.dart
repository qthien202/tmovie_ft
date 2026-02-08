import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/watch_history_entry.dart';
import 'favorites_repository.dart';

class LocalFavoritesRepository implements FavoritesRepository {
  static const _favoritesKey = 'favorites';

  @override
  Future<List<WatchHistoryEntry>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_favoritesKey) ?? [];
    return jsonList
        .map(
          (e) => WatchHistoryEntry.fromJson(
            json.decode(e) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  @override
  Future<void> addFavorite(WatchHistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_favoritesKey) ?? [];
    jsonList.removeWhere((e) {
      final map = json.decode(e) as Map<String, dynamic>;
      return map['slug'] == entry.slug;
    });
    jsonList.insert(0, json.encode(entry.toJson()));
    await prefs.setStringList(_favoritesKey, jsonList);
  }

  @override
  Future<void> removeFavorite(String slug) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_favoritesKey) ?? [];
    jsonList.removeWhere((e) {
      final map = json.decode(e) as Map<String, dynamic>;
      return map['slug'] == slug;
    });
    await prefs.setStringList(_favoritesKey, jsonList);
  }

  @override
  Future<bool> isFavorite(String slug) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_favoritesKey) ?? [];
    return jsonList.any((e) {
      final map = json.decode(e) as Map<String, dynamic>;
      return map['slug'] == slug;
    });
  }

  @override
  Future<void> clearFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favoritesKey);
  }
}

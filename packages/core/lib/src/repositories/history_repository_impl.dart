import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/watch_history_entry.dart';
import 'history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  static const _historyKey = 'watch_history';
  static const _positionPrefix = 'playback_pos_';

  @override
  Future<List<WatchHistoryEntry>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_historyKey) ?? [];
    return jsonList
        .map((e) => WatchHistoryEntry.fromJson(json.decode(e) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> addHistory(WatchHistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_historyKey) ?? [];
    jsonList.removeWhere((e) {
      final map = json.decode(e) as Map<String, dynamic>;
      return map['slug'] == entry.slug;
    });
    jsonList.insert(0, json.encode(entry.toJson()));
    if (jsonList.length > 50) {
      jsonList.removeRange(50, jsonList.length);
    }
    await prefs.setStringList(_historyKey, jsonList);
  }

  @override
  Future<void> savePlaybackPosition(String filmSlug, String episodeSlug, int positionSeconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_positionPrefix${filmSlug}_$episodeSlug', positionSeconds);
  }

  @override
  Future<int?> getPlaybackPosition(String filmSlug, String episodeSlug) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_positionPrefix${filmSlug}_$episodeSlug');
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';

final favoritesProvider =
    FutureProvider.autoDispose<List<WatchHistoryEntry>>((ref) {
  final repo = ref.watch(favoritesRepositoryProvider);
  return repo.getFavorites();
});

final isFavoriteProvider =
    FutureProvider.family.autoDispose<bool, String>((ref, slug) {
  final repo = ref.watch(favoritesRepositoryProvider);
  return repo.isFavorite(slug);
});

final watchHistoryProvider =
    FutureProvider.autoDispose<List<WatchHistoryEntry>>((ref) {
  final repo = ref.watch(historyRepositoryProvider);
  return repo.getHistory();
});

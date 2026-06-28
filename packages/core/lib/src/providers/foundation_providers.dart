import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../network/dio_provider.dart';
import '../network/api_service.dart';
import '../network/tmdb_service.dart';
import '../network/trakt_service.dart';
import '../repositories/film_repository.dart';
import '../repositories/film_repository_impl.dart';
import '../repositories/history_repository.dart';
import '../repositories/drift_history_repository.dart';
import '../repositories/composite_history_repository.dart';
import '../repositories/firestore_history_repository.dart';
import '../repositories/noop_history_repository.dart';
import '../repositories/favorites_repository.dart';
import '../repositories/drift_favorites_repository.dart';
import '../repositories/composite_favorites_repository.dart';
import '../repositories/firestore_favorites_repository.dart';
import '../repositories/noop_favorites_repository.dart';
import '../repositories/hero_repository.dart';
import '../services/auth_service.dart';
import '../services/shared_cache_service.dart';

// --- Foundation singletons shared by every feature package ---

final dioProvider = Provider<Dio>((ref) => createDio());

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(dioProvider));
});

/// Local Drift database — source of truth for the catalog (offline-first).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Shared (cross-device) Firestore cache tier in front of OPhim.
final sharedCacheServiceProvider = Provider<SharedCacheService>((ref) {
  return SharedCacheService();
});

final filmRepositoryProvider = Provider<FilmRepository>((ref) {
  return FilmRepositoryImpl(
    ref.watch(apiServiceProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(sharedCacheServiceProvider),
  );
});

/// Builds & caches the home hero list (local → Firestore → OPhim, once/day).
final heroRepositoryProvider = Provider<HeroRepository>((ref) {
  return HeroRepository(
    ref.watch(filmRepositoryProvider),
    ref.watch(traktServiceProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(sharedCacheServiceProvider),
  );
});

final tmdbServiceProvider = Provider<TmdbService>((ref) {
  return TmdbService(ref.watch(dioProvider));
});

/// Trakt.tv — currently-hot titles (watched right now) for the home hero.
final traktServiceProvider = Provider<TraktService>((ref) {
  return TraktService(ref.watch(dioProvider));
});

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Watch history requires sign-in. When signed in it is saved both locally
/// (Drift, offline-first) and remotely (Firestore) so it survives offline AND
/// syncs across devices. Signed out, nothing is stored.
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const NoopHistoryRepository();
  return CompositeHistoryRepository(
    local: DriftHistoryRepository(ref.watch(appDatabaseProvider)),
    remote: FirestoreHistoryRepository(user.uid),
  );
});

/// Favourites require sign-in. Signed in → saved locally (Drift) AND remotely
/// (Firestore) for cross-device sync. Signed out, nothing is stored.
final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const NoopFavoritesRepository();
  return CompositeFavoritesRepository(
    local: DriftFavoritesRepository(ref.watch(appDatabaseProvider)),
    remote: FirestoreFavoritesRepository(user.uid),
  );
});

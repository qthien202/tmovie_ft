import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_provider.dart';
import '../network/api_service.dart';
import '../network/tmdb_service.dart';
import '../repositories/film_repository.dart';
import '../repositories/film_repository_impl.dart';
import '../repositories/history_repository.dart';
import '../repositories/history_repository_impl.dart';
import '../repositories/favorites_repository.dart';
import '../repositories/local_favorites_repository.dart';
import '../repositories/firestore_history_repository.dart';
import '../repositories/firestore_favorites_repository.dart';
import '../services/auth_service.dart';

// --- Foundation singletons shared by every feature package ---

final dioProvider = Provider<Dio>((ref) => createDio());

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(dioProvider));
});

final filmRepositoryProvider = Provider<FilmRepository>((ref) {
  return FilmRepositoryImpl(ref.watch(apiServiceProvider));
});

final tmdbServiceProvider = Provider<TmdbService>((ref) {
  return TmdbService(ref.watch(dioProvider));
});

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user != null) return FirestoreHistoryRepository(user.uid);
  return HistoryRepositoryImpl();
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user != null) return FirestoreFavoritesRepository(user.uid);
  return LocalFavoritesRepository();
});

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_provider.dart';
import '../network/api_service.dart';
import '../repositories/film_repository.dart';
import '../repositories/film_repository_impl.dart';
import '../repositories/history_repository.dart';
import '../repositories/history_repository_impl.dart';
import '../models/film_list_response.dart';
import '../models/film_detail_response.dart';

// --- Singleton providers ---

final dioProvider = Provider<Dio>((ref) => createDio());

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(dioProvider));
});

final filmRepositoryProvider = Provider<FilmRepository>((ref) {
  return FilmRepositoryImpl(ref.watch(apiServiceProvider));
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepositoryImpl();
});

// --- Data providers ---

final filmsByTypeProvider =
    FutureProvider.family.autoDispose<FilmListResponse, ({String typeSlug, int page})>(
  (ref, params) {
    final repo = ref.watch(filmRepositoryProvider);
    return repo.getFilmsByType(params.typeSlug, page: params.page);
  },
);

final filmDetailProvider =
    FutureProvider.family.autoDispose<FilmDetailResponse, String>(
  (ref, slug) {
    final repo = ref.watch(filmRepositoryProvider);
    return repo.getFilmDetail(slug);
  },
);

final searchFilmsProvider =
    FutureProvider.family.autoDispose<FilmListResponse, ({String keyword, int page})>(
  (ref, params) {
    final repo = ref.watch(filmRepositoryProvider);
    return repo.searchFilms(params.keyword, page: params.page);
  },
);

final filmsByGenreProvider =
    FutureProvider.family.autoDispose<FilmListResponse, ({String slug, int page})>(
  (ref, params) {
    final repo = ref.watch(filmRepositoryProvider);
    return repo.getFilmsByGenre(params.slug, page: params.page);
  },
);

final filmsByCountryProvider =
    FutureProvider.family.autoDispose<FilmListResponse, ({String slug, int page})>(
  (ref, params) {
    final repo = ref.watch(filmRepositoryProvider);
    return repo.getFilmsByCountry(params.slug, page: params.page);
  },
);

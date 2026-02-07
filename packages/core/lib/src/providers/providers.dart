import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_provider.dart';
import '../network/api_service.dart';
import '../repositories/film_repository.dart';
import '../repositories/film_repository_impl.dart';
import '../repositories/history_repository.dart';
import '../repositories/history_repository_impl.dart';
import '../models/film_list_response.dart';
import '../models/film_item.dart';
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

final filmsByTypeProvider = FutureProvider.family
    .autoDispose<FilmListResponse, ({String typeSlug, int page})>((
      ref,
      params,
    ) {
      final repo = ref.watch(filmRepositoryProvider);
      return repo.getFilmsByType(params.typeSlug, page: params.page);
    });

final filmDetailProvider = FutureProvider.family
    .autoDispose<FilmDetailResponse, String>((ref, slug) {
      final repo = ref.watch(filmRepositoryProvider);
      return repo.getFilmDetail(slug);
    });

final searchFilmsProvider = FutureProvider.family
    .autoDispose<FilmListResponse, ({String keyword, int page})>((ref, params) {
      final repo = ref.watch(filmRepositoryProvider);
      return repo.searchFilms(params.keyword, page: params.page);
    });

final filmsByGenreProvider = FutureProvider.family
    .autoDispose<FilmListResponse, ({String slug, int page})>((ref, params) {
      final repo = ref.watch(filmRepositoryProvider);
      return repo.getFilmsByGenre(params.slug, page: params.page);
    });

final filmsByCountryProvider = FutureProvider.family
    .autoDispose<FilmListResponse, ({String slug, int page})>((ref, params) {
      final repo = ref.watch(filmRepositoryProvider);
      return repo.getFilmsByCountry(params.slug, page: params.page);
    });

// --- Paginated Notifier ---

class FilmListState {
  final List<FilmItem> items;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final Object? error;

  FilmListState({
    required this.items,
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  FilmListState copyWith({
    List<FilmItem>? items,
    bool? isLoading,
    bool? hasMore,
    int? page,
    Object? error,
  }) {
    return FilmListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error,
    );
  }
}

class FilmListNotifier extends StateNotifier<FilmListState> {
  final FilmRepository _repository;
  final String _typeSlug;

  FilmListNotifier(this._repository, this._typeSlug)
    : super(FilmListState(items: [])) {
    loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, page: 1, items: []);
    try {
      final response = await _repository.getFilmsByType(_typeSlug, page: 1);
      final items = response.data?.items ?? [];
      state = state.copyWith(
        items: items,
        isLoading: false,
        hasMore: items.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.page + 1;
      final response = await _repository.getFilmsByType(
        _typeSlug,
        page: nextPage,
      );
      final newItems = response.data?.items ?? [];
      if (newItems.isEmpty) {
        state = state.copyWith(isLoading: false, hasMore: false);
      } else {
        state = state.copyWith(
          items: [...state.items, ...newItems],
          isLoading: false,
          page: nextPage,
          hasMore: true,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }
}

final paginatedFilmsProvider = StateNotifierProvider.family
    .autoDispose<FilmListNotifier, FilmListState, String>((ref, typeSlug) {
      final repo = ref.watch(filmRepositoryProvider);
      return FilmListNotifier(repo, typeSlug);
    });

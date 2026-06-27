import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';

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

enum PaginatedSource { type, genre, country, search }

class FilmFilterParams {
  final String slug;
  final PaginatedSource source;
  final String? category;
  final String? country;
  final int? year;
  final String? sortField;

  const FilmFilterParams({
    required this.slug,
    required this.source,
    this.category,
    this.country,
    this.year,
    this.sortField,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilmFilterParams &&
          slug == other.slug &&
          source == other.source &&
          category == other.category &&
          country == other.country &&
          year == other.year &&
          sortField == other.sortField;

  @override
  int get hashCode =>
      Object.hash(slug, source, category, country, year, sortField);
}

class FilmListNotifier extends StateNotifier<FilmListState> {
  final FilmRepository _repository;
  final FilmFilterParams _params;

  FilmListNotifier(this._repository, this._params)
    : super(FilmListState(items: [])) {
    loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, page: 1, items: []);
    try {
      final response = await _fetchData(1);
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
      final response = await _fetchData(nextPage);
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

  Future<FilmListResponse> _fetchData(int page) {
    switch (_params.source) {
      case PaginatedSource.type:
        return _repository.getFilmsByType(
          _params.slug,
          page: page,
          category: _params.category,
          country: _params.country,
          year: _params.year,
          sortField: _params.sortField,
        );
      case PaginatedSource.genre:
        return _repository.getFilmsByGenre(
          _params.slug,
          page: page,
          country: _params.country,
          year: _params.year,
          sortField: _params.sortField,
        );
      case PaginatedSource.country:
        return _repository.getFilmsByCountry(
          _params.slug,
          page: page,
          category: _params.category,
          year: _params.year,
          sortField: _params.sortField,
        );
      case PaginatedSource.search:
        return _repository.searchFilms(_params.slug, page: page);
    }
  }
}

final paginatedFilmsProvider = StateNotifierProvider.family
    .autoDispose<FilmListNotifier, FilmListState, FilmFilterParams>((
      ref,
      params,
    ) {
      final repo = ref.watch(filmRepositoryProvider);
      return FilmListNotifier(repo, params);
    });

final paginatedSearchFilmsProvider = StateNotifierProvider.family
    .autoDispose<FilmListNotifier, FilmListState, String>((ref, keyword) {
      final repo = ref.watch(filmRepositoryProvider);
      return FilmListNotifier(
        repo,
        FilmFilterParams(slug: keyword, source: PaginatedSource.search),
      );
    });

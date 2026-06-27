import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';

final filmDetailProvider = FutureProvider.family
    .autoDispose<FilmDetailResponse, String>((ref, slug) {
      final repo = ref.watch(filmRepositoryProvider);
      return repo.getFilmDetail(slug);
    });

final filmPeoplesProvider = FutureProvider.family
    .autoDispose<FilmPeopleResponse, String>((ref, slug) {
      final repo = ref.watch(filmRepositoryProvider);
      return repo.getFilmPeoples(slug);
    });

final filmImagesProvider = FutureProvider.family
    .autoDispose<FilmImagesResponse, String>((ref, slug) {
      final repo = ref.watch(filmRepositoryProvider);
      return repo.getFilmImages(slug);
    });

final tmdbSeasonProvider = FutureProvider.family
    .autoDispose<TmdbSeasonResponse, ({String tmdbId, int season})>((ref, params) {
      final service = ref.watch(tmdbServiceProvider);
      return service.getSeasonDetails(
        tmdbId: params.tmdbId,
        seasonNumber: params.season,
      );
    });

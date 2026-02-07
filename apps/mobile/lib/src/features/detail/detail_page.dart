import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import 'widgets/film_info.dart';
import 'widgets/episode_selector.dart';

class DetailPage extends ConsumerWidget {
  final String slug;
  final String? name;

  const DetailPage({super.key, required this.slug, this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(filmDetailProvider(slug));

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: detailAsync.when(
        data: (response) {
          final film = response.data?.item;
          if (film == null) {
            return const Center(
              child: Text('Không tìm thấy phim', style: TextStyle(color: Colors.white)),
            );
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.backgroundColor,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppImage(
                        imageUrl: film.fullPosterUrl.isNotEmpty
                            ? film.fullPosterUrl
                            : film.fullThumbUrl,
                        boxFit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.backgroundColor,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FilmInfo(film: film),
              ),
              if (film.episodes != null && film.episodes!.isNotEmpty)
                SliverToBoxAdapter(
                  child: EpisodeSelector(
                    episodes: film.episodes!,
                    filmName: film.name ?? '',
                    slug: film.slug ?? '',
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Có lỗi xảy ra', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(filmDetailProvider(slug)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

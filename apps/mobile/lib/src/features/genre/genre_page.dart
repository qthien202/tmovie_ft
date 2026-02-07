import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

class GenrePage extends ConsumerStatefulWidget {
  final String slug;
  final String title;

  const GenrePage({
    super.key,
    required this.slug,
    required this.title,
  });

  @override
  ConsumerState<GenrePage> createState() => _GenrePageState();
}

class _GenrePageState extends ConsumerState<GenrePage> {
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    final filmsAsync = ref.watch(
      filmsByGenreProvider((slug: widget.slug, page: _currentPage)),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        title: Text(
          widget.title.isNotEmpty ? widget.title : widget.slug,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: filmsAsync.when(
        data: (response) {
          final items = response.data?.items ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text('Không có phim', style: TextStyle(color: Colors.white)),
            );
          }
          final pagination = response.data?.params?.pagination;
          final totalPages = pagination?.totalPages ?? 1;

          return Column(
            children: [
              Expanded(
                child: FilmGrid(
                  films: items,
                  onFilmTap: (film) => context.push('/detail/${film.slug}'),
                ),
              ),
              if (totalPages > 1)
                PaginationBar(
                  currentPage: _currentPage,
                  totalPages: totalPages,
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                  },
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
                onPressed: () => ref.invalidate(
                  filmsByGenreProvider((slug: widget.slug, page: _currentPage)),
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

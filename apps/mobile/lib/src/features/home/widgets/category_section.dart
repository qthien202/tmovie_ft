import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

class CategorySection extends ConsumerWidget {
  final String title;
  final String genreSlug;

  const CategorySection({
    super.key,
    required this.title,
    required this.genreSlug,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filmsAsync = ref.watch(
      filmsByGenreProvider((slug: genreSlug, page: 1)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/genre/$genreSlug?title=$title'),
                child: Text('Xem thêm', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        filmsAsync.when(
          data: (response) {
            final items = response.data?.items ?? [];
            return SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: items.take(10).length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final film = items[index];
                  return SizedBox(
                    width: 120,
                    child: FilmCard(
                      film: film,
                      onTap: () => context.push('/detail/${film.slug}'),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const SizedBox(height: 220),
        ),
      ],
    );
  }
}

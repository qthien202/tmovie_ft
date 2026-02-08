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

    return Container(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push('/genre/$genreSlug?title=$title'),
                  child: Text(
                    'Tất cả',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          filmsAsync.when(
            data: (response) {
              final items = response.data?.items ?? [];
              return SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.take(10).length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final film = items[index];
                    return SizedBox(
                      width: 145,
                      child: FilmCard(
                        film: film,
                        onTap: () => context.push('/detail/${film.slug}'),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const FilmSectionSkeleton(),
            error: (_, _) => const SizedBox(height: 220),
          ),
        ],
      ),
    );
  }
}

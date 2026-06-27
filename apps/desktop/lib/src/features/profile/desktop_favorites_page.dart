import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import 'package:media_library/media_library.dart';
import '../../shared/desktop_design_system.dart';
import '../../shared/widgets/desktop_film_card.dart';

class DesktopFavoritesPage extends ConsumerWidget {
  const DesktopFavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yêu thích',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: favoritesAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return _buildEmpty();
                }
                final items = entries
                    .map((e) => FilmItem(
                          slug: e.slug,
                          name: e.name,
                          originName: e.originName,
                          thumbUrl: e.thumbUrl,
                        ))
                    .toList();
                return GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: DS.cardAspectRatio * 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return DesktopFilmCard(
                      film: items[index],
                      onTap: () =>
                          context.push('/detail/${items[index].slug}'),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: DS.primary),
              ),
              error: (_, _) => const Center(
                child: Text('Lỗi tải dữ liệu',
                    style: TextStyle(color: DS.textMuted)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded,
              size: 64, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            'Chưa có phim yêu thích',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

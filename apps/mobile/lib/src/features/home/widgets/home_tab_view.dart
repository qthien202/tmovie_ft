import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

class FilmTypeTab extends ConsumerStatefulWidget {
  final String typeSlug;
  const FilmTypeTab({super.key, required this.typeSlug});

  @override
  ConsumerState<FilmTypeTab> createState() => _FilmTypeTabState();
}

class _FilmTypeTabState extends ConsumerState<FilmTypeTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Nếu là tab "Mới nhất", hiển thị giao diện Dashboard kiểu Netflix
    if (widget.typeSlug == 'phim-moi-cap-nhat') {
      return const NetflixDashboard();
    }

    // Các tab khác hiển thị dạng Grid có Infinite Scroll
    return PaginatedGridView(typeSlug: widget.typeSlug);
  }
}

class NetflixDashboard extends ConsumerWidget {
  const NetflixDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FilmSection(title: 'MỚI CẬP NHẬT', slug: 'phim-moi-cap-nhat'),
        const FilmSection(
          title: 'PHIM HÀNH ĐỘNG',
          slug: 'hanh-dong',
          isGenre: true,
        ),
        const FilmSection(
          title: 'PHIM TÌNH CẢM',
          slug: 'tinh-cam',
          isGenre: true,
        ),
        const FilmSection(
          title: 'PHIM KINH DỊ',
          slug: 'kinh-di',
          isGenre: true,
        ),
        const FilmSection(title: 'PHIM HOẠT HÌNH', slug: 'hoat-hinh'),
        const SizedBox(height: 100),
      ],
    );
  }
}

class FilmSection extends ConsumerWidget {
  final String title;
  final String slug;
  final bool isGenre;

  const FilmSection({
    super.key,
    required this.title,
    required this.slug,
    this.isGenre = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filmsAsync = ref.watch(
      isGenre
          ? filmsByGenreProvider((slug: slug, page: 1))
          : filmsByTypeProvider((typeSlug: slug, page: 1, sortField: null, year: null)),
    );

    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                  onTap: () => context.push('/film-list/$slug?title=$title'),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.4),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: filmsAsync.when(
              data: (res) {
                final items = res.data?.items ?? [];
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 145,
                      child: FilmCard(
                        film: items[index],
                        onTap: () =>
                            context.push('/detail/${items[index].slug}'),
                      ),
                    );
                  },
                );
              },
              loading: () => const FilmSectionSkeleton(),
              error: (e, s) => const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }
}

class PaginatedGridView extends ConsumerWidget {
  final String typeSlug;
  const PaginatedGridView({super.key, required this.typeSlug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filmListState = ref.watch(
      paginatedFilmsProvider(
        FilmFilterParams(slug: typeSlug, source: PaginatedSource.type),
      ),
    );

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 400) {
            ref
                .read(
                  paginatedFilmsProvider(
                    FilmFilterParams(
                      slug: typeSlug,
                      source: PaginatedSource.type,
                    ),
                  ).notifier,
                )
                .loadMore();
          }
        }
        return false;
      },
      child: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primaryValue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'DANH SÁCH PHIM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    final title = typeSlug == 'phim-bo'
                        ? 'Phim Bộ'
                        : typeSlug == 'phim-le'
                        ? 'Phim Lẻ'
                        : typeSlug == 'tv-shows'
                        ? 'TV Shows'
                        : 'Danh sách phim';
                    context.push('/film-list/$typeSlug?title=$title');
                  },
                  child: Row(
                    children: [
                      Text(
                        'Xem tất cả',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (filmListState.items.isEmpty && filmListState.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: FilmGridSkeleton(),
            )
          else if (filmListState.error != null && filmListState.items.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Có lỗi xảy ra',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref
                        .read(
                          paginatedFilmsProvider(
                            FilmFilterParams(
                              slug: typeSlug,
                              source: PaginatedSource.type,
                            ),
                          ).notifier,
                        )
                        .loadFirstPage(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          else if (filmListState.items.isEmpty)
            const Center(
              child: Text(
                'Không có phim',
                style: TextStyle(color: Colors.white),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilmGrid(
                films: filmListState.items,
                childAspectRatio: 0.6,
                onFilmTap: (film) => context.push('/detail/${film.slug}'),
              ),
            ),
            if (filmListState.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: FilmGridSkeleton(count: 3),
              ),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

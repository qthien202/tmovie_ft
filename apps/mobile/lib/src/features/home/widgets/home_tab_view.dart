import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:catalog/catalog.dart';

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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppSpacing.md),
        FilmSection(title: 'Mới cập nhật', slug: 'phim-moi-cap-nhat'),
        FilmSection(title: 'Phim hành động', slug: 'hanh-dong', isGenre: true),
        FilmSection(title: 'Phim tình cảm', slug: 'tinh-cam', isGenre: true),
        FilmSection(title: 'Phim kinh dị', slug: 'kinh-di', isGenre: true),
        FilmSection(title: 'Phim hoạt hình', slug: 'hoat-hinh'),
        SizedBox(height: 100),
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
          : filmsByTypeProvider((
              typeSlug: slug,
              page: 1,
              sortField: null,
              year: null,
            )),
    );

    return Container(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: SectionHeader(
              title: title,
              onSeeAll: () => context.push('/film-list/$slug?title=$title'),
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
              loading: () => ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, index) =>
                    const SizedBox(width: 145, child: FilmCardSkeleton()),
              ),
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
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SectionHeader(
              title: 'Danh sách phim',
              seeAllLabel: 'Xem tất cả',
              onSeeAll: () {
                final title = typeSlug == 'phim-bo'
                    ? 'Phim Bộ'
                    : typeSlug == 'phim-le'
                    ? 'Phim Lẻ'
                    : typeSlug == 'tv-shows'
                    ? 'TV Shows'
                    : 'Danh sách phim';
                context.push('/film-list/$typeSlug?title=$title');
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
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
                  Text('Có lỗi xảy ra', style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Thử lại',
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
                  ),
                ],
              ),
            )
          else if (filmListState.items.isEmpty)
            Center(
              child: Text('Không có phim', style: AppTypography.bodyMedium),
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

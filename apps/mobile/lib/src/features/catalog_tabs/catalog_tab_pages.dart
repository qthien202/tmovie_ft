import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:catalog/catalog.dart';
import 'package:core/core.dart';

import '../home/widgets/home_tab_view.dart';

/// Shared header for the content tabs: big title + a search icon (global search)
/// so each tab carries its own search without a dedicated bottom tab.
class _TabHeader extends StatelessWidget {
  final String title;
  const _TabHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTypography.headlineMedium)),
          Material(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () => context.push('/search'),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textPrimary,
                  size: AppSizes.iconMd,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// **Phim bộ** — an editorial *rails* layout (horizontal carousels by country &
/// status), distinct from the Phim lẻ poster grid.
class SeriesTabPage extends StatelessWidget {
  const SeriesTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          children: const [
            _TabHeader(title: 'Phim bộ'),
            FilmSection(title: 'Bộ mới cập nhật', slug: 'phim-bo'),
            FilmSection(title: 'Hàn Quốc', slug: 'han-quoc', isCountry: true),
            FilmSection(title: 'Trung Quốc', slug: 'trung-quoc', isCountry: true),
            FilmSection(title: 'Âu Mỹ', slug: 'au-my', isCountry: true),
            FilmSection(title: 'Đang chiếu', slug: 'phim-bo-dang-chieu'),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

/// **TV Shows** — a single-column landscape-card list, distinct again from the
/// rails (Phim bộ) and the poster grid (Phim lẻ).
class TvShowsTabPage extends ConsumerWidget {
  const TvShowsTabPage({super.key});

  static final _params = FilmFilterParams(
    slug: 'tv-shows',
    source: PaginatedSource.type,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paginatedFilmsProvider(_params));

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            // Guard on maxScrollExtent > 0 so a short, non-scrollable list
            // doesn't fire loadMore during the first frame (which trips a
            // 'debugFrameWasSentToEngine' assertion).
            if (n is ScrollEndNotification &&
                n.metrics.maxScrollExtent > 0 &&
                n.metrics.pixels >= n.metrics.maxScrollExtent - 400) {
              ref.read(paginatedFilmsProvider(_params).notifier).loadMore();
            }
            return false;
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: _TabHeader(title: 'TV Shows')),
              if (state.items.isEmpty && state.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: FilmGridSkeleton(),
                  ),
                )
              else if (state.items.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Center(
                      child: Text(
                        'Không có nội dung',
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                  ),
                )
              else
                SliverList.builder(
                  itemCount: state.items.length,
                  itemBuilder: (context, i) =>
                      _LandscapeCard(film: state.items[i]),
                ),
              if (state.hasMore && state.items.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wide 16:9 card used by the TV Shows list.
class _LandscapeCard extends StatelessWidget {
  final FilmItem film;
  const _LandscapeCard({required this.film});

  @override
  Widget build(BuildContext context) {
    // Fixed height from the screen width (16:9). Avoids AspectRatio/intrinsics,
    // which would probe AppImage's internal LayoutBuilder and assert.
    final cardWidth = MediaQuery.sizeOf(context).width - AppSpacing.lg * 2;
    return GestureDetector(
      onTap: () => context.push('/detail/${film.slug}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: SizedBox(
            height: cardWidth * 9 / 16,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AppImage(
                    imageUrl: film.fullThumbUrl,
                    boxFit: BoxFit.cover,
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                        stops: [0.45, 1],
                      ),
                    ),
                  ),
                ),
                if (film.episodeCurrent != null &&
                    film.episodeCurrent!.isNotEmpty)
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.md,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        film.episodeCurrent!,
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        film.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if ((film.originName ?? '').isNotEmpty)
                        Text(
                          film.originName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

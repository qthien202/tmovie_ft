import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:catalog/catalog.dart';

class GenrePage extends ConsumerWidget {
  final String slug;
  final String title;

  const GenrePage({super.key, required this.slug, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filmListState = ref.watch(
      paginatedFilmsProvider(
        FilmFilterParams(slug: slug, source: PaginatedSource.genre),
      ),
    );
    final items = filmListState.items;
    final backdropUrl = items.isNotEmpty ? items.first.fullThumbUrl : null;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          // 1. Dynamic Blurred Background
          if (backdropUrl != null)
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: AppImage(
                  key: ValueKey(backdropUrl),
                  imageUrl: backdropUrl,
                  boxFit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                color: AppColors.backgroundColor.withValues(alpha: 0.8),
              ),
            ),
          ),

          // 2. Main Content with Infinite Scroll
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification) {
                if (notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent - 400) {
                  ref
                      .read(
                        paginatedFilmsProvider(
                          FilmFilterParams(
                            slug: slug,
                            source: PaginatedSource.genre,
                          ),
                        ).notifier,
                      )
                      .loadMore();
                }
              }
              return false;
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Glassmorphism sticky header
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppColors.backgroundColor.withValues(
                    alpha: 0.5,
                  ),
                  elevation: 0,
                  centerTitle: true,
                  leading: const _AppBackButton(),
                  title: Text(
                    title.isNotEmpty ? title : slug,
                    style: AppTypography.titleLarge,
                  ),
                ),

                if (items.isEmpty && filmListState.isLoading)
                  const SliverFillRemaining(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
                      child: FilmGridSkeleton(),
                    ),
                  )
                else if (items.isEmpty && filmListState.error != null)
                  SliverFillRemaining(
                    child: _ErrorView(
                      onRetry: () => ref
                          .read(
                            paginatedFilmsProvider(
                              FilmFilterParams(
                                slug: slug,
                                source: PaginatedSource.genre,
                              ),
                            ).notifier,
                          )
                          .loadFirstPage(),
                    ),
                  )
                else if (items.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Không có phim',
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: FilmGrid(
                      films: items,
                      onFilmTap: (film) => context.push('/detail/${film.slug}'),
                    ),
                  ),
                  if (filmListState.isLoading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 16,
                        ),
                        child: FilmGridSkeleton(count: 3),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 50)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Có lỗi xảy ra', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: 'Thử lại', onPressed: onRetry),
        ],
      ),
    );
  }
}

class _AppBackButton extends StatelessWidget {
  const _AppBackButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Material(
        color: AppColors.surfaceElevated,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.border),
        ),
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
            size: AppSizes.iconSm,
          ),
          onPressed: () => context.pop(),
        ),
      ),
    );
  }
}

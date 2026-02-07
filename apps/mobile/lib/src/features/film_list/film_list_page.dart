import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

class FilmListPage extends ConsumerWidget {
  final String typeSlug;
  final String title;

  const FilmListPage({super.key, required this.typeSlug, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filmListState = ref.watch(paginatedFilmsProvider(typeSlug));
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
              child: Container(color: Colors.black.withValues(alpha: 0.7)),
            ),
          ),

          // 2. Main Content with Infinite Scroll
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification) {
                if (notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent - 400) {
                  ref
                      .read(paginatedFilmsProvider(typeSlug).notifier)
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
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                  leading: const _AppBackButton(),
                  title: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          title.isNotEmpty ? title : typeSlug,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                if (items.isEmpty && filmListState.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (items.isEmpty && filmListState.error != null)
                  SliverFillRemaining(
                    child: _ErrorView(
                      onRetry: () => ref
                          .read(paginatedFilmsProvider(typeSlug).notifier)
                          .loadFirstPage(),
                    ),
                  )
                else if (items.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Không có phim',
                        style: TextStyle(color: Colors.white),
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
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
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
          const Text('Có lỗi xảy ra', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
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
      padding: const EdgeInsets.all(8.0),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
    );
  }
}

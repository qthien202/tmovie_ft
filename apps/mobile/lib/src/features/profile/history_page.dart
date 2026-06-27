import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:media_library/media_library.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(watchHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: historyAsync.when(
              data: (history) {
                if (history.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  );
                }
                return SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: AppSpacing.lg,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.65,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = history[index];
                    return _PosterGridTile(
                      item: item,
                      subtitle: item.episode != null
                          ? 'Tập ${item.episode}'
                          : null,
                    );
                  }, childCount: history.length),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => SliverFillRemaining(
                child: Center(
                  child: Text('Error: $err', style: AppTypography.bodyMedium),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.backgroundColor,
      elevation: 0,
      pinned: true,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
          size: AppSizes.iconSm,
        ),
        onPressed: () => context.pop(),
      ),
      title: Text('Lịch sử xem', style: AppTypography.titleLarge),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.history_rounded,
          size: 80,
          color: AppColors.border,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Chưa có lịch sử xem', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Hãy bắt đầu xem những bộ phim bạn thích',
          style: AppTypography.bodyMedium,
        ),
      ],
    );
  }
}

/// Poster + title + optional subtitle. Shared by History & Favorites grids.
class _PosterGridTile extends StatelessWidget {
  final WatchHistoryEntry item;
  final String? subtitle;
  const _PosterGridTile({required this.item, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/detail/${item.slug}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppElevation.sm,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: AppImage(
                  imageUrl: item.thumbUrl ?? '',
                  boxFit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:media_library/media_library.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch history requires sign-in, so the profile is gated behind login.
    final authAsync = ref.watch(authStateProvider);
    return authAsync.when(
      data: (user) => user == null
          ? _buildSignedOut(context)
          : _buildSignedIn(context, ref, user),
      loading: () => const Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => _buildSignedOut(context),
    );
  }

  // ── Signed-out: prompt to log in ──
  Widget _buildSignedOut(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryValue.withValues(alpha: 0.10),
                  border: Border.all(
                    color: AppColors.primaryValue.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 56,
                  color: AppColors.primaryValue,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Đăng nhập để bắt đầu', style: AppTypography.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Đăng nhập để lưu lịch sử xem & phim yêu thích, đồng bộ trên mọi thiết bị.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Đăng nhập với Google',
                  icon: Icons.login_rounded,
                  size: AppButtonSize.lg,
                  expanded: true,
                  onPressed: () => context.go('/login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Signed-in: history, favourites, menu ──
  Widget _buildSignedIn(BuildContext context, WidgetRef ref, User user) {
    final historyAsync = ref.watch(watchHistoryProvider);
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildCover(context, user, historyAsync, favoritesAsync),

                _buildSection(
                  title: 'Tiếp tục xem',
                  child: historyAsync.when(
                    data: (history) => history.isEmpty
                        ? _buildEmptySection(
                            icon: Icons.play_circle_outline_rounded,
                            text: 'Chưa có lịch sử xem',
                          )
                        : _buildContinueRail(history),
                    loading: () => const _ContinueSkeleton(),
                    error: (_, _) => _buildEmptySection(
                      icon: Icons.play_circle_outline_rounded,
                      text: 'Chưa có lịch sử xem',
                    ),
                  ),
                  onSeeAll: historyAsync.valueOrNull?.isNotEmpty == true
                      ? () => context.push('/history')
                      : null,
                ),

                _buildSection(
                  title: 'Yêu thích',
                  child: favoritesAsync.when(
                    data: (favorites) => favorites.isEmpty
                        ? _buildEmptySection(
                            icon: Icons.favorite_border_rounded,
                            text: 'Chưa có phim yêu thích',
                          )
                        : _buildPosterRail(favorites),
                    loading: () => const _PosterSkeleton(),
                    error: (_, _) => _buildEmptySection(
                      icon: Icons.favorite_border_rounded,
                      text: 'Chưa có phim yêu thích',
                    ),
                  ),
                  onSeeAll: favoritesAsync.valueOrNull?.isNotEmpty == true
                      ? () => context.push('/favorites')
                      : null,
                ),

                _buildMenu(context, ref, signedIn: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Cinematic cover header ──
  Widget _buildCover(
    BuildContext context,
    User user,
    AsyncValue<List<WatchHistoryEntry>> historyAsync,
    AsyncValue<List<WatchHistoryEntry>> favoritesAsync,
  ) {
    final history = historyAsync.valueOrNull ?? const <WatchHistoryEntry>[];
    final backdrop = history.isNotEmpty ? history.first.thumbUrl : null;
    final topInset = MediaQuery.paddingOf(context).top;

    return Column(
      children: [
        SizedBox(
          height: 168 + topInset,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: _coverBanner(backdrop)),
              Positioned(
                left: 0,
                right: 0,
                bottom: -52,
                child: Center(child: _buildAvatar(user, size: 104)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 60),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              Text(
                user.displayName ?? 'Thành viên',
                style: AppTypography.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_done_rounded,
                    size: 14,
                    color: AppColors.primaryValue,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      user.email ?? 'Đã đồng bộ trên các thiết bị',
                      style: AppTypography.labelSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _buildStatsRow(historyAsync, favoritesAsync),
            ],
          ),
        ),
      ],
    );
  }

  Widget _coverBanner(String? backdrop) {
    final hasImage = backdrop != null && backdrop.isNotEmpty;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasImage)
          AppImage(imageUrl: backdrop, boxFit: BoxFit.cover)
        else
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF12B5B5), Color(0xFF0A4F4F)],
              ),
            ),
          ),
        if (hasImage)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: Container(
              color: AppColors.backgroundColor.withValues(alpha: 0.32),
            ),
          ),
        // Fade the bottom into the page so the avatar/name read cleanly.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Color(0x660A0C0C),
                AppColors.backgroundColor,
              ],
              stops: [0.35, 0.72, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(User user, {double size = 80}) {
    final photoUrl = user.photoURL;
    final inner = size * 0.44;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                AppColors.primaryValue,
                AppColors.secondary,
                AppColors.primaryValue,
              ],
            ),
          ),
        ),
        CircleAvatar(
          radius: inner + 4,
          backgroundColor: AppColors.backgroundColor,
          child: CircleAvatar(
            radius: inner,
            backgroundColor: AppColors.surfaceElevated,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Icon(
                    Icons.person_rounded,
                    size: size * 0.4,
                    color: AppColors.textSecondary,
                  )
                : null,
          ),
        ),
        Positioned(
          bottom: size * 0.03,
          right: size * 0.03,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primaryValue,
              shape: BoxShape.circle,
              border: Border.fromBorderSide(
                BorderSide(color: AppColors.backgroundColor, width: 2.5),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.star_rounded,
                color: AppColors.onPrimary,
                size: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(
    AsyncValue<List<WatchHistoryEntry>> historyAsync,
    AsyncValue<List<WatchHistoryEntry>> favoritesAsync,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            Icons.visibility_rounded,
            'Đã xem',
            historyAsync.valueOrNull?.length.toString() ?? '0',
          ),
          _buildStatDivider(),
          _buildStatItem(
            Icons.favorite_rounded,
            'Yêu thích',
            favoritesAsync.valueOrNull?.length.toString() ?? '0',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryValue, size: AppSizes.iconSm),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 36, width: 1, color: AppColors.border);
  }

  // ── Sections ──
  Widget _buildSection({
    required String title,
    VoidCallback? onSeeAll,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SectionHeader(
            title: title,
            seeAllLabel: 'Tất cả',
            onSeeAll: onSeeAll,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }

  /// Landscape "continue watching" rail.
  Widget _buildContinueRail(List<WatchHistoryEntry> items) {
    return SizedBox(
      height: 168,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) => _ContinueCard(item: items[index]),
      ),
    );
  }

  /// Portrait poster rail for favourites.
  Widget _buildPosterRail(List<WatchHistoryEntry> items) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) => _PosterCard(item: items[index]),
      ),
    );
  }

  Widget _buildEmptySection({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textTertiary, size: AppSizes.iconSm),
          const SizedBox(width: AppSpacing.sm),
          Text(text, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }

  // ── Menu ──
  Widget _buildMenu(
    BuildContext context,
    WidgetRef ref, {
    required bool signedIn,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        100,
      ),
      child: Column(
        children: [
          _buildMenuContainer([
            _MenuTileV2(
              icon: Icons.delete_sweep_rounded,
              label: 'Quản lý lịch sử & yêu thích',
              onTap: () => _showSettingsSheet(context, ref),
            ),
            _buildMenuDivider(),
            _MenuTileV2(
              icon: Icons.notifications_rounded,
              label: 'Thông báo & Tin nhắn',
              onTap: () {},
            ),
          ]),
          const SizedBox(height: AppSpacing.md),
          _buildMenuContainer([
            _MenuTileV2(
              icon: Icons.help_center_rounded,
              label: 'Trung tâm trợ giúp',
              onTap: () => _showHelpSheet(context),
            ),
            _buildMenuDivider(),
            _MenuTileV2(
              icon: Icons.security_rounded,
              label: 'Quyền riêng tư',
              onTap: () {},
            ),
          ]),
          if (signedIn) ...[
            const SizedBox(height: AppSpacing.xl),
            AppButton.ghost(
              label: 'Đăng xuất tài khoản',
              icon: Icons.logout_rounded,
              expanded: true,
              onPressed: () => _showLogoutDialog(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 64,
      endIndent: AppSpacing.lg,
      color: AppColors.border,
    );
  }

  void _showSettingsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quản lý dữ liệu', style: AppTypography.headlineMedium),
            const SizedBox(height: AppSpacing.xl),
            _MenuTile(
              icon: Icons.delete_sweep_rounded,
              label: 'Xóa lịch sử xem',
              onTap: () {
                Navigator.pop(context);
                _showConfirmDialog(
                  context,
                  ref,
                  title: 'Xóa lịch sử xem?',
                  message: 'Toàn bộ lịch sử xem phim sẽ bị xóa vĩnh viễn.',
                  onConfirm: () {
                    ref.read(historyRepositoryProvider).clearHistory();
                    ref.invalidate(watchHistoryProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xóa lịch sử xem')),
                    );
                  },
                );
              },
            ),
            _MenuTile(
              icon: Icons.heart_broken_rounded,
              label: 'Xóa phim yêu thích',
              onTap: () {
                Navigator.pop(context);
                _showConfirmDialog(
                  context,
                  ref,
                  title: 'Xóa phim yêu thích?',
                  message:
                      'Toàn bộ danh sách phim yêu thích sẽ bị xóa vĩnh viễn.',
                  onConfirm: () {
                    ref.read(favoritesRepositoryProvider).clearFavorites();
                    ref.invalidate(favoritesProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã xóa danh sách yêu thích'),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trợ giúp & Phản hồi', style: AppTypography.headlineMedium),
            const SizedBox(height: AppSpacing.xl),
            _MenuTile(
              icon: Icons.telegram_rounded,
              label: 'Tham gia nhóm Telegram hỗ trợ',
              onTap: () => Navigator.pop(context),
            ),
            _MenuTile(
              icon: Icons.bug_report_rounded,
              label: 'Báo lỗi hệ thống',
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Text(
                'Phiên bản 1.3.0',
                style: AppTypography.labelSmall,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(title, style: AppTypography.titleLarge),
        content: Text(message, style: AppTypography.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: AppTypography.labelMedium),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(
              'Xóa',
              style: AppTypography.labelMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('Đăng xuất?', style: AppTypography.titleLarge),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: AppTypography.labelMedium),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authService = ref.read(authServiceProvider);
              await authService.signOut();
            },
            child: Text(
              'Đăng xuất',
              style: AppTypography.labelMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTileV2 extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuTileV2({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primaryValue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryValue,
            size: AppSizes.iconMd,
          ),
        ),
        title: Text(label, style: AppTypography.titleMedium),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textTertiary,
          size: AppSizes.iconMd,
        ),
      ),
    );
  }
}

/// Landscape "continue watching" card: 16:9 art, play badge, title overlay.
class _ContinueCard extends StatelessWidget {
  final WatchHistoryEntry item;
  const _ContinueCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/detail/${item.slug}'),
      child: SizedBox(
        width: 232,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppImage(imageUrl: item.thumbUrl ?? '', boxFit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC04201F)],
                    stops: [0.45, 1.0],
                  ),
                ),
              ),
              const Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.black,
                      size: 22,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (item.episode != null)
                      Text(
                        'Tập ${item.episode}',
                        style: AppTypography.labelSmall.copyWith(
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
    );
  }
}

/// Portrait poster card for the favourites rail.
class _PosterCard extends StatelessWidget {
  final WatchHistoryEntry item;
  const _PosterCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/detail/${item.slug}'),
      child: SizedBox(
        width: 124,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: AppImage(
                  imageUrl: item.thumbUrl ?? '',
                  boxFit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        onTap: onTap,
        tileColor: AppColors.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border),
        ),
        leading: Icon(icon, color: AppColors.primaryValue),
        title: Text(label, style: AppTypography.titleMedium),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

class _ContinueSkeleton extends StatelessWidget {
  const _ContinueSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) => Container(
          width: 232,
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
    );
  }
}

class _PosterSkeleton extends StatelessWidget {
  const _PosterSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) => const FilmCardSkeleton(),
      ),
    );
  }
}

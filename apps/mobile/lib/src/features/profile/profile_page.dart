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
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      data: (user) {
        if (user == null) {
          return _buildSignedOutView(context, ref);
        }
        return _buildSignedInView(context, ref, user);
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _buildSignedOutView(context, ref),
    );
  }

  Widget _buildSignedOutView(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryValue.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.surfaceElevated,
                  child: const Icon(
                    Icons.person_rounded,
                    size: 50,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Đăng nhập để đồng bộ', style: AppTypography.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Lịch sử xem & phim yêu thích trên mọi thiết bị',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xxl),
              _GoogleSignInButton(
                onPressed: () async {
                  final authService = ref.read(authServiceProvider);
                  await authService.signInWithGoogle();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignedInView(BuildContext context, WidgetRef ref, dynamic user) {
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
                // 1. Header & profile card
                Stack(
                  children: [
                    Container(
                      height: 210,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primaryValue.withValues(alpha: 0.18),
                            AppColors.backgroundColor,
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        50,
                        AppSpacing.lg,
                        0,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xl,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceColor,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            _buildAvatar(user),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              user.displayName ?? 'Thành viên',
                              style: AppTypography.titleLarge,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              user.email ?? '',
                              style: AppTypography.labelSmall,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _buildStatsRow(historyAsync, favoritesAsync),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // 2. History section
                historyAsync.when(
                  data: (history) => _buildSection(
                    title: 'Vừa xem gần đây',
                    onSeeAll: history.isNotEmpty
                        ? () => context.push('/history')
                        : null,
                    child: history.isEmpty
                        ? _buildEmptySection(
                            icon: Icons.history_rounded,
                            text: 'Chưa có lịch sử xem',
                          )
                        : SizedBox(
                            height: 180,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              scrollDirection: Axis.horizontal,
                              itemCount: history.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: AppSpacing.md),
                              itemBuilder: (context, index) =>
                                  _HistoryCard(item: history[index]),
                            ),
                          ),
                  ),
                  loading: () => const _HistorySkeleton(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // 3. Favorites section
                favoritesAsync.when(
                  data: (favorites) => _buildSection(
                    title: 'Danh sách yêu thích',
                    onSeeAll: favorites.isNotEmpty
                        ? () => context.push('/favorites')
                        : null,
                    child: favorites.isEmpty
                        ? _buildEmptySection(
                            icon: Icons.favorite_border_rounded,
                            text: 'Chưa có phim yêu thích',
                          )
                        : SizedBox(
                            height: 180,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              scrollDirection: Axis.horizontal,
                              itemCount: favorites.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: AppSpacing.md),
                              itemBuilder: (context, index) =>
                                  _HistoryCard(item: favorites[index]),
                            ),
                          ),
                  ),
                  loading: () => const _HistorySkeleton(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // 4. Menu
                Padding(
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
                          icon: Icons.settings_rounded,
                          label: 'Cài đặt tài khoản',
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
                      const SizedBox(height: AppSpacing.xl),
                      AppButton.ghost(
                        label: 'Đăng xuất tài khoản',
                        icon: Icons.logout_rounded,
                        expanded: true,
                        onPressed: () => _showLogoutDialog(context, ref),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(dynamic user) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
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
          radius: 36,
          backgroundColor: AppColors.surfaceColor,
          child: CircleAvatar(
            radius: 33,
            backgroundColor: AppColors.surfaceElevated,
            backgroundImage: user.photoURL != null
                ? NetworkImage(user.photoURL!)
                : null,
            child: user.photoURL == null
                ? const Icon(
                    Icons.person_rounded,
                    size: 32,
                    color: AppColors.textSecondary,
                  )
                : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: AppColors.primaryValue,
              shape: BoxShape.circle,
              border: Border.fromBorderSide(
                BorderSide(color: AppColors.surfaceColor, width: 2),
              ),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: AppColors.onPrimary,
              size: 12,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          'Đã xem',
          historyAsync.valueOrNull?.length.toString() ?? '0',
        ),
        _buildStatDivider(),
        _buildStatItem(
          'Yêu thích',
          favoritesAsync.valueOrNull?.length.toString() ?? '0',
        ),
        _buildStatDivider(),
        _buildStatItem('Cấp độ', 'Pro'),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
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
    return Container(height: 20, width: 1, color: AppColors.border);
  }

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
            Text('Cài đặt tài khoản', style: AppTypography.headlineMedium),
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
                'Phiên bản 1.0.0 (BETA)',
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

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _GoogleSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        elevation: 0,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.g_mobiledata_rounded, size: 28),
          SizedBox(width: AppSpacing.sm),
          Text(
            'Đăng nhập bằng Google',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final WatchHistoryEntry item;
  const _HistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/detail/${item.slug}'),
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
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
            if (item.episode != null)
              Text(
                'Tập ${item.episode}',
                style: AppTypography.labelSmall,
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

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) => const FilmCardSkeleton(),
      ),
    );
  }
}

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
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      data: (user) {
        if (user == null) {
          return _buildSignedOutView(context, ref);
        }
        return _buildSignedInView(context, ref, user);
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _buildSignedOutView(context, ref),
    );
  }

  Widget _buildSignedOutView(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white.withOpacity(0.1),
                child: const Icon(
                  Icons.person_rounded,
                  size: 50,
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Đăng nhập để đồng bộ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lịch sử xem & phim yêu thích trên mọi thiết bị',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),
            _GoogleSignInButton(
              onPressed: () async {
                final authService = ref.read(authServiceProvider);
                await authService.signInWithGoogle();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignedInView(BuildContext context, WidgetRef ref, dynamic user) {
    final historyAsync = ref.watch(watchHistoryProvider);
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                // 1. Header & Card
                Stack(
                  children: [
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryValue.withOpacity(0.15),
                            Colors.black,
                          ],
                        ),
                      ),
                      child: user.photoURL != null
                          ? Opacity(
                              opacity: 0.2,
                              child: Image.network(
                                user.photoURL!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : null,
                    ),
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(color: Colors.black.withOpacity(0.2)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildAvatar(user),
                            const SizedBox(height: 12),
                            Text(
                              user.displayName ?? 'Thành viên',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user.email ?? '',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildStatsRow(historyAsync, favoritesAsync),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // 2. History Section
                historyAsync.when(
                  data: (history) => _buildSection(
                    title: 'VỪA XEM GẦN ĐÂY',
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
                                horizontal: 20,
                              ),
                              scrollDirection: Axis.horizontal,
                              itemCount: history.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) =>
                                  _HistoryCard(item: history[index]),
                            ),
                          ),
                  ),
                  loading: () => const _HistorySkeleton(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // 3. Favorites Section
                favoritesAsync.when(
                  data: (favorites) => _buildSection(
                    title: 'DANH SÁCH YÊU THÍCH',
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
                                horizontal: 20,
                              ),
                              scrollDirection: Axis.horizontal,
                              itemCount: favorites.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) =>
                                  _HistoryCard(item: favorites[index]),
                            ),
                          ),
                  ),
                  loading: () => const _HistorySkeleton(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // 4. Menu Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  child: Column(
                    children: [
                      _buildMenuContainer([
                        _MenuTileV2(
                          icon: Icons.settings_rounded,
                          label: 'Cài đặt tài khoản',
                          color: AppColors.primaryValue,
                          onTap: () => _showSettingsSheet(context, ref),
                        ),
                        _MenuTileV2(
                          icon: Icons.notifications_rounded,
                          label: 'Thông báo & Tin nhắn',
                          color: Colors.orangeAccent,
                          onTap: () {},
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _buildMenuContainer([
                        _MenuTileV2(
                          icon: Icons.help_center_rounded,
                          label: 'Trung tâm trợ giúp',
                          color: Colors.greenAccent,
                          onTap: () => _showHelpSheet(context),
                        ),
                        _MenuTileV2(
                          icon: Icons.security_rounded,
                          label: 'Quyền riêng tư',
                          color: Colors.purpleAccent,
                          onTap: () {},
                        ),
                      ]),
                      const SizedBox(height: 32),
                      _buildLogoutButton(context, ref),
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
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                AppColors.primaryValue,
                AppColors.primaryValue.withOpacity(0.2),
                AppColors.primaryValue,
              ],
            ),
          ),
        ),
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.backgroundColor,
          child: CircleAvatar(
            radius: 33,
            backgroundImage: user.photoURL != null
                ? NetworkImage(user.photoURL!)
                : null,
            child: user.photoURL == null
                ? const Icon(
                    Icons.person_rounded,
                    size: 32,
                    color: Colors.white54,
                  )
                : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.primaryValue,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.backgroundColor, width: 2),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Colors.white,
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 20,
      width: 1,
      color: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildSection({
    required String title,
    VoidCallback? onSeeAll,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              if (onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: Text(
                    'Tất cả',
                    style: TextStyle(
                      color: AppColors.primaryValue.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildEmptySection({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.15), size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.white24, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Center(
      child: GestureDetector(
        onTap: () => _showLogoutDialog(context, ref),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.logout_rounded,
                color: Colors.redAccent.withOpacity(0.8),
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'Đăng xuất tài khoản',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cài đặt tài khoản',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 12),
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
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trợ giúp & Phản hồi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Phiên bản 1.0.0 (BETA)',
                style: TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
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
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: AppColors.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.white38)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: const Text(
                'Xóa',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: AppColors.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          title: const Text(
            'Đăng xuất?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.white38)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final authService = ref.read(authServiceProvider);
                await authService.signOut();
              },
              child: const Text(
                'Đăng xuất',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTileV2 extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _MenuTileV2({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.white24,
          size: 22,
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.g_mobiledata_rounded, size: 28),
          SizedBox(width: 8),
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
                borderRadius: BorderRadius.circular(12),
                child: AppImage(
                  imageUrl: item.thumbUrl ?? '',
                  boxFit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (item.episode != null)
              Text(
                'Tập ${item.episode}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
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
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ListTile(
            onTap: onTap,
            tileColor: Colors.white.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            leading: Icon(icon, color: AppColors.primaryValue),
            title: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white24,
            ),
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => const FilmCardSkeleton(),
      ),
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

import '../../shared/tv_design_system.dart';
import '../../shared/widgets/tv_focus_wrapper.dart';

class TvProfilePage extends ConsumerWidget {
  const TvProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/login');
          });
          return const Scaffold(
            backgroundColor: TvDesignSystem.background,
            body: Center(
              child: CircularProgressIndicator(color: TvDesignSystem.primary),
            ),
          );
        }
        return _buildProfileView(context, ref, user);
      },
      loading: () => const Scaffold(
        backgroundColor: TvDesignSystem.background,
        body: Center(
          child: CircularProgressIndicator(color: TvDesignSystem.primary),
        ),
      ),
      error: (_, _) => const Scaffold(
        backgroundColor: TvDesignSystem.background,
        body: Center(
          child: Text('Đã có lỗi xảy ra',
              style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildProfileView(
      BuildContext context, WidgetRef ref, dynamic user) {
    final historyAsync = ref.watch(watchHistoryProvider);
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: TvDesignSystem.background,
      body: Focus(
        skipTraversal: true,
        canRequestFocus: false,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.goBack ||
                  event.logicalKey == LogicalKeyboardKey.escape)) {
            Navigator.of(context).pop();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            // Subtle gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    TvDesignSystem.surface.withValues(alpha: 0.5),
                    TvDesignSystem.background,
                  ],
                  stops: const [0.0, 0.3],
                ),
              ),
            ),
            Row(
            children: [
              // Left Panel (40%) - User Info
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        TvDesignSystem.primary.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(TvDesignSystem.overscanMargin),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Avatar
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                TvDesignSystem.primary,
                                TvDesignSystem.primary.withValues(alpha: 0.2),
                                TvDesignSystem.primary,
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: CircleAvatar(
                              radius: 66,
                              backgroundColor: TvDesignSystem.background,
                              child: CircleAvatar(
                                radius: 62,
                                backgroundImage: user.photoURL != null
                                    ? NetworkImage(user.photoURL!)
                                    : null,
                                child: user.photoURL == null
                                    ? const Icon(Icons.person_rounded,
                                        size: 56, color: Colors.white54)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          user.displayName ?? 'Thành viên',
                          style: TvDesignSystem.headlineLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.email ?? '',
                          style: TvDesignSystem.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        // Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStat(
                              'Đã xem',
                              historyAsync.valueOrNull?.length.toString() ??
                                  '0',
                            ),
                            Container(
                              height: 40,
                              width: 1,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                            _buildStat(
                              'Yêu thích',
                              favoritesAsync.valueOrNull?.length.toString() ??
                                  '0',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Divider
              Container(
                width: 1,
                color: Colors.white.withValues(alpha: 0.08),
              ),

              // Right Panel (60%) - Menu Items
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(TvDesignSystem.overscanMargin),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cài đặt',
                        style: TvDesignSystem.headlineLarge,
                      ),
                      const SizedBox(height: 32),
                      _TvProfileMenuItem(
                        icon: Icons.delete_sweep_rounded,
                        label: 'Xóa lịch sử xem',
                        autofocus: true,
                        onPressed: () => _showConfirmDialog(
                          context,
                          ref,
                          title: 'Xóa lịch sử xem?',
                          message:
                              'Toàn bộ lịch sử xem phim sẽ bị xóa vĩnh viễn.',
                          onConfirm: () {
                            ref
                                .read(historyRepositoryProvider)
                                .clearHistory();
                            ref.invalidate(watchHistoryProvider);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _TvProfileMenuItem(
                        icon: Icons.heart_broken_rounded,
                        label: 'Xóa phim yêu thích',
                        onPressed: () => _showConfirmDialog(
                          context,
                          ref,
                          title: 'Xóa phim yêu thích?',
                          message:
                              'Toàn bộ danh sách phim yêu thích sẽ bị xóa vĩnh viễn.',
                          onConfirm: () {
                            ref
                                .read(favoritesRepositoryProvider)
                                .clearFavorites();
                            ref.invalidate(favoritesProvider);
                          },
                        ),
                      ),
                      const Spacer(),
                      // Logout Button
                      _TvProfileMenuItem(
                        icon: Icons.logout_rounded,
                        label: 'Đăng xuất tài khoản',
                        isDestructive: true,
                        onPressed: () => _showConfirmDialog(
                          context,
                          ref,
                          title: 'Đăng xuất?',
                          message:
                              'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này?',
                          confirmLabel: 'Đăng xuất',
                          onConfirm: () async {
                            final authService =
                                ref.read(authServiceProvider);
                            await authService.signOut();
                            if (context.mounted) context.go('/home');
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Back button
                      _TvProfileMenuItem(
                        icon: Icons.arrow_back_rounded,
                        label: 'Quay lại',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TvDesignSystem.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TvDesignSystem.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String message,
    String confirmLabel = 'Xóa',
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: TvDesignSystem.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TvDesignSystem.radiusLg),
            side: BorderSide(
                color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: Text(
            title,
            style: TvDesignSystem.headlineMedium,
          ),
          content: Text(
            message,
            style: TvDesignSystem.bodyMedium.copyWith(
              color: Colors.white70,
            ),
          ),
          actions: [
            Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    (event.logicalKey == LogicalKeyboardKey.select ||
                        event.logicalKey == LogicalKeyboardKey.enter)) {
                  Navigator.pop(context);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Builder(builder: (ctx) {
                final hasFocus = Focus.of(ctx).hasFocus;
                return TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    side: hasFocus
                        ? const BorderSide(color: Colors.white, width: 2)
                        : null,
                  ),
                  child: Text(
                    'Hủy',
                    style: TvDesignSystem.labelLarge.copyWith(
                      color: Colors.white38,
                    ),
                  ),
                );
              }),
            ),
            Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    (event.logicalKey == LogicalKeyboardKey.select ||
                        event.logicalKey == LogicalKeyboardKey.enter)) {
                  Navigator.pop(context);
                  onConfirm();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Builder(builder: (ctx) {
                final hasFocus = Focus.of(ctx).hasFocus;
                return TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirm();
                  },
                  style: TextButton.styleFrom(
                    side: hasFocus
                        ? const BorderSide(color: Colors.redAccent, width: 2)
                        : null,
                  ),
                  child: Text(
                    confirmLabel,
                    style: TvDesignSystem.labelLarge.copyWith(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _TvProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;
  final bool autofocus;

  const _TvProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TvFocusWrapper(
      autofocus: autofocus,
      onTap: onPressed,
      focusedScale: 1.02,
      builder: (context, hasFocus) {
        return AnimatedContainer(
          duration: TvDesignSystem.durationFast,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: hasFocus
                ? isDestructive
                    ? Colors.redAccent.withValues(alpha: 0.15)
                    : Colors.white
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(TvDesignSystem.radiusMd),
            border: Border.all(
              color: hasFocus
                  ? isDestructive
                      ? Colors.redAccent
                      : Colors.white
                  : Colors.white.withValues(alpha: 0.06),
              width: hasFocus ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive
                    ? Colors.redAccent
                    : hasFocus
                        ? Colors.black
                        : Colors.white70,
                size: 28,
              ),
              const SizedBox(width: 20),
              Text(
                label,
                style: TvDesignSystem.titleLarge.copyWith(
                  color: isDestructive
                      ? Colors.redAccent
                      : hasFocus
                          ? Colors.black
                          : Colors.white,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: hasFocus
                    ? (isDestructive ? Colors.redAccent : Colors.black54)
                    : Colors.white24,
                size: 28,
              ),
            ],
          ),
        );
      },
    );
  }
}

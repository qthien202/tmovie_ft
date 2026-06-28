import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_update/app_update.dart';
import 'package:design_system/design_system.dart';

import '../features/update/update_dialog.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _tabs = [
    {'route': '/home', 'icon': Icons.home_rounded, 'label': 'Trang chủ'},
    {'route': '/phim-bo', 'icon': Icons.live_tv_rounded, 'label': 'Phim bộ'},
    {'route': '/phim-le', 'icon': Icons.movie_rounded, 'label': 'Phim lẻ'},
    {'route': '/tv-shows', 'icon': Icons.tv_rounded, 'label': 'TV Shows'},
    {'route': '/profile', 'icon': Icons.person_rounded, 'label': 'Cá nhân'},
  ];

  @override
  void initState() {
    super.initState();
    // Bỏ qua check cập nhật khi đang chạy debug/dev.
    if (!kReleaseMode) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    final updateInfo = await ref.read(appUpdateCheckProvider.future);
    if (updateInfo != null && mounted) {
      UpdateDialog.show(context, updateInfo);
    }
  }

  /// Derive the active tab from the current route so the highlight always
  /// matches what's on screen (deep links, programmatic nav, etc.).
  int _indexForLocation(String location) {
    final i = _tabs.indexWhere(
      (t) => location.startsWith(t['route'] as String),
    );
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _indexForLocation(location);

    // Android: nâng thanh nav lên trên thanh điều hướng cử chỉ/nút của hệ thống.
    // iOS: giữ nguyên khoảng cách cũ (home indicator đã đủ chỗ).
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final bottomNavPad = isAndroid
        ? MediaQuery.viewPaddingOf(context).bottom + 8
        : (MediaQuery.paddingOf(context).bottom > 0 ? 6.0 : 12.0);
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottomNavPad),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            // Liquid glass: blur the content scrolling behind the bar.
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.surfaceColor.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                children: List.generate(_tabs.length, (index) {
                  final isSelected = selectedIndex == index;
                  const active = Colors.white;
                  const inactive = Color(0xFF8A949B);
                  return Expanded(
                    child: InkWell(
                      onTap: () => context.go(_tabs[index]['route'] as String),
                      borderRadius: BorderRadius.circular(22),
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            // Active: lighter frosted pill on the glass bar.
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.16)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                            border: isSelected
                                ? Border.all(
                                    color: Colors.white.withValues(alpha: 0.10),
                                  )
                                : null,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _tabs[index]['icon'] as IconData,
                                color: isSelected ? active : inactive,
                                size: 21,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _tabs[index]['label'] as String,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.fade,
                                style: AppTypography.labelSmall.copyWith(
                                  color: isSelected ? active : inactive,
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

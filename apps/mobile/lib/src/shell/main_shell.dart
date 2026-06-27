import 'dart:ui';
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
  int _selectedIndex = 0;

  static const _tabs = [
    {'route': '/home', 'icon': Icons.home_rounded, 'label': 'Trang chủ'},
    {'route': '/search', 'icon': Icons.search_rounded, 'label': 'Tìm kiếm'},
    {'route': '/profile', 'icon': Icons.person_rounded, 'label': 'Cá nhân'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    final updateInfo = await ref.read(appUpdateCheckProvider.future);
    if (updateInfo != null && mounted) {
      UpdateDialog.show(context, updateInfo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.paddingOf(context).bottom > 0 ? 6 : 12,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                // Liquid glass: translucent fill with a top sheen + light edge.
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.14),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                children: List.generate(_tabs.length, (index) {
                  final isSelected = _selectedIndex == index;
                  final color = isSelected
                      ? AppColors.primaryValue
                      : Colors.white.withValues(alpha: 0.6);
                  return Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedIndex = index);
                        context.go(_tabs[index]['route'] as String);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _tabs[index]['icon'] as IconData,
                            color: color,
                            size: AppSizes.iconMd,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _tabs[index]['label'] as String,
                            style: AppTypography.labelSmall.copyWith(
                              color: color,
                              fontSize: 11,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
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

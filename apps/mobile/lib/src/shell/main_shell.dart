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
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceColor,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final isSelected = _selectedIndex == index;
                final color = isSelected
                    ? AppColors.primaryValue
                    : AppColors.textTertiary;
                return Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedIndex = index);
                      context.go(_tabs[index]['route'] as String);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _tabs[index]['icon'] as IconData,
                          color: color,
                          size: AppSizes.iconMd,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _tabs[index]['label'] as String,
                          style: AppTypography.labelSmall.copyWith(
                            color: color,
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
    );
  }
}

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
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: List.generate(_tabs.length, (index) {
              final isSelected = _selectedIndex == index;
              const accent = AppColors.primaryValue;
              const inactive = Color(0xFF9AA0A6);
              return Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    context.go(_tabs[index]['route'] as String);
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Active: soft grey "blob" behind the icon.
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.black.withValues(alpha: 0.06)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          _tabs[index]['icon'] as IconData,
                          color: isSelected ? accent : inactive,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _tabs[index]['label'] as String,
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected ? accent : inactive,
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:core/core.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const _tabs = [
    {'route': '/home', 'icon': Icons.home_outlined, 'title': 'Trang chủ'},
    {'route': '/search', 'icon': Icons.search_outlined, 'title': 'Tìm kiếm'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: widget.child,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundColor,
            boxShadow: [
              BoxShadow(blurRadius: 20, color: Colors.black.withValues(alpha: 0.1)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: GNav(
              backgroundColor: AppColors.backgroundColor,
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() => _selectedIndex = index);
                context.go(_tabs[index]['route'] as String);
              },
              rippleColor: AppColors.surfaceColor,
              hoverColor: AppColors.surfaceColor,
              gap: 5,
              activeColor: AppColors.primary,
              iconSize: 28,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: AppColors.surfaceColor,
              color: Colors.grey,
              tabs: _tabs.map((e) {
                return GButton(
                  icon: e['icon'] as IconData,
                  text: e['title'] as String,
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

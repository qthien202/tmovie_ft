import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../desktop_design_system.dart';

class DesktopShell extends StatefulWidget {
  final Widget child;
  const DesktopShell({super.key, required this.child});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  bool _isHovered = false;

  static const _navItems = [
    _NavItem(icon: Icons.home_rounded, label: 'Trang chủ', path: '/home'),
    _NavItem(icon: Icons.search_rounded, label: 'Tìm kiếm', path: '/search'),
    _NavItem(icon: Icons.history_rounded, label: 'Vừa xem', path: '/history'),
    _NavItem(
      icon: Icons.favorite_rounded,
      label: 'Yêu thích',
      path: '/favorites',
    ),
    _NavItem(icon: Icons.person_rounded, label: 'Cá nhân', path: '/profile'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _navItems.length; i++) {
      if (location == _navItems[i].path) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _currentIndex(context);
    final isExpanded = _isHovered;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Content - full width, sidebar overlays on top
          Positioned.fill(child: widget.child),

          // Glassmorphism sidebar
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: DS.curveFluid,
                width: isExpanded ? 200 : 64,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: isExpanded ? 30 : 15,
                      sigmaY: isExpanded ? 30 : 15,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isExpanded
                            ? Colors.black.withValues(alpha: 0.6)
                            : Colors.black.withValues(alpha: 0.3),
                        border: Border(
                          right: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          // Logo
                          _buildLogo(isExpanded),
                          const SizedBox(height: 20),
                          // Nav
                          ...List.generate(_navItems.length, (index) {
                            return _buildNavItem(
                              _navItems[index],
                              index == selectedIndex,
                              isExpanded,
                            );
                          }),
                          const Spacer(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(bool isExpanded) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.symmetric(
        horizontal: isExpanded ? 20 : 12,
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [DS.primary, DS.primary.withValues(alpha: 0.6)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: DS.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 22),
          ),
          if (isExpanded) ...[
            const SizedBox(width: 12),
            const Text(
              'TMovie',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem(_NavItem item, bool isSelected, bool isExpanded) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isExpanded ? 10 : 8,
        vertical: 2,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => context.go(item.path),
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.white.withValues(alpha: 0.08),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 14 : 0,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? DS.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: DS.primary.withValues(alpha: 0.2))
                  : null,
            ),
            child: Row(
              mainAxisAlignment: isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  color: isSelected
                      ? DS.primary
                      : Colors.white.withValues(alpha: 0.5),
                  size: 22,
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 14),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
  });
}

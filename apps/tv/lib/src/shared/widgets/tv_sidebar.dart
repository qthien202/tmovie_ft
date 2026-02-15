import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import 'dart:ui';
import '../tv_design_system.dart';

class TvSidebar extends ConsumerStatefulWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final VoidCallback onSearchPressed;
  final Function(bool)? onFocusChange;

  const TvSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onSearchPressed,
    this.onFocusChange,
  });

  @override
  ConsumerState<TvSidebar> createState() => _TvSidebarState();
}

class _TvSidebarState extends ConsumerState<TvSidebar> {
  bool _isExpanded = false;

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.home_rounded, 'label': 'Trang chủ'},
    {'icon': Icons.history_rounded, 'label': 'Vừa xem'},
    {'icon': Icons.favorite_rounded, 'label': 'Yêu thích'},
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    return FocusTraversalGroup(
      child: Focus(
        skipTraversal: true,
        canRequestFocus: false,
        onFocusChange: (hasFocus) {
          if (_isExpanded != hasFocus) {
            setState(() => _isExpanded = hasFocus);
            widget.onFocusChange?.call(hasFocus);
          }
        },
        child: AnimatedContainer(
          duration: TvDesignSystem.durationMedium,
          curve: TvDesignSystem.curveFluid,
          width: _isExpanded ? 340 : 110,
          decoration: BoxDecoration(
            color: _isExpanded
                ? TvDesignSystem.background.withValues(alpha: 0.8)
                : Colors.transparent,
          ),
          child: Stack(
            children: [
              // Liquid Glass Blur Overlay
              if (_isExpanded)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.05),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.2),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    // Premium Logo Section
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: _isExpanded ? 32 : 0,
                      ),
                      child: Row(
                        mainAxisAlignment: _isExpanded
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  TvDesignSystem.primary,
                                  TvDesignSystem.secondary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: TvDesignSystem.primary.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          if (_isExpanded) ...[
                            const SizedBox(width: 20),
                            const Text(
                              'TMOVIE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),

                    // Menu Items (Scrollable if height is small)
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SidebarItem(
                              icon: Icons.search_rounded,
                              label: 'Tìm kiếm',
                              isExpanded: _isExpanded,
                              isSelected: false,
                              onTap: widget.onSearchPressed,
                              onRightPress: _moveFocusToContent,
                              highlightColor: TvDesignSystem.accent,
                            ),
                            const SizedBox(height: 16),
                            ...List.generate(_menuItems.length, (index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _SidebarItem(
                                  icon: _menuItems[index]['icon'],
                                  label: _menuItems[index]['label'],
                                  isExpanded: _isExpanded,
                                  isSelected: widget.selectedIndex == index,
                                  onTap: () =>
                                      widget.onDestinationSelected(index),
                                  onRightPress: _moveFocusToContent,
                                  highlightColor: TvDesignSystem.accent,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    // Profile Section
                    _buildUserSection(user),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _moveFocusToContent() {
    FocusManager.instance.primaryFocus?.focusInDirection(
      TraversalDirection.right,
    );
  }

  Widget _buildUserSection(dynamic user) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Divider(
            color: Colors.white.withValues(alpha: 0.08),
            height: 1,
          ),
        ),
        const SizedBox(height: 32),
        _SidebarItem(
          icon: user?.photoURL == null
              ? Icons.account_circle_outlined
              : Icons.account_circle,
          label: user?.displayName ?? 'Đăng nhập',
          isExpanded: _isExpanded,
          isSelected: false,
          onTap: () => context.push(user == null ? '/login' : '/profile'),
          onRightPress: _moveFocusToContent,
          isAvatar: true,
          avatarUrl: user?.photoURL,
          highlightColor: Colors.white,
        ),
      ],
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isExpanded;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onRightPress;
  final bool isAvatar;
  final String? avatarUrl;
  final Color? highlightColor;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isExpanded,
    required this.isSelected,
    required this.onTap,
    this.onRightPress,
    this.isAvatar = false,
    this.avatarUrl,
    this.highlightColor,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.highlightColor ?? Colors.white;

    return Focus(
      onFocusChange: (f) => setState(() => _isFocused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onTap();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onRightPress?.call();
            });
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            widget.onRightPress?.call();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: TvDesignSystem.durationFast,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            color: _isFocused ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(TvDesignSystem.radiusMd),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.25),
                      blurRadius: 25,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: widget.isExpanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Selected indicator (White Dot/Line)
                  if (widget.isSelected && !widget.isExpanded && !_isFocused)
                    Positioned(
                      left: -26,
                      child: Container(
                        width: 6,
                        height: 32,
                        decoration: BoxDecoration(
                          color: activeColor,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (widget.isAvatar && widget.avatarUrl != null)
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(widget.avatarUrl!),
                      backgroundColor: Colors.transparent,
                    )
                  else
                    Icon(
                      widget.icon,
                      color: _isFocused
                          ? Colors.black
                          : (widget.isSelected ? activeColor : Colors.white70),
                      size: 30,
                    ),
                ],
              ),
              if (widget.isExpanded) ...[
                const SizedBox(width: 24),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: _isFocused
                          ? Colors.black
                          : (widget.isSelected ? activeColor : Colors.white),
                      fontSize: 21,
                      fontWeight: _isFocused || widget.isSelected
                          ? FontWeight.w900
                          : FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.isSelected && !_isFocused)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

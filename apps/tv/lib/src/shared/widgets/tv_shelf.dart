import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:core/core.dart';
import 'tv_film_card.dart';
import '../tv_design_system.dart';

class TvShelf extends StatefulWidget {
  final String title;
  final List<FilmItem> items;
  final Function(FilmItem) onFilmTap;
  final Function(FilmItem)? onFilmFocused;
  final bool isLarge;

  const TvShelf({
    super.key,
    required this.title,
    required this.items,
    required this.onFilmTap,
    this.onFilmFocused,
    this.isLarge = false,
  });

  @override
  State<TvShelf> createState() => _TvShelfState();
}

class _TvShelfState extends State<TvShelf> {
  late ScrollController _scrollController;
  final double _paddingLeft = 80.0;
  int _selectedIndex = 0;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (_selectedIndex < widget.items.length - 1) {
        setState(() => _selectedIndex++);
        _scrollToSelected();
        widget.onFilmFocused?.call(widget.items[_selectedIndex]);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (_selectedIndex > 0) {
        setState(() => _selectedIndex--);
        _scrollToSelected();
        widget.onFilmFocused?.call(widget.items[_selectedIndex]);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter) {
      widget.onFilmTap(widget.items[_selectedIndex]);
    }
  }

  void _scrollToSelected() {
    final itemWidth = widget.isLarge ? 400.0 : 280.0;
    const itemSpacing = 32.0;
    final targetOffset = _selectedIndex * (itemWidth + itemSpacing);

    _scrollController.animateTo(
      targetOffset,
      duration: TvDesignSystem.durationFast,
      curve: TvDesignSystem.curveFluid,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final itemWidth = widget.isLarge ? 400.0 : 280.0;
    const aspectRatio = 16 / 9;
    final thumbHeight = itemWidth / aspectRatio;
    // itemHeight should just be thumb + text space + some breathing room
    final itemHeight = thumbHeight + 100;

    return Focus(
      onFocusChange: (hasFocus) {
        setState(() => _isFocused = hasFocus);
        if (hasFocus) {
          widget.onFilmFocused?.call(widget.items[_selectedIndex]);
        }
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
              event.logicalKey == LogicalKeyboardKey.arrowLeft ||
              event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            _onKey(event);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: _paddingLeft, top: 40, bottom: 24),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        TvDesignSystem.primary,
                        TvDesignSystem.secondary,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: TvDesignSystem.primary.withValues(alpha: 0.5),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Text(
                  widget.title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: itemHeight,
            child: Stack(
              clipBehavior:
                  Clip.none, // Allow scaled cards to overflow container
              children: [
                // 1. The scrolling list (Belt)
                Positioned(
                  left: _paddingLeft,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: MediaQuery.removePadding(
                    context: context,
                    removeLeft: true,
                    removeRight: true,
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(
                        right: 600,
                        top: 20,
                        bottom: 20,
                      ),
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      clipBehavior: Clip.none,
                      itemCount: widget.items.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 32),
                      itemBuilder: (context, index) {
                        final isItemSelected = index == _selectedIndex;
                        return TvFilmCard(
                          film: widget.items[index],
                          onTap: () => widget.onFilmTap(widget.items[index]),
                          width: itemWidth,
                          aspectRatio: aspectRatio,
                          isFocused: _isFocused && isItemSelected,
                          canRequestFocus: false,
                          showBorder: true,
                          showShadow: true,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

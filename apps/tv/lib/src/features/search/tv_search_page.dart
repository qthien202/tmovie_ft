import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

import '../../shared/tv_design_system.dart';
import '../../shared/widgets/tv_film_card.dart';
import '../../shared/widgets/tv_focus_button.dart';
import '../../shared/widgets/tv_focus_wrapper.dart';

class TvSearchPage extends ConsumerStatefulWidget {
  final String? initialGenre;

  const TvSearchPage({super.key, this.initialGenre});

  @override
  ConsumerState<TvSearchPage> createState() => _TvSearchPageState();
}

class _TvSearchPageState extends ConsumerState<TvSearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _keyword = '';

  // Filter state
  String? _selectedGenre;
  String? _selectedCountry;
  int? _selectedYear;

  static const _genres = [
    {'label': 'Hành Động', 'slug': 'hanh-dong'},
    {'label': 'Tình Cảm', 'slug': 'tinh-cam'},
    {'label': 'Kinh Dị', 'slug': 'kinh-di'},
    {'label': 'Hài Hước', 'slug': 'hai-huoc'},
    {'label': 'Viễn Tưởng', 'slug': 'vien-tuong'},
    {'label': 'Hoạt Hình', 'slug': 'hoat-hinh'},
    {'label': 'Phiêu Lưu', 'slug': 'phieu-luu'},
    {'label': 'Cổ Trang', 'slug': 'co-trang'},
    {'label': 'Tâm Lý', 'slug': 'tam-ly'},
  ];

  static const _countries = [
    {'label': 'Trung Quốc', 'slug': 'trung-quoc'},
    {'label': 'Hàn Quốc', 'slug': 'han-quoc'},
    {'label': 'Âu Mỹ', 'slug': 'au-my'},
    {'label': 'Nhật Bản', 'slug': 'nhat-ban'},
    {'label': 'Thái Lan', 'slug': 'thai-lan'},
    {'label': 'Việt Nam', 'slug': 'viet-nam'},
  ];

  bool get _hasFilters =>
      _selectedGenre != null ||
      _selectedCountry != null ||
      _selectedYear != null;

  bool get _useSearch => _keyword.isNotEmpty && !_hasFilters;

  @override
  void initState() {
    super.initState();
    if (widget.initialGenre != null) {
      _selectedGenre = widget.initialGenre;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      setState(() => _keyword = value.trim());
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedGenre = null;
      _selectedCountry = null;
      _selectedYear = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TvDesignSystem.background,
      body: Focus(
        skipTraversal: true,
        canRequestFocus: false,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.goBack ||
                  event.logicalKey == LogicalKeyboardKey.escape ||
                  event.logicalKey == LogicalKeyboardKey.backspace)) {
            context.pop();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
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
              Column(
                children: [
                  // Search bar
                  _buildSearchBar(),

                  // Filter chips
                  _buildFilterRow(),

                  // Results
                  Expanded(
                    child: (!_hasFilters && _keyword.isEmpty)
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  color: Colors.white.withValues(alpha: 0.12),
                                  size: 80,
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Nhập từ khóa hoặc chọn bộ lọc để tìm kiếm',
                                  style: TvDesignSystem.titleLarge.copyWith(
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _useSearch
                        ? _TvPaginatedSearchResults(keyword: _keyword)
                        : _TvPaginatedFilterResults(
                            genre: _selectedGenre,
                            country: _selectedCountry,
                            year: _selectedYear,
                            keyword: _keyword.isNotEmpty ? _keyword : null,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        TvDesignSystem.overscanMargin,
        TvDesignSystem.overscanMargin,
        TvDesignSystem.overscanMargin,
        0,
      ),
      child: Row(
        children: [
          TvFocusButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(TvDesignSystem.radiusMd),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(
                      TvDesignSystem.radiusMd,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    autofocus: false,
                    onChanged: _onSearchChanged,
                    style: TvDesignSystem.titleLarge,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm phim...',
                      hintStyle: TvDesignSystem.titleLarge.copyWith(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      filled: false,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 18,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 20, right: 12),
                        child: Icon(
                          Icons.search_rounded,
                          color: Colors.white.withValues(alpha: 0.4),
                          size: 28,
                        ),
                      ),
                      suffixIcon: _keyword.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white54,
                                size: 24,
                              ),
                              onPressed: () {
                                _controller.clear();
                                setState(() => _keyword = '');
                              },
                            )
                          : null,
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

  Widget _buildFilterRow() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        TvDesignSystem.overscanMargin,
        TvDesignSystem.spaceMd,
        TvDesignSystem.overscanMargin,
        TvDesignSystem.spaceMd,
      ),
      child: SizedBox(
        height: 52,
        child: FocusTraversalGroup(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Genre chips
              ..._genres.map(
                (g) => _buildFilterChip(
                  g['label']!,
                  isSelected: _selectedGenre == g['slug'],
                  onTap: () => setState(() {
                    _selectedGenre = _selectedGenre == g['slug']
                        ? null
                        : g['slug'];
                  }),
                ),
              ),
              // Divider
              _buildChipDivider(),
              // Country chips
              ..._countries.map(
                (c) => _buildFilterChip(
                  c['label']!,
                  isSelected: _selectedCountry == c['slug'],
                  onTap: () => setState(() {
                    _selectedCountry = _selectedCountry == c['slug']
                        ? null
                        : c['slug'];
                  }),
                ),
              ),
              // Divider
              _buildChipDivider(),
              // Year chips
              ...[2025, 2024, 2023, 2022].map(
                (y) => _buildFilterChip(
                  '$y',
                  isSelected: _selectedYear == y,
                  onTap: () => setState(() {
                    _selectedYear = _selectedYear == y ? null : y;
                  }),
                ),
              ),
              // Clear all
              if (_hasFilters)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _buildFilterChip(
                    'Xóa bộ lọc',
                    isSelected: false,
                    isClear: true,
                    onTap: _clearFilters,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChipDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Container(width: 1, color: Colors.white.withValues(alpha: 0.12)),
    );
  }

  Widget _buildFilterChip(
    String label, {
    required bool isSelected,
    required VoidCallback onTap,
    bool isClear = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: TvFocusWrapper(
        onTap: onTap,
        focusedScale: 1.05,
        builder: (context, hasFocus) {
          return AnimatedContainer(
            duration: TvDesignSystem.durationFast,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? TvDesignSystem.primary
                  : isClear
                  ? Colors.redAccent.withValues(alpha: 0.15)
                  : hasFocus
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(TvDesignSystem.radiusSm),
              border: Border.all(
                color: hasFocus
                    ? Colors.white
                    : isSelected
                    ? TvDesignSystem.primary
                    : isClear
                    ? Colors.redAccent.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.08),
                width: hasFocus ? 2 : 1,
              ),
            ),
            child: Text(
              label,
              style: TvDesignSystem.labelLarge.copyWith(
                color: isClear
                    ? Colors.redAccent
                    : hasFocus && !isSelected
                    ? Colors.black
                    : isSelected || hasFocus
                    ? Colors.white
                    : Colors.white70,
                fontSize: 18,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Paginated search results (keyword only)
class _TvPaginatedSearchResults extends ConsumerWidget {
  final String keyword;
  const _TvPaginatedSearchResults({required this.keyword});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paginatedSearchFilmsProvider(keyword));
    final notifier = ref.read(paginatedSearchFilmsProvider(keyword).notifier);

    return _TvFilmGrid(
      items: state.items,
      isLoading: state.isLoading,
      hasMore: state.hasMore,
      onLoadMore: () => notifier.loadMore(),
    );
  }
}

/// Paginated filter results (genre/country/year)
class _TvPaginatedFilterResults extends ConsumerWidget {
  final String? genre;
  final String? country;
  final int? year;
  final String? keyword;

  const _TvPaginatedFilterResults({
    this.genre,
    this.country,
    this.year,
    this.keyword,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = FilmFilterParams(
      slug: (keyword != null && keyword!.isNotEmpty)
          ? keyword!
          : (genre ?? country ?? 'phim-moi-cap-nhat'),
      source: (keyword != null && keyword!.isNotEmpty)
          ? PaginatedSource.search
          : genre != null
          ? PaginatedSource.genre
          : country != null
          ? PaginatedSource.country
          : PaginatedSource.type,
      category: genre,
      country: country,
      year: year,
    );

    final state = ref.watch(paginatedFilmsProvider(params));
    final notifier = ref.read(paginatedFilmsProvider(params).notifier);

    return _TvFilmGrid(
      items: state.items,
      isLoading: state.isLoading,
      hasMore: state.hasMore,
      onLoadMore: () => notifier.loadMore(),
    );
  }
}

/// Reusable grid with pagination - uses TvFilmCard for premium look
class _TvFilmGrid extends StatelessWidget {
  final List<FilmItem> items;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback onLoadMore;

  const _TvFilmGrid({
    required this.items,
    required this.isLoading,
    required this.hasMore,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: TvDesignSystem.primary),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.movie_filter_rounded,
              color: Colors.white.withValues(alpha: 0.12),
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              'Không tìm thấy phim',
              style: TvDesignSystem.titleLarge.copyWith(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      );
    }

    return FocusTraversalGroup(
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.extentAfter < 200 &&
              hasMore &&
              !isLoading) {
            onLoadMore();
          }
          return false;
        },
        child: GridView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: TvDesignSystem.overscanMargin,
            vertical: TvDesignSystem.spaceMd,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.76,
            crossAxisSpacing: 36,
            mainAxisSpacing: 40,
          ),
          itemCount: items.length + (isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= items.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    color: TvDesignSystem.primary,
                    strokeWidth: 2,
                  ),
                ),
              );
            }

            final film = items[index];
            return TvFilmCard(
              film: film,
              onTap: () => context.push('/detail/${film.slug}'),
              width: double.infinity,
              aspectRatio: 16 / 9,
            );
          },
        ),
      ),
    );
  }
}

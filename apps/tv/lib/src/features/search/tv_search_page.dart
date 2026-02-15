import 'dart:async';
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
  final _searchFocusNode = FocusNode();
  Timer? _debounce;
  String _keyword = '';

  // Applied Filter state (what results reflect)
  String? _selectedGenre;
  String? _selectedCountry;
  int? _selectedYear;

  // Temporary selection state (in-panel selection)
  String? _tempGenre;
  String? _tempCountry;
  int? _tempYear;

  bool _showFilters = false;

  static const _genres = [
    {'label': 'Hành Động', 'slug': 'hanh-dong'},
    {'label': 'Tình Cảm', 'slug': 'tinh-cam'},
    {'label': 'Kinh Dị', 'slug': 'kinh-di'},
    {'label': 'Hài Hước', 'slug': 'hai-huoc'},
    {'label': 'Hoạt Hình', 'slug': 'hoat-hinh'},
    {'label': 'Viễn Tưởng', 'slug': 'vien-tuong'},
    {'label': 'Võ Thuật', 'slug': 'vo-thuat'},
    {'label': 'Cổ Trang', 'slug': 'co-trang'},
    {'label': 'Kịch Tính', 'slug': 'kich-tinh'},
    {'label': 'Tâm Lý', 'slug': 'tam-ly'},
    {'label': 'Hình Sự', 'slug': 'hinh-su'},
    {'label': 'Chiến Tranh', 'slug': 'chien-tranh'},
    {'label': 'Tài Liệu', 'slug': 'tai-lieu'},
    {'label': 'Khoa Học', 'slug': 'khoa-hoc'},
    {'label': 'Thần Thoại', 'slug': 'than-thoai'},
  ];

  static const _countries = [
    {'label': 'Trung Quốc', 'slug': 'trung-quoc'},
    {'label': 'Hàn Quốc', 'slug': 'han-quoc'},
    {'label': 'Âu Mỹ', 'slug': 'au-my'},
    {'label': 'Nhật Bản', 'slug': 'nhat-ban'},
    {'label': 'Thái Lan', 'slug': 'thai-lan'},
    {'label': 'Việt Nam', 'slug': 'viet-nam'},
    {'label': 'Hồng Kông', 'slug': 'hong-kong'},
    {'label': 'Đài Loan', 'slug': 'dai-loan'},
  ];

  final List<int> _years = List.generate(
    12,
    (index) => DateTime.now().year - index,
  );

  bool get _hasFilters =>
      _selectedGenre != null ||
      _selectedCountry != null ||
      _selectedYear != null;

  bool get _useSearch => _keyword.isNotEmpty && !_hasFilters;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    if (widget.initialGenre != null) {
      _selectedGenre = widget.initialGenre;
      _tempGenre = widget.initialGenre;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchFocusNode.dispose();
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
      _tempGenre = null;
      _tempCountry = null;
      _tempYear = null;
    });
  }

  void _applyFilters() {
    setState(() {
      _selectedGenre = _tempGenre;
      _selectedCountry = _tempCountry;
      _selectedYear = _tempYear;
      _showFilters = false;
    });
  }

  void _resetTempFilters() {
    setState(() {
      _tempGenre = _selectedGenre;
      _tempCountry = _selectedCountry;
      _tempYear = _selectedYear;
    });
  }

  int _getActiveFiltersCount() {
    int count = 0;
    if (_selectedGenre != null) count++;
    if (_selectedCountry != null) count++;
    if (_selectedYear != null) count++;
    return count;
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
              NotificationListener<ScrollNotification>(
                onNotification: (notification) => false,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 16),
                        child: _buildSearchBar(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.02),
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildFilterShelf(
                                'THỂ LOẠI',
                                _genres,
                                _tempGenre,
                                (slug) {
                                  setState(
                                    () => _tempGenre = _tempGenre == slug
                                        ? null
                                        : slug,
                                  );
                                },
                              ),
                              _buildFilterShelf(
                                'QUỐC GIA',
                                _countries,
                                _tempCountry,
                                (slug) {
                                  setState(
                                    () => _tempCountry = _tempCountry == slug
                                        ? null
                                        : slug,
                                  );
                                },
                              ),
                              _buildFilterShelf(
                                'NĂM PHÁT HÀNH',
                                _years
                                    .map((y) => {'label': '$y', 'slug': '$y'})
                                    .toList(),
                                _tempYear?.toString(),
                                (slug) {
                                  setState(
                                    () => _tempYear =
                                        _tempYear == int.tryParse(slug)
                                        ? null
                                        : int.tryParse(slug),
                                  );
                                },
                              ),
                              const SizedBox(height: 32),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 48,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TvFocusButton(
                                        icon: Icons.check_circle_rounded,
                                        label: 'ÁP DỤNG BỘ LỌC',
                                        isPrimary: true,
                                        onPressed: _applyFilters,
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    TvFocusButton(
                                      icon: Icons.refresh_rounded,
                                      label: 'LÀM MỚI',
                                      onPressed: () {
                                        setState(() {
                                          _tempGenre = null;
                                          _tempCountry = null;
                                          _tempYear = null;
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 24),
                                    TvFocusButton(
                                      icon: Icons.close_rounded,
                                      label: 'HỦY',
                                      onPressed: () =>
                                          setState(() => _showFilters = false),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                        crossFadeState: _showFilters
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: TvDesignSystem.durationFast,
                        sizeCurve: Curves.easeInOut,
                      ),
                    ),
                    if (_hasFilters && !_showFilters)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(48, 0, 48, 16),
                          child: Row(
                            children: [
                              _buildActiveFilterBadge(),
                              const SizedBox(width: 16),
                              TvFocusButton(
                                icon: Icons.close_rounded,
                                label: 'XÓA BỘ LỌC',
                                onPressed: _clearFilters,
                              ),
                            ],
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      sliver: (!_hasFilters && _keyword.isEmpty)
                          ? SliverFillRemaining(
                              hasScrollBody: false,
                              child: _buildSearchEmptyState(),
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
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final hasFocus = _searchFocusNode.hasFocus;
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: TvFocusButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: AnimatedContainer(
              duration: TvDesignSystem.durationFast,
              height: 72,
              decoration: BoxDecoration(
                color: hasFocus
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(TvDesignSystem.radiusMd),
                border: Border.all(
                  color: hasFocus
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.1),
                  width: 2,
                ),
                boxShadow: hasFocus ? TvDesignSystem.focusGlow : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(TvDesignSystem.radiusMd),
                child: Focus(
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent) {
                      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                        FocusManager.instance.primaryFocus?.focusInDirection(
                          TraversalDirection.right,
                        );
                        return KeyEventResult.handled;
                      }
                      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                        FocusManager.instance.primaryFocus?.focusInDirection(
                          TraversalDirection.left,
                        );
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: _controller,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    style: TvDesignSystem.titleLarge.copyWith(
                      color: hasFocus ? Colors.black : Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Nhập tên phim cần tìm...',
                      hintStyle: TvDesignSystem.titleLarge.copyWith(
                        color: hasFocus
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.2),
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
                          color: hasFocus
                              ? Colors.black.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.4),
                          size: 32,
                        ),
                      ),
                      suffixIcon: _keyword.isNotEmpty
                          ? IconButton(
                              padding: const EdgeInsets.only(right: 16),
                              icon: Icon(
                                Icons.close_rounded,
                                color: hasFocus
                                    ? Colors.black45
                                    : Colors.white54,
                                size: 28,
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
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildFilterToggleButton() {
    final activeCount = _getActiveFiltersCount();
    return TvFocusWrapper(
      onTap: () {
        if (!_showFilters) _resetTempFilters();
        setState(() => _showFilters = !_showFilters);
      },
      builder: (context, hasFocus) {
        return Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: _showFilters
                ? TvDesignSystem.primary
                : hasFocus
                ? Colors.white
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(TvDesignSystem.radiusMd),
            border: Border.all(
              color: hasFocus
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                color: hasFocus && !_showFilters ? Colors.black : Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                _showFilters ? 'ĐÓNG BỘ LỌC' : 'BỘ LỌC',
                style: TextStyle(
                  color: hasFocus && !_showFilters
                      ? Colors.black
                      : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              if (activeCount > 0) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$activeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveFilterBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: TvDesignSystem.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(TvDesignSystem.radiusSm),
        border: Border.all(
          color: TvDesignSystem.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        'Đang áp dụng ${_getActiveFiltersCount()} bộ lọc',
        style: const TextStyle(
          color: TvDesignSystem.primary,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildFilterShelf(
    String title,
    List<Map<String, String>> items,
    String? selectedSlug,
    Function(String) onToggle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ),
          SizedBox(
            height: 60,
            child: FocusTraversalGroup(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = selectedSlug == item['slug'];
                  return _buildFilterItem(
                    item['label']!,
                    isSelected: isSelected,
                    onTap: () => onToggle(item['slug']!),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterItem(
    String label, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return TvFocusWrapper(
      onTap: onTap,
      builder: (context, hasFocus) {
        return AnimatedContainer(
          duration: TvDesignSystem.durationFast,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? TvDesignSystem.primary
                : hasFocus
                ? Colors.white
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(TvDesignSystem.radiusMd),
            border: Border.all(
              color: hasFocus
                  ? Colors.white
                  : isSelected
                  ? TvDesignSystem.primary
                  : Colors.white.withValues(alpha: 0.08),
              width: 1.5,
            ),
            boxShadow: hasFocus ? TvDesignSystem.primaryGlow : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: hasFocus && !isSelected ? Colors.black : Colors.white,
                fontSize: 18,
                fontWeight: isSelected || hasFocus
                    ? FontWeight.w900
                    : FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.02),
            ),
            child: Icon(
              Icons.search_rounded,
              color: Colors.white.withValues(alpha: 0.05),
              size: 120,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'BẠN MUỐN XEM PHIM GÌ?',
            style: TvDesignSystem.headlineLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sử dụng bộ lọc ở trên để khám phá nhanh kho phim',
            style: TvDesignSystem.bodyLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}

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
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: TvDesignSystem.primary),
        ),
      );
    }
    if (items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
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
                'Không tìm thấy phim phù hợp',
                style: TvDesignSystem.titleLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 400 &&
            hasMore &&
            !isLoading) {
          onLoadMore();
        }
        return false;
      },
      child: SliverPadding(
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.15,
            crossAxisSpacing: 40,
            mainAxisSpacing: 40,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
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
          }, childCount: items.length + (isLoading ? 1 : 0)),
        ),
      ),
    );
  }
}

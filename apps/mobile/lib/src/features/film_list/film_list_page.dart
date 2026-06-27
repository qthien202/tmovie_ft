import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:catalog/catalog.dart';

class FilmListPage extends ConsumerStatefulWidget {
  final String typeSlug;
  final String title;

  const FilmListPage({super.key, required this.typeSlug, required this.title});

  @override
  ConsumerState<FilmListPage> createState() => _FilmListPageState();
}

class _FilmListPageState extends ConsumerState<FilmListPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  String? _searchQuery;
  final Set<String> _selectedGenres = {};
  final Set<String> _selectedCountries = {};
  String? _selectedYear;

  final List<({String name, String slug})> _genres = [
    (name: 'Hành Động', slug: 'hanh-dong'),
    (name: 'Tình Cảm', slug: 'tinh-cam'),
    (name: 'Kinh Dị', slug: 'kinh-di'),
    (name: 'Hài Hước', slug: 'hai-huoc'),
    (name: 'Hoạt Hình', slug: 'hoat-hinh'),
    (name: 'Viễn Tưởng', slug: 'vien-tuong'),
    (name: 'Võ Thuật', slug: 'vo-thuat'),
    (name: 'Cổ Trang', slug: 'co-trang'),
    (name: 'Kịch Tính', slug: 'kich-tinh'),
    (name: 'Tâm Lý', slug: 'tam-ly'),
  ];

  final List<({String name, String slug})> _countries = [
    (name: 'Trung Quốc', slug: 'trung-quoc'),
    (name: 'Hàn Quốc', slug: 'han-quoc'),
    (name: 'Âu Mỹ', slug: 'au-my'),
    (name: 'Nhật Bản', slug: 'nhat-ban'),
    (name: 'Thái Lan', slug: 'thai-lan'),
    (name: 'Việt Nam', slug: 'viet-nam'),
    (name: 'Hồng Kông', slug: 'hong-kong'),
    (name: 'Đài Loan', slug: 'dai-loan'),
  ];

  final List<({String name, String slug})> _years = List.generate(10, (index) {
    final year = DateTime.now().year - index;
    return (name: '$year', slug: '$year');
  });

  @override
  void initState() {
    super.initState();
    _initInitialFilters();
  }

  void _initInitialFilters() {
    // If typeSlug matches a genre, activate it
    if (_genres.any((g) => g.slug == widget.typeSlug)) {
      _selectedGenres.add(widget.typeSlug);
    }
    // If typeSlug matches a country, activate it
    else if (_countries.any((c) => c.slug == widget.typeSlug)) {
      _selectedCountries.add(widget.typeSlug);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = value.trim().isEmpty ? null : value.trim();
        // Clear other filters when searching manually to avoid confusion
        if (_searchQuery != null) {
          _selectedGenres.clear();
          _selectedCountries.clear();
          _selectedYear = null;
        }
      });
    });
  }

  void _toggleGenre(String slug) {
    setState(() {
      if (_selectedGenres.contains(slug)) {
        _selectedGenres.remove(slug);
      } else {
        _selectedGenres.add(slug);
      }
      _searchQuery = null;
      _searchController.clear();
    });
  }

  void _toggleCountry(String slug) {
    setState(() {
      if (_selectedCountries.contains(slug)) {
        _selectedCountries.remove(slug);
      } else {
        _selectedCountries.add(slug);
      }
      _searchQuery = null;
      _searchController.clear();
    });
  }

  void _selectYear(String? slug) {
    setState(() {
      _selectedYear = slug;
      _searchQuery = null;
      _searchController.clear();
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedGenres.clear();
      _selectedCountries.clear();
      _selectedYear = null;
      _searchQuery = null;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Build filter params based on current selections
    final dynamic provider;

    if (_searchQuery != null) {
      provider = paginatedSearchFilmsProvider(_searchQuery!);
    } else {
      // Determine the primary source and build filter params
      final int? yearFilter = _selectedYear != null
          ? int.tryParse(_selectedYear!)
          : null;

      if (_selectedGenres.length == 1 && _selectedCountries.length <= 1) {
        // Use genre endpoint as primary, with country & year as query params
        provider = paginatedFilmsProvider(
          FilmFilterParams(
            slug: _selectedGenres.first,
            source: PaginatedSource.genre,
            country: _selectedCountries.firstOrNull,
            year: yearFilter,
          ),
        );
      } else if (_selectedCountries.length == 1 &&
          _selectedGenres.length <= 1) {
        // Use country endpoint as primary, with category & year as query params
        provider = paginatedFilmsProvider(
          FilmFilterParams(
            slug: _selectedCountries.first,
            source: PaginatedSource.country,
            category: _selectedGenres.firstOrNull,
            year: yearFilter,
          ),
        );
      } else {
        // Use type endpoint with category, country, year as query params
        provider = paginatedFilmsProvider(
          FilmFilterParams(
            slug: widget.typeSlug,
            source: PaginatedSource.type,
            category: _selectedGenres.firstOrNull,
            country: _selectedCountries.firstOrNull,
            year: yearFilter,
          ),
        );
      }
    }

    final filmListState = ref.watch(provider);
    final firstFilm = filmListState.items.isNotEmpty
        ? filmListState.items.first
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background
          if (firstFilm != null)
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(seconds: 1),
                child: AppImage(
                  key: ValueKey(firstFilm.fullThumbUrl),
                  imageUrl: firstFilm.fullThumbUrl,
                  boxFit: BoxFit.cover,
                ),
              ),
            ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification) {
                  if (notification.metrics.pixels >=
                      notification.metrics.maxScrollExtent - 400) {
                    ref.read(provider.notifier).loadMore();
                  }
                }
                return false;
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Minimalist Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          _buildGlassButton(
                            icon: Icons.chevron_left_rounded,
                            onTap: () => context.pop(),
                          ),
                          const Spacer(),
                          _buildDynamicTitleBadge(),
                          const Spacer(),
                          _buildGlassButton(
                            icon: Icons.tune_rounded,
                            onTap: _showFilterSheet,
                            badgeCount:
                                (_selectedGenres.length +
                                _selectedCountries.length +
                                (_selectedYear != null ? 1 : 0)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Search Field
                  SliverAppBar(
                    pinned: false,
                    floating: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    toolbarHeight: 65,
                    titleSpacing: 16,
                    automaticallyImplyLeading: false,
                    title: _buildCompactSearchField(),
                  ),

                  // Quick Genre Chips & Active Filters
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildQuickGenreScroll(),
                        ),
                        if (_selectedGenres.isNotEmpty ||
                            _selectedCountries.isNotEmpty ||
                            _selectedYear != null)
                          _buildActiveFilterChips(),
                      ],
                    ),
                  ),

                  // Results
                  if (filmListState.items.isEmpty && filmListState.isLoading)
                    const SliverFillRemaining(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        child: FilmGridSkeleton(),
                      ),
                    )
                  else if (filmListState.error != null &&
                      filmListState.items.isEmpty)
                    SliverFillRemaining(child: _buildErrorState(provider))
                  else if (filmListState.items.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'Không tìm thấy nội dung phù hợp',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: FilmGrid.asSliver(
                        films: filmListState.items,
                        onFilmTap: (film) =>
                            context.push('/detail/${film.slug}'),
                      ),
                    ),

                  if (filmListState.hasMore && filmListState.items.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 40,
                          horizontal: 16,
                        ),
                        child: FilmGridSkeleton(count: 3),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDynamicTitleBadge() {
    String title = widget.title.toUpperCase();
    if (_searchQuery != null) {
      title = 'TÌM KIẾM';
    } else if (_selectedGenres.isNotEmpty ||
        _selectedCountries.isNotEmpty ||
        _selectedYear != null) {
      title = 'LỌC KẾT QUẢ';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCompactSearchField() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Nhập tên phim cần tìm...',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Colors.white54,
                size: 18,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white54,
                        size: 16,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickGenreScroll() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _genres.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final genre = _genres[index];
          final isSelected = _selectedGenres.contains(genre.slug);
          return GestureDetector(
            onTap: () => _toggleGenre(genre.slug),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                genre.name,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _FilterBottomSheet(
        genres: _genres,
        countries: _countries,
        years: _years,
        selectedGenres: _selectedGenres,
        selectedCountries: _selectedCountries,
        selectedYear: _selectedYear,
        onGenreToggle: _toggleGenre,
        onCountryToggle: _toggleCountry,
        onYearSelect: _selectYear,
        onClearAll: _clearAllFilters,
      ),
    );
  }

  Widget _buildActiveFilterChips() {
    final filters = <({String label, VoidCallback onRemove})>[];

    for (final slug in _selectedGenres) {
      final name = _genres.firstWhere((g) => g.slug == slug).name;
      filters.add((label: name, onRemove: () => _toggleGenre(slug)));
    }

    for (final slug in _selectedCountries) {
      final name = _countries.firstWhere((c) => c.slug == slug).name;
      filters.add((label: name, onRemove: () => _toggleCountry(slug)));
    }

    if (_selectedYear != null) {
      filters.add((label: _selectedYear!, onRemove: () => _selectYear(null)));
    }

    return Container(
      height: 44,
      padding: const EdgeInsets.only(bottom: 12),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          return Chip(
            label: Text(
              filter.label,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            deleteIcon: const Icon(
              Icons.close_rounded,
              color: Colors.white70,
              size: 14,
            ),
            onDeleted: filter.onRemove,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(dynamic provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.white24,
            size: 60,
          ),
          const SizedBox(height: 16),
          const Text('Có lỗi xảy ra', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.read(provider.notifier).loadFirstPage(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final List<({String name, String slug})> genres;
  final List<({String name, String slug})> countries;
  final List<({String name, String slug})> years;
  final Set<String> selectedGenres;
  final Set<String> selectedCountries;
  final String? selectedYear;
  final Function(String) onGenreToggle;
  final Function(String) onCountryToggle;
  final Function(String?) onYearSelect;
  final VoidCallback onClearAll;

  const _FilterBottomSheet({
    required this.genres,
    required this.countries,
    required this.years,
    required this.selectedGenres,
    required this.selectedCountries,
    required this.selectedYear,
    required this.onGenreToggle,
    required this.onCountryToggle,
    required this.onYearSelect,
    required this.onClearAll,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  String? _localYear;

  @override
  void initState() {
    super.initState();
    _localYear = widget.selectedYear;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'BỘ LỌC NÂNG CAO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  widget.onClearAll();
                  setState(() {
                    _localYear = null;
                  });
                },
                child: Text(
                  'Xóa tất cả',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildSection(
            'THỂ LOẠI (CHỌN NHIỀU)',
            widget.genres,
            widget.selectedGenres,
            widget.onGenreToggle,
          ),
          const SizedBox(height: 24),
          _buildSection(
            'QUỐC GIA (CHỌN NHIỀU)',
            widget.countries,
            widget.selectedCountries,
            widget.onCountryToggle,
          ),
          const SizedBox(height: 24),
          _buildYearSection(),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'XEM KẾT QUẢ',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSection(
    String label,
    List<({String name, String slug})> items,
    Set<String> selectedSet,
    Function(String) onToggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final isSelected = selectedSet.contains(item.slug);
            return GestureDetector(
              onTap: () {
                onToggle(item.slug);
                setState(() {});
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Text(
                  item.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildYearSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NĂM PHÁT HÀNH',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.years.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final year = widget.years[index];
              final isSelected = _localYear == year.slug;
              return GestureDetector(
                onTap: () {
                  final newYear = isSelected ? null : year.slug;
                  widget.onYearSelect(newYear);
                  setState(() {
                    _localYear = newYear;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    year.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

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

  /// When shown as a bottom-nav root tab there's nothing to pop back to, so the
  /// header hides its back button.
  final bool isRootTab;

  const FilmListPage({
    super.key,
    required this.typeSlug,
    required this.title,
    this.isRootTab = false,
  });

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

  int get _activeFilterCount =>
      _selectedGenres.length +
      _selectedCountries.length +
      (_selectedYear != null ? 1 : 0);

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
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          // Cinematic blurred backdrop of the first result.
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
                      AppColors.backgroundColor.withValues(alpha: 0.7),
                      AppColors.backgroundColor.withValues(alpha: 0.9),
                      AppColors.backgroundColor,
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
                  // Header: back · title · filter
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        0,
                      ),
                      child: Row(
                        children: [
                          if (!widget.isRootTab) ...[
                            _IconButton(
                              icon: Icons.chevron_left_rounded,
                              onTap: () => context.pop(),
                            ),
                            const SizedBox(width: AppSpacing.md),
                          ],
                          Expanded(
                            child: Text(
                              widget.title,
                              style: AppTypography.titleLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          _IconButton(
                            icon: Icons.tune_rounded,
                            onTap: _showFilterSheet,
                            badgeCount: _activeFilterCount,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Search field
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.md,
                      ),
                      child: AppTextField(
                        controller: _searchController,
                        hint: 'Nhập tên phim cần tìm...',
                        prefixIcon: Icons.search_rounded,
                        onChanged: _onSearchChanged,
                        onClear: _searchController.text.isNotEmpty
                            ? () {
                                _searchController.clear();
                                _onSearchChanged('');
                              }
                            : null,
                      ),
                    ),
                  ),

                  // Quick genre chips & active filters
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _buildQuickGenreScroll(),
                        ),
                        if (_activeFilterCount > 0) _buildActiveFilterChips(),
                      ],
                    ),
                  ),

                  // Results
                  if (filmListState.items.isEmpty && filmListState.isLoading)
                    const SliverFillRemaining(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.xl,
                        ),
                        child: FilmGridSkeleton(),
                      ),
                    )
                  else if (filmListState.error != null &&
                      filmListState.items.isEmpty)
                    SliverFillRemaining(child: _buildErrorState(provider))
                  else if (filmListState.items.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'Không tìm thấy nội dung phù hợp',
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
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
                          horizontal: AppSpacing.lg,
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

  Widget _buildQuickGenreScroll() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _genres.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final genre = _genres[index];
          return AppChip(
            label: genre.name,
            selected: _selectedGenres.contains(genre.slug),
            onTap: () => _toggleGenre(genre.slug),
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
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final filter = filters[index];
          return Chip(
            label: Text(
              filter.label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primaryValue,
              ),
            ),
            backgroundColor: AppColors.primaryValue.withValues(alpha: 0.14),
            side: BorderSide(
              color: AppColors.primaryValue.withValues(alpha: 0.4),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            deleteIcon: const Icon(Icons.close_rounded, size: 14),
            deleteIconColor: AppColors.primaryValue,
            onDeleted: filter.onRemove,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
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
            color: AppColors.textTertiary,
            size: 60,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Có lỗi xảy ra', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Thử lại',
            onPressed: () => ref.read(provider.notifier).loadFirstPage(),
          ),
        ],
      ),
    );
  }
}

/// Token-styled square icon button used in the header.
class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  const _IconButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                icon,
                color: AppColors.textPrimary,
                size: AppSizes.iconMd,
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
              decoration: const BoxDecoration(
                color: AppColors.primaryValue,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badgeCount',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
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
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Bộ lọc nâng cao', style: AppTypography.titleLarge),
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
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primaryValue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          _buildSection(
            'Thể loại (chọn nhiều)',
            widget.genres,
            widget.selectedGenres,
            widget.onGenreToggle,
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildSection(
            'Quốc gia (chọn nhiều)',
            widget.countries,
            widget.selectedCountries,
            widget.onCountryToggle,
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildYearSection(),

          const SizedBox(height: AppSpacing.xxl),
          AppButton(
            label: 'Xem kết quả',
            expanded: true,
            size: AppButtonSize.lg,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
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
        _buildSectionLabel(label),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: items.map((item) {
            return AppChip(
              label: item.name,
              selected: selectedSet.contains(item.slug),
              onTap: () {
                onToggle(item.slug);
                setState(() {});
              },
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
        _buildSectionLabel('Năm phát hành'),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.years.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final year = widget.years[index];
              final isSelected = _localYear == year.slug;
              return AppChip(
                label: year.name,
                selected: isSelected,
                onTap: () {
                  final newYear = isSelected ? null : year.slug;
                  widget.onYearSelect(newYear);
                  setState(() {
                    _localYear = newYear;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

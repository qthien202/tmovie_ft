import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:catalog/catalog.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _keyword = '';

  final Set<String> _selectedGenres = {};
  final Set<String> _selectedCountries = {};
  String? _selectedYear;

  @override
  void initState() {
    super.initState();
    // Default filter to 2026 on first entry
    _selectedYear = '2026';
  }

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
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      setState(() {
        _keyword = value.trim();
        if (_keyword.isNotEmpty) {
          _selectedGenres.clear();
          _selectedCountries.clear();
          _selectedYear = null;
        }
      });
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true, // Show above bottom navigation bar
      builder: (context) => _FilterBottomSheet(
        genres: _genres,
        countries: _countries,
        years: _years,
        selectedGenres: _selectedGenres,
        selectedCountries: _selectedCountries,
        selectedYear: _selectedYear,
        onGenreToggle: (slug) {
          setState(() {
            if (_selectedGenres.contains(slug)) {
              _selectedGenres.remove(slug);
            } else {
              _selectedGenres.add(slug);
            }
            _keyword = '';
            _controller.clear();
          });
        },
        onCountryToggle: (slug) {
          setState(() {
            if (_selectedCountries.contains(slug)) {
              _selectedCountries.remove(slug);
            } else {
              _selectedCountries.add(slug);
            }
            _keyword = '';
            _controller.clear();
          });
        },
        onYearSelect: (slug) {
          setState(() {
            _selectedYear = slug;
            _keyword = '';
            _controller.clear();
          });
        },
        onClearAll: () {
          setState(() {
            _selectedGenres.clear();
            _selectedCountries.clear();
            _selectedYear = null;
            _keyword = '';
            _controller.clear();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
            child: Column(
              children: [
                // Header: search field + filter inline
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _controller,
                          hint: 'Nhập tên phim, diễn viên...',
                          prefixIcon: Icons.search_rounded,
                          textInputAction: TextInputAction.search,
                          onChanged: (val) {
                            setState(() {});
                            _onSearchChanged(val);
                          },
                          onClear: _controller.text.isNotEmpty
                              ? () {
                                  _controller.clear();
                                  _onSearchChanged('');
                                  setState(() {});
                                }
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterButton(),
                    ],
                  ),
                ),

                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child:
                        (_keyword.isEmpty &&
                            _selectedGenres.isEmpty &&
                            _selectedCountries.isEmpty &&
                            _selectedYear == null)
                        ? _buildEmptyState()
                        : _SearchList(
                            keyword: _keyword,
                            selectedGenres: _selectedGenres,
                            selectedCountries: _selectedCountries,
                            selectedYear: _selectedYear,
                            key: ValueKey(
                              '$_keyword-${_selectedGenres.join()}-${_selectedCountries.join()}-$_selectedYear',
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildFilterButton() {
    final count = _selectedGenres.length +
        _selectedCountries.length +
        (_selectedYear != null ? 1 : 0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.surfaceElevated,
          borderRadius: AppRadius.brMd,
          child: InkWell(
            onTap: _showFilterSheet,
            borderRadius: AppRadius.brMd,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: AppRadius.brMd,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: AppColors.textPrimary,
                size: AppSizes.iconMd,
              ),
            ),
          ),
        ),
        if (count > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: AppColors.primaryValue,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: AppColors.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 1),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceColor,
              ),
              child: const Icon(
                Icons.search_rounded,
                size: 80,
                color: AppColors.border,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Tìm kiếm vạn phim hay', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Nhập tên phim để khám phá ngay',
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SearchList extends ConsumerWidget {
  final String keyword;
  final Set<String> selectedGenres;
  final Set<String> selectedCountries;
  final String? selectedYear;

  const _SearchList({
    required this.keyword,
    required this.selectedGenres,
    required this.selectedCountries,
    this.selectedYear,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dynamic provider;

    if (keyword.isNotEmpty) {
      provider = paginatedSearchFilmsProvider(keyword);
    } else {
      final int? yearFilter = selectedYear != null
          ? int.tryParse(selectedYear!)
          : null;

      if (selectedGenres.length == 1) {
        provider = paginatedFilmsProvider(
          FilmFilterParams(
            slug: selectedGenres.first,
            source: PaginatedSource.genre,
            country: selectedCountries.firstOrNull,
            year: yearFilter,
          ),
        );
      } else if (selectedCountries.length == 1) {
        provider = paginatedFilmsProvider(
          FilmFilterParams(
            slug: selectedCountries.first,
            source: PaginatedSource.country,
            category: selectedGenres.firstOrNull,
            year: yearFilter,
          ),
        );
      } else {
        provider = paginatedFilmsProvider(
          FilmFilterParams(
            slug: 'phim-moi-cap-nhat',
            source: PaginatedSource.type,
            category: selectedGenres.firstOrNull,
            country: selectedCountries.firstOrNull,
            year: yearFilter,
          ),
        );
      }
    }

    final filmListState = ref.watch(provider);

    if (filmListState.items.isEmpty && filmListState.isLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: FilmGridSkeleton(),
      );
    }

    if (filmListState.items.isEmpty && !filmListState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sentiment_dissatisfied_rounded,
              size: 60,
              color: AppColors.border,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Không tìm thấy bộ phim nào phù hợp',
              style: AppTypography.bodyMedium,
            ),
            if (keyword.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '"$keyword"',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.primaryValue,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
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
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: FilmGrid.asSliver(
              films: filmListState.items,
              onFilmTap: (film) => context.push('/detail/${film.slug}'),
            ),
          ),
          if (filmListState.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                child: FilmGridSkeleton(count: 3),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: AppButton(
                label: 'Xem kết quả',
                expanded: true,
                size: AppButtonSize.lg,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
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
            padding: EdgeInsets.zero,
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

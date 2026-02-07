import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Ambient Glow Background
          Positioned(
            top: -150,
            right: -150,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 1. Header Area
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      const SizedBox(width: 40), // Balance the filter button
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

                // 2. Search Field Area
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: _buildCompactSearchField(),
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
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
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
    String title = 'TÌM KIẾM';
    if (_selectedGenres.isNotEmpty ||
        _selectedCountries.isNotEmpty ||
        _selectedYear != null) {
      title = 'LỌC KẾT QUẢ';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildCompactSearchField() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: _controller,
            onChanged: (val) {
              setState(() {});
              _onSearchChanged(val);
            },
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Nhập tên phim, diễn viên...',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Colors.white.withValues(alpha: 0.4),
                size: 20,
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: Colors.white60,
                      onPressed: () {
                        _controller.clear();
                        _onSearchChanged('');
                        setState(() {});
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
              child: Icon(
                Icons.search_rounded,
                size: 80,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tìm kiếm vạn phim hay',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nhập tên phim để khám phá ngay',
            style: TextStyle(color: Colors.white12, fontSize: 13),
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
            Icon(
              Icons.sentiment_dissatisfied_rounded,
              size: 60,
              color: Colors.white.withValues(alpha: 0.05),
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy bộ phim nào phù hợp',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 14,
              ),
            ),
            if (keyword.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '"$keyword"',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
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
          const SizedBox(height: 32),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 20,
              ), // Extra space to clear nav bar
              child: SizedBox(
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
            ),
          ),
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
          height: 38,
          child: ListView.separated(
            padding: EdgeInsets.zero,
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

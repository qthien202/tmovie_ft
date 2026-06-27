import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:catalog/catalog.dart';
import '../../shared/desktop_design_system.dart';

class DesktopSearchPage extends ConsumerStatefulWidget {
  const DesktopSearchPage({super.key});

  @override
  ConsumerState<DesktopSearchPage> createState() => _DesktopSearchPageState();
}

class _DesktopSearchPageState extends ConsumerState<DesktopSearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _keyword = '';

  final Set<String> _selectedGenres = {};
  String? _selectedYear;

  static const _genres = [
    (name: 'Hành Động', slug: 'hanh-dong'),
    (name: 'Tình Cảm', slug: 'tinh-cam'),
    (name: 'Kinh Dị', slug: 'kinh-di'),
    (name: 'Hài Hước', slug: 'hai-huoc'),
    (name: 'Hoạt Hình', slug: 'hoat-hinh'),
    (name: 'Viễn Tưởng', slug: 'vien-tuong'),
    (name: 'Võ Thuật', slug: 'vo-thuat'),
    (name: 'Cổ Trang', slug: 'co-trang'),
    (name: 'Tâm Lý', slug: 'tam-ly'),
    (name: 'Hình Sự', slug: 'hinh-su'),
  ];

  final List<String> _years = List.generate(
    10,
    (index) => '${DateTime.now().year - index}',
  );

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _keyword = value.trim();
        if (_keyword.isNotEmpty) {
          _selectedGenres.clear();
          _selectedYear = null;
        }
      });
    });
  }

  bool get _hasFilters => _selectedGenres.isNotEmpty || _selectedYear != null;
  bool get _hasResults => _keyword.isNotEmpty || _hasFilters;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Ambient glow
          Positioned(
            top: -150,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DS.primary.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),

          Column(
            children: [
              const SizedBox(height: 20),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(80, 0, 32, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: DS.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: DS.primary.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        _hasFilters ? 'LỌC KẾT QUẢ' : 'TÌM KIẾM',
                        style: TextStyle(
                          color: DS.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Search field
              Padding(
                padding: const EdgeInsets.fromLTRB(80, 0, 32, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: TextField(
                        controller: _controller,
                        onChanged: (val) {
                          setState(() {});
                          _onSearch(val);
                        },
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Nhập tên phim, diễn viên...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Colors.white.withValues(alpha: 0.4),
                            size: 20,
                          ),
                          suffixIcon: _controller.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded,
                                      size: 18),
                                  color: Colors.white60,
                                  onPressed: () {
                                    _controller.clear();
                                    setState(() => _keyword = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Filter chips
              Padding(
                padding: const EdgeInsets.fromLTRB(80, 0, 32, 0),
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Year chips
                      ..._years.map((year) {
                        final isSelected = _selectedYear == year;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _filterChip(
                            year,
                            isSelected,
                            () => setState(() {
                              _selectedYear =
                                  isSelected ? null : year;
                              _keyword = '';
                              _controller.clear();
                            }),
                          ),
                        );
                      }),
                      Container(
                        width: 1,
                        height: 24,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      // Genre chips
                      ..._genres.map((g) {
                        final isSelected =
                            _selectedGenres.contains(g.slug);
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _filterChip(
                            g.name,
                            isSelected,
                            () => setState(() {
                              if (isSelected) {
                                _selectedGenres.remove(g.slug);
                              } else {
                                _selectedGenres.add(g.slug);
                              }
                              _keyword = '';
                              _controller.clear();
                            }),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Results
              Expanded(
                child: _hasResults ? _buildResults() : _buildEmpty(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
      String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? DS.primary.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? DS.primary
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 12,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_rounded,
              size: 80, color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 20),
          Text(
            'Tìm kiếm vạn phim hay',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhập tên phim hoặc chọn bộ lọc để khám phá',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.15),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final dynamic provider;

    if (_keyword.isNotEmpty) {
      provider = paginatedSearchFilmsProvider(_keyword);
    } else if (_selectedGenres.length == 1) {
      provider = paginatedFilmsProvider(
        FilmFilterParams(
          slug: _selectedGenres.first,
          source: PaginatedSource.genre,
          year: _selectedYear != null ? int.tryParse(_selectedYear!) : null,
        ),
      );
    } else {
      provider = paginatedFilmsProvider(
        FilmFilterParams(
          slug: 'phim-moi-cap-nhat',
          source: PaginatedSource.type,
          category: _selectedGenres.firstOrNull,
          year: _selectedYear != null ? int.tryParse(_selectedYear!) : null,
        ),
      );
    }

    final filmListState = ref.watch(provider);

    if (filmListState.items.isEmpty && filmListState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: DS.primary),
      );
    }

    if (filmListState.items.isEmpty) {
      return Center(
        child: Text(
          'Không tìm thấy kết quả',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 14,
          ),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(80, 0, 80, 80),
        child: FilmGrid(
          films: filmListState.items,
          childAspectRatio: 0.55,
          crossAxisCount: 6,
          onFilmTap: (film) => context.push('/detail/${film.slug}'),
        ),
      ),
    );
  }
}

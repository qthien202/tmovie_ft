import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

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
  String? _selectedGenre;

  // Common genres for quick filtering
  final List<({String name, String slug})> _quickGenres = [
    (name: 'Hành Động', slug: 'hanh-dong'),
    (name: 'Tình Cảm', slug: 'tinh-cam'),
    (name: 'Kinh Dị', slug: 'kinh-di'),
    (name: 'Hài Hước', slug: 'hai-huoc'),
    (name: 'Hoạt Hình', slug: 'hoat-hinh'),
    (name: 'Viễn Tưởng', slug: 'vien-tuong'),
    (name: 'Võ Thuật', slug: 'vo-thuat'),
    (name: 'Cổ Trang', slug: 'co-trang'),
  ];

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
        if (_searchQuery != null)
          _selectedGenre = null; // Clear genre when searching
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Logic to select provider based on current mode
    final dynamic provider;
    if (_searchQuery != null) {
      provider = paginatedSearchFilmsProvider(_searchQuery!);
    } else if (_selectedGenre != null) {
      provider = paginatedGenreFilmsProvider(_selectedGenre!);
    } else {
      provider = paginatedFilmsProvider(widget.typeSlug);
    }

    final filmListState = ref.watch(provider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Ambient Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    Colors.black,
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),

          NotificationListener<ScrollNotification>(
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
                // Premium Search Header
                SliverAppBar(
                  expandedHeight: 130,
                  pinned: true,
                  floating: true,
                  backgroundColor: Colors.black.withValues(alpha: 0.8),
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => context.pop(),
                  ),
                  centerTitle: true,
                  title: Text(
                    _searchQuery != null
                        ? 'Kết quả tìm kiếm'
                        : (_selectedGenre != null
                              ? 'Thể loại: ${_quickGenres.firstWhere((g) => g.slug == _selectedGenre).name}'
                              : widget.title.toUpperCase()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Padding(
                      padding: const EdgeInsets.only(
                        top: 90,
                        left: 16,
                        right: 16,
                      ),
                      child: _buildSearchField(),
                    ),
                  ),
                ),

                // Quick Filter Chips
                SliverToBoxAdapter(child: _buildFilterChips()),

                // Results Grid
                if (filmListState.items.isEmpty && filmListState.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (filmListState.error != null &&
                    filmListState.items.isEmpty)
                  SliverFillRemaining(child: _buildErrorState(provider))
                else if (filmListState.items.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Không tìm thấy phim',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: FilmGrid.asSliver(
                      films: filmListState.items,
                      onFilmTap: (film) => context.push('/detail/${film.slug}'),
                    ),
                  ),

                // Loading Indicator at bottom
                if (filmListState.hasMore && filmListState.items.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary.withValues(alpha: 0.5),
                          ),
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

  Widget _buildSearchField() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm trong danh sách...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Colors.white70,
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _quickGenres.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final genre = _quickGenres[index];
          final isSelected = _selectedGenre == genre.slug;
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedGenre = null;
                } else {
                  _selectedGenre = genre.slug;
                  _searchQuery = null;
                  _searchController.clear();
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.1),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                genre.name,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
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
          const Text(
            'Có lỗi xảy ra khi tải dữ liệu',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.read(provider.notifier).loadFirstPage(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

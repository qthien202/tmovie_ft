import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:catalog/catalog.dart';
import 'package:media_library/media_library.dart';

import '../../shared/widgets/tv_sidebar.dart';
import '../../shared/widgets/tv_shelf.dart';
import '../../shared/widgets/tv_focus_button.dart';
import '../../shared/tv_design_system.dart';
import '../update/tv_update_dialog.dart';
import 'package:app_update/app_update.dart';

class TvHomePage extends ConsumerStatefulWidget {
  const TvHomePage({super.key});

  @override
  ConsumerState<TvHomePage> createState() => _TvHomePageState();
}

class _TvHomePageState extends ConsumerState<TvHomePage> {
  int _selectedMenuIndex = 0; // 0=Trang chủ, 1=Vừa xem, 2=Yêu thích
  int _selectedTabIndex = 0; // Tab bar index (only used when menu=0)
  FilmItem? _focusedFilm;
  final ScrollController _scrollController = ScrollController();
  bool _isSidebarFocused = false;

  // Top category tabs (iQIYI style)
  static const _contentTabs = [
    'Khám phá',
    'Phim bộ',
    'Phim lẻ',
    'TV Shows',
    'Hoạt hình',
    'Vietsub',
    'Thuyết minh',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    final updateInfo = await ref.read(appUpdateCheckProvider.future);
    if (updateInfo != null && mounted) {
      TvUpdateDialog.show(context, updateInfo);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                  event.logicalKey == LogicalKeyboardKey.escape)) {
            SystemNavigator.pop();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Focus(
          skipTraversal: true,
          canRequestFocus: false,
          onKeyEvent: (node, event) {
            // Catch unhandled arrow-left from content → move to sidebar
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              // Only handle when focus is NOT already in the sidebar
              if (!_isSidebarFocused) {
                FocusManager.instance.primaryFocus?.focusInDirection(
                  TraversalDirection.left,
                );
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Stack(
            children: [
              // 1. Cinematic Dynamic Background
              _buildHeroBackground(),

              // 2. Main Content Wrapper
              Row(
                children: [
                  const SizedBox(width: 110), // Sidebar collapsed width
                  Expanded(
                    child: FocusTraversalGroup(
                      policy: ReadingOrderTraversalPolicy(),
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // Top category tabs (only on Trang chủ)
                          if (_selectedMenuIndex == 0)
                            SliverToBoxAdapter(child: _buildTopTabBar()),

                          // Hero Section
                          SliverToBoxAdapter(child: _buildGrandHero()),

                          // Shelves based on selected menu
                          ..._buildContentForMenu(),

                          const SliverToBoxAdapter(
                            child: SizedBox(height: 120),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 3. Sidebar Overlay (blur when sidebar focused)
              _buildSidebarOverlay(),

              // 4. Sidebar
              TvSidebar(
                selectedIndex: _selectedMenuIndex,
                onFocusChange: (hasFocus) =>
                    setState(() => _isSidebarFocused = hasFocus),
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedMenuIndex = index;
                    _selectedTabIndex = 0;
                    _focusedFilm =
                        null; // Reset to trigger auto-focus on new section
                  });
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 800),
                    curve: TvDesignSystem.curveFluid,
                  );
                },
                onSearchPressed: () => context.push('/search'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Hero Section ───

  Widget _buildGrandHero() {
    if (_focusedFilm == null) {
      return _buildHeroPlaceholder();
    }

    final film = _focusedFilm!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(60, 80, 60, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Film type tag
          if (film.type != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(
                  TvDesignSystem.radiusSm,
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                _getTypeLabel(film.type!).toUpperCase(),
                style: TvDesignSystem.labelSmall.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
            ),
          const SizedBox(height: 28),

          // Film title
          Text(
            film.name ?? '',
            style: TvDesignSystem.displayLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 28),

          // Real metadata row
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 0,
            runSpacing: 12,
            children: [
              if (film.year != null) ...[
                Text('${film.year}', style: TvDesignSystem.headlineMedium),
                _buildDot(),
              ],
              if (film.episodeCurrent != null) ...[
                Text(
                  film.episodeCurrent!,
                  style: TvDesignSystem.headlineMedium,
                ),
                _buildDot(),
              ],
              if (film.quality != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amber, width: 2),
                    borderRadius: BorderRadius.circular(
                      TvDesignSystem.radiusSm,
                    ),
                  ),
                  child: Text(
                    film.quality!.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
              if (film.lang != null) ...[
                _buildDot(),
                Text(film.lang!, style: TvDesignSystem.bodyMedium),
              ],
            ],
          ),
          const SizedBox(height: 36),

          // Origin name / description
          if (film.originName != null && film.originName!.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Text(
                film.originName!,
                style: TvDesignSystem.bodyLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 48),

          // Action buttons
          FocusTraversalGroup(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TvFocusButton(
                  icon: Icons.play_arrow_rounded,
                  label: 'Xem phim',
                  isPrimary: true,
                  onPressed: () => context.push('/detail/${film.slug}'),
                ),
                const SizedBox(width: 24),
                TvFocusButton(
                  icon: Icons.info_outline_rounded,
                  label: 'Chi tiết',
                  onPressed: () => context.push('/detail/${film.slug}'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPlaceholder() {
    return Container(
      height: 500,
      padding: const EdgeInsets.fromLTRB(60, 80, 60, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 200,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(TvDesignSystem.radiusSm),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 500,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(TvDesignSystem.radiusMd),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 350,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(TvDesignSystem.radiusSm),
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'single':
        return 'Phim lẻ';
      case 'series':
        return 'Phim bộ';
      case 'hoathinh':
        return 'Hoạt hình';
      case 'tvshows':
        return 'TV Shows';
      default:
        return type;
    }
  }

  Widget _buildDot() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        shape: BoxShape.circle,
      ),
    );
  }

  // ─── Top Tab Bar (iQIYI style) ───

  Widget _buildTopTabBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(60, 40, 60, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none, // Prevent clipping of the glass pills
        child: FocusTraversalGroup(
          child: Row(
            children: [
              for (int i = 0; i < _contentTabs.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildTabItem(_contentTabs[i], i),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    final isActive = _selectedMenuIndex == 0 && _selectedTabIndex == index;

    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            setState(() {
              _selectedMenuIndex = 0;
              _selectedTabIndex = index;
              _focusedFilm = null;
            });
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 800),
              curve: TvDesignSystem.curveFluid,
            );
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft && index == 0) {
            FocusManager.instance.primaryFocus?.focusInDirection(
              TraversalDirection.left,
            );
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: hasFocus ? 1.05 : 1.0,
                duration: TvDesignSystem.durationFast,
                curve: TvDesignSystem.curveFluid,
                child: AnimatedContainer(
                  duration: TvDesignSystem.durationFast,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: hasFocus
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      TvDesignSystem.radiusFull,
                    ),
                    border: Border.all(
                      color: hasFocus
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isActive || hasFocus
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      fontSize: 24,
                      fontWeight: isActive || hasFocus
                          ? FontWeight.w900
                          : FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Active Indicator (Dot)
              AnimatedContainer(
                duration: TvDesignSystem.durationMedium,
                width: isActive ? 8 : 0,
                height: 8,
                decoration: BoxDecoration(
                  color: TvDesignSystem.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: TvDesignSystem.primary.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Content per Menu Index ───

  List<Widget> _buildContentForMenu() {
    // Sidebar: 0=Trang chủ, 1=Vừa xem, 2=Yêu thích
    switch (_selectedMenuIndex) {
      case 0: // Trang chủ → use tab bar index
        return _buildContentForTab();
      case 1: // Vừa xem (History)
        return [_buildHistorySection()];
      case 2: // Yêu thích (Favorites)
        return [_buildFavoritesSection()];
      default:
        return _buildContentForTab();
    }
  }

  List<Widget> _buildContentForTab() {
    switch (_selectedTabIndex) {
      case 0: // Khám phá
        return _buildFeaturedDiscoverSections();
      case 1: // Phim bộ
        return [
          _buildShelfSliver(
            'Phim bộ mới cập nhật',
            'phim-bo',
            isLandscape: true,
          ),
          _buildGenreShelfSliver('Cổ trang - Kiếm hiệp', 'co-trang'),
          _buildGenreShelfSliver('Hình sự - Chiến tranh', 'hinh-su'),
          _buildGenreShelfSliver('Tâm lý - Gia đình', 'tam-ly'),
          _buildShelfSliver('Phim bộ hot trong tuần', 'phim-bo'),
        ];
      case 2: // Phim lẻ
        return [
          _buildShelfSliver('Phim lẻ mới nhất', 'phim-le', isLandscape: true),
          _buildGenreShelfSliver('Hành động kịch tính', 'hanh-dong'),
          _buildGenreShelfSliver('Tình cảm lãng mạn', 'tinh-cam'),
          _buildGenreShelfSliver('Kinh dị rùng rợn', 'kinh-di'),
          _buildShelfSliver('Phim chiếu rạp hot', 'phim-le'),
        ];
      case 3: // TV Shows
        return [
          _buildShelfSliver('TV Shows nổi bật', 'tv-shows', isLandscape: true),
          _buildGenreShelfSliver('Reality Shows', 'reality'),
          _buildGenreShelfSliver('Talk Shows', 'talk-show'),
          _buildGenreShelfSliver('Music Shows', 'music'),
        ];
      case 4: // Hoạt hình
        return [
          _buildShelfSliver('Anime mới nhất', 'hoat-hinh', isLandscape: true),
          _buildGenreShelfSliver('Anime hành động', 'hanh-dong'),
          _buildGenreShelfSliver('Anime phiêu lưu', 'phieu-luu'),
          _buildGenreShelfSliver('Anime viễn tưởng', 'vien-tuong'),
        ];
      case 5: // Vietsub
        return [
          _buildShelfSliver(
            'Phim Vietsub mới nhất',
            'phim-vietsub',
            isLandscape: true,
          ),
          _buildGenreShelfSliver('Phim bộ Vietsub', 'phim-bo'),
          _buildGenreShelfSliver('Phim lẻ Vietsub', 'phim-le'),
        ];
      case 6: // Thuyết minh
        return [
          _buildShelfSliver(
            'Phim Thuyết minh mới nhất',
            'phim-thuyet-minh',
            isLandscape: true,
          ),
          _buildGenreShelfSliver('Phim bộ Thuyết minh', 'phim-bo'),
          _buildGenreShelfSliver('Phim lẻ Thuyết minh', 'phim-le'),
        ];
      default:
        return _buildDiscoverShelves();
    }
  }

  List<Widget> _buildFeaturedDiscoverSections() {
    final latestAsync = ref.watch(
      filmsByTypeProvider((
        typeSlug: 'phim-moi-cap-nhat',
        page: 1,
        sortField: null,
        year: null,
      )),
    );
    final hotAsync = ref.watch(
      filmsByTypeProvider((
        typeSlug: 'phim-moi-cap-nhat',
        page: 1,
        sortField: 'view',
        year: DateTime.now().year,
      )),
    );

    final featuredFilmsAsync = latestAsync.when(
      data: (latestRes) => hotAsync.when(
        data: (hotRes) {
          final hotItems = hotRes.data?.items ?? [];
          final latestItems = latestRes.data?.items ?? [];
          final hotSlugs = hotItems.map((e) => e.slug).toSet();
          final merged = [
            ...hotItems,
            ...latestItems.where((item) => !hotSlugs.contains(item.slug)),
          ];

          return AsyncValue.data(
            FilmListResponse(
              status: latestRes.status,
              data: FilmListData(
                items: merged,
                appDomainCdnImage: latestRes.data?.appDomainCdnImage,
              ),
            ),
          );
        },
        loading: () => AsyncValue.data(latestRes),
        error: (_, _) => AsyncValue.data(latestRes),
      ),
      loading: () => const AsyncValue<FilmListResponse>.loading(),
      error: (e, s) => AsyncValue<FilmListResponse>.error(e, s),
    );

    return [
      _buildBaseShelfSliver('MỚI CẬP NHẬT', featuredFilmsAsync, true),
      _buildGenreShelfSliver('PHIM HÀNH ĐỘNG', 'hanh-dong'),
      _buildGenreShelfSliver('PHIM TÌNH CẢM', 'tinh-cam'),
      _buildGenreShelfSliver('PHIM KINH DỊ', 'kinh-di'),
      _buildShelfSliver('PHIM HOẠT HÌNH', 'hoat-hinh', isLandscape: true),
    ];
  }

  List<Widget> _buildDiscoverShelves() {
    return [
      _buildShelfSliver('MỚI CẬP NHẬT', 'phim-moi-cap-nhat', isLandscape: true),
      _buildGenreShelfSliver('PHIM HÀNH ĐỘNG', 'hanh-dong'),
      _buildGenreShelfSliver('PHIM TÌNH CẢM', 'tinh-cam'),
      _buildGenreShelfSliver('PHIM KINH DỊ', 'kinh-di'),
      _buildShelfSliver('PHIM HOẠT HÌNH', 'hoat-hinh', isLandscape: true),
    ];
  }

  Widget _buildShelfSliver(
    String title,
    String typeSlug, {
    bool isLandscape = false,
  }) {
    final filmsAsync = ref.watch(
      filmsByTypeProvider((
        typeSlug: typeSlug,
        page: 1,
        sortField: null,
        year: null,
      )),
    );

    return _buildBaseShelfSliver(title, filmsAsync, isLandscape);
  }

  Widget _buildGenreShelfSliver(
    String title,
    String genreSlug, {
    bool isLandscape = false,
  }) {
    final filmsAsync = ref.watch(
      filmsByGenreProvider((slug: genreSlug, page: 1)),
    );

    return _buildBaseShelfSliver(title, filmsAsync, isLandscape);
  }

  Widget _buildBaseShelfSliver(
    String title,
    AsyncValue<FilmListResponse> filmsAsync,
    bool isLandscape,
  ) {
    return SliverToBoxAdapter(
      child: filmsAsync.when(
        data: (response) {
          final items = response.data?.items ?? [];
          if (_focusedFilm == null && items.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _focusedFilm == null) {
                setState(() => _focusedFilm = items.first);
              }
            });
          }
          return TvShelf(
            title: title,
            items: items,
            onFilmTap: (film) => context.push('/detail/${film.slug}'),
            onFilmFocused: (film) => setState(() => _focusedFilm = film),
            isLarge: isLandscape,
          );
        },
        loading: () => const SizedBox(height: 350),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildHistorySection() {
    final historyAsync = ref.watch(watchHistoryProvider);

    return SliverToBoxAdapter(
      child: historyAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return _buildEmptyState(
              Icons.history_rounded,
              'Chưa có lịch sử xem',
            );
          }
          final items = entries
              .map(
                (e) => FilmItem(
                  slug: e.slug,
                  name: e.name,
                  originName: e.originName,
                  thumbUrl: e.thumbUrl,
                  episodeCurrent: e.episode,
                ),
              )
              .toList();

          if (_focusedFilm == null && items.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _focusedFilm == null) {
                setState(() => _focusedFilm = items.first);
              }
            });
          }
          return TvShelf(
            title: 'Đã xem gần đây',
            items: items,
            onFilmTap: (film) => context.push('/detail/${film.slug}'),
            onFilmFocused: (film) => setState(() => _focusedFilm = film),
            isLarge: true,
          );
        },
        loading: () => const SizedBox(height: 400),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildFavoritesSection() {
    final favoritesAsync = ref.watch(favoritesProvider);

    return SliverToBoxAdapter(
      child: favoritesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return _buildEmptyState(
              Icons.favorite_rounded,
              'Chưa có phim yêu thích',
            );
          }
          final items = entries
              .map(
                (e) => FilmItem(
                  slug: e.slug,
                  name: e.name,
                  originName: e.originName,
                  thumbUrl: e.thumbUrl,
                ),
              )
              .toList();

          if (_focusedFilm == null && items.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _focusedFilm == null) {
                setState(() => _focusedFilm = items.first);
              }
            });
          }
          return TvShelf(
            title: 'Danh sách yêu thích',
            items: items,
            onFilmTap: (film) => context.push('/detail/${film.slug}'),
            onFilmFocused: (film) => setState(() => _focusedFilm = film),
            isLarge: true,
          );
        },
        loading: () => const SizedBox(height: 400),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 120),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.15), size: 80),
            const SizedBox(height: 24),
            Text(
              message,
              style: TvDesignSystem.titleLarge.copyWith(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Hero Background ───

  Widget _buildHeroBackground() {
    final imageUrl = _focusedFilm?.fullPosterUrl.isNotEmpty == true
        ? _focusedFilm!.fullPosterUrl
        : (_focusedFilm?.fullThumbUrl ?? '');

    return RepaintBoundary(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        child: Stack(
          key: ValueKey(imageUrl + (_focusedFilm?.slug ?? 'bg')),
          fit: StackFit.expand,
          children: [
            if (imageUrl.isNotEmpty)
              AppImage(imageUrl: imageUrl, boxFit: BoxFit.cover)
            else
              Container(color: TvDesignSystem.background),

            // Simplified gradient overlay (2 layers instead of 3)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.5),
                    TvDesignSystem.background,
                  ],
                  stops: const [0.0, 0.4, 0.95],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    TvDesignSystem.background.withValues(alpha: 0.95),
                    TvDesignSystem.background.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !_isSidebarFocused,
        child: AnimatedContainer(
          duration: TvDesignSystem.durationMedium,
          curve: TvDesignSystem.curveFluid,
          // Use solid dark overlay instead of BackdropFilter (too heavy for TV GPU)
          color: _isSidebarFocused
              ? Colors.black.withValues(alpha: 0.7)
              : Colors.transparent,
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:catalog/catalog.dart';
import '../../shared/desktop_design_system.dart';
import '../../shared/widgets/desktop_film_shelf.dart';

class DesktopHomePage extends ConsumerStatefulWidget {
  const DesktopHomePage({super.key});

  @override
  ConsumerState<DesktopHomePage> createState() => _DesktopHomePageState();
}

class _DesktopHomePageState extends ConsumerState<DesktopHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _backdropUrl;
  FilmItem? _heroFilm;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: AppConstants.filmTypes.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fetch featured films for hero
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

    // Merge hot + latest
    final featuredAsync = latestAsync.when(
      data: (latestRes) => hotAsync.when(
        data: (hotRes) {
          final hotItems = hotRes.data?.items ?? [];
          final latestItems = latestRes.data?.items ?? [];
          final hotSlugs = hotItems.map((e) => e.slug).toSet();
          final merged = [
            ...hotItems,
            ...latestItems.where((item) => !hotSlugs.contains(item.slug)),
          ];
          return AsyncValue.data(merged);
        },
        loading: () =>
            AsyncValue.data(latestRes.data?.items ?? <FilmItem>[]),
        error: (_, _) =>
            AsyncValue.data(latestRes.data?.items ?? <FilmItem>[]),
      ),
      loading: () => const AsyncValue<List<FilmItem>>.loading(),
      error: (e, s) => AsyncValue<List<FilmItem>>.error(e, s),
    );

    // Auto-set hero film
    featuredAsync.whenData((films) {
      if (_heroFilm == null && films.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _heroFilm == null) {
            setState(() {
              _heroFilm = films.first;
              _backdropUrl = films.first.fullThumbUrl;
            });
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Dynamic blurred background
          if (_backdropUrl != null)
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                child: AppImage(
                  key: ValueKey(_backdropUrl),
                  imageUrl: _backdropUrl!,
                  boxFit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),

          // Main content
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverOverlapAbsorber(
                  handle:
                      NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  sliver: SliverAppBar(
                    expandedHeight: 480,
                    pinned: true,
                    stretch: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    toolbarHeight: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      stretchModes: const [StretchMode.zoomBackground],
                      background: _buildHeroSection(featuredAsync),
                    ),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(56),
                      child: ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: innerBoxIsScrolled ? 30 : 0,
                            sigmaY: innerBoxIsScrolled ? 30 : 0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: innerBoxIsScrolled
                                  ? Colors.black.withValues(alpha: 0.4)
                                  : Colors.transparent,
                              border: Border(
                                bottom: BorderSide(
                                  color: innerBoxIsScrolled
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.transparent,
                                ),
                              ),
                            ),
                            child: _buildTabBar(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: AppConstants.filmTypes.map((type) {
                return Builder(
                  builder: (context) {
                    return CustomScrollView(
                      slivers: [
                        SliverOverlapInjector(
                          handle:
                              NestedScrollView.sliverOverlapAbsorberHandleFor(
                                  context),
                        ),
                        SliverToBoxAdapter(
                          child: _DesktopFilmTypeTab(
                              typeSlug: type['slug']!),
                        ),
                      ],
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.fromLTRB(80, 8, 32, 8),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.4),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        padding: const EdgeInsets.all(4),
        tabs: AppConstants.filmTypes.map((type) {
          return Tab(
            height: 34,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(type['title']!),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeroSection(AsyncValue<List<FilmItem>> featuredAsync) {
    return featuredAsync.when(
      data: (films) {
        if (films.isEmpty) return const SizedBox();
        final film = _heroFilm ?? films.first;
        return _buildHeroContent(film);
      },
      loading: () => const SizedBox(),
      error: (_, _) => const SizedBox(),
    );
  }

  Widget _buildHeroContent(FilmItem film) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        AppImage(imageUrl: film.fullThumbUrl, boxFit: BoxFit.cover),
        // Left gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.black.withValues(alpha: 0.85),
                Colors.black.withValues(alpha: 0.4),
                Colors.transparent,
              ],
            ),
          ),
        ),
        // Bottom gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.9),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5],
            ),
          ),
        ),
        // Content
        Positioned(
          left: 80,
          bottom: 80,
          right: MediaQuery.of(context).size.width * 0.4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                film.name ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (film.originName != null) ...[
                const SizedBox(height: 4),
                Text(
                  film.originName!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Tags
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (film.quality != null) _tagItem(film.quality!),
                  if (film.lang != null) _tagItem(film.lang!),
                  if (film.episodeCurrent != null)
                    _tagItem(film.episodeCurrent!),
                  if (film.year != null) _tagItem('${film.year}'),
                ],
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                children: [
                  _actionButton(
                    label: 'Xem Phim',
                    icon: Icons.play_arrow_rounded,
                    filled: true,
                    onTap: () => context.push('/detail/${film.slug}'),
                  ),
                  const SizedBox(width: 12),
                  _actionButton(
                    label: 'Thông tin',
                    icon: Icons.info_outline_rounded,
                    filled: false,
                    onTap: () => context.push('/detail/${film.slug}'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tagItem(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: filled
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: !filled
                ? Border.all(color: Colors.white.withValues(alpha: 0.15))
                : null,
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: filled ? Colors.black : Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: filled ? Colors.black : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tab Content ───

class _DesktopFilmTypeTab extends ConsumerWidget {
  final String typeSlug;
  const _DesktopFilmTypeTab({required this.typeSlug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (typeSlug == 'phim-moi-cap-nhat') {
      return const _NetflixDashboard();
    }
    return _PaginatedGridView(typeSlug: typeSlug);
  }
}

class _NetflixDashboard extends ConsumerWidget {
  const _NetflixDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilmSection(title: 'MỚI CẬP NHẬT', slug: 'phim-moi-cap-nhat'),
        _FilmSection(
            title: 'PHIM HÀNH ĐỘNG', slug: 'hanh-dong', isGenre: true),
        _FilmSection(
            title: 'PHIM TÌNH CẢM', slug: 'tinh-cam', isGenre: true),
        _FilmSection(
            title: 'PHIM KINH DỊ', slug: 'kinh-di', isGenre: true),
        _FilmSection(title: 'PHIM HOẠT HÌNH', slug: 'hoat-hinh'),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _FilmSection extends ConsumerWidget {
  final String title;
  final String slug;
  final bool isGenre;

  const _FilmSection({
    required this.title,
    required this.slug,
    this.isGenre = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filmsAsync = ref.watch(
      isGenre
          ? filmsByGenreProvider((slug: slug, page: 1))
          : filmsByTypeProvider((
              typeSlug: slug,
              page: 1,
              sortField: null,
              year: null,
            )),
    );

    return filmsAsync.when(
      data: (res) {
        final items = res.data?.items ?? [];
        return DesktopFilmShelf(
          title: title,
          items: items,
          onFilmTap: (film) => context.push('/detail/${film.slug}'),
        );
      },
      loading: () => const SizedBox(height: 320),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _PaginatedGridView extends ConsumerWidget {
  final String typeSlug;
  const _PaginatedGridView({required this.typeSlug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filmListState = ref.watch(
      paginatedFilmsProvider(
        FilmFilterParams(slug: typeSlug, source: PaginatedSource.type),
      ),
    );

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 400) {
            ref
                .read(
                  paginatedFilmsProvider(
                    FilmFilterParams(
                      slug: typeSlug,
                      source: PaginatedSource.type,
                    ),
                  ).notifier,
                )
                .loadMore();
          }
        }
        return false;
      },
      child: Column(
        children: [
          const SizedBox(height: 24),
          if (filmListState.items.isEmpty && filmListState.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 80),
              child: Center(
                child: CircularProgressIndicator(color: DS.primary),
              ),
            )
          else if (filmListState.items.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80),
              child: FilmGrid(
                films: filmListState.items,
                childAspectRatio: 0.55,
                crossAxisCount: 6,
                onFilmTap: (film) =>
                    context.push('/detail/${film.slug}'),
              ),
            ),
            if (filmListState.isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(color: DS.primary),
                ),
              ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

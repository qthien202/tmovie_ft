import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import 'widgets/film_carousel.dart';
import 'widgets/home_tab_view.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _currentBackdropUrl;

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
    // Lấy phim mới nhất + phim hot rồi trộn lại
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

    // Trộn 2 danh sách: hot trước, mới nhất sau, loại trùng
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
          return AsyncValue.data(merged);
        },
        loading: () => AsyncValue.data(latestRes.data?.items ?? <FilmItem>[]),
        error: (_, _) => AsyncValue.data(latestRes.data?.items ?? <FilmItem>[]),
      ),
      loading: () => const AsyncValue<List<FilmItem>>.loading(),
      error: (e, s) => AsyncValue<List<FilmItem>>.error(e, s),
    );
    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          // Dynamic Blurred Background
          Positioned.fill(
            child: _currentBackdropUrl != null
                ? AnimatedSwitcher(
                    duration: const Duration(milliseconds: 800),
                    child: AppImage(
                      key: ValueKey(_currentBackdropUrl),
                      imageUrl: _currentBackdropUrl!,
                      boxFit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                : const SizedBox(),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(color: Colors.black.withValues(alpha: 0.15)),
            ),
          ),

          // Main Content
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverOverlapAbsorber(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                    context,
                  ),
                  sliver: SliverAppBar(
                    expandedHeight: MediaQuery.of(context).size.height * 0.75,
                    pinned: true,
                    stretch: true,
                    primary: false,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    toolbarHeight: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      stretchModes: const [
                        StretchMode.zoomBackground,
                        StretchMode.blurBackground,
                      ],
                      background: LayoutBuilder(
                        builder: (context, constraints) {
                          final expandedHeight =
                              MediaQuery.of(context).size.height * 0.75;
                          final collapsedHeight = 60.5 + topPadding;

                          final double t =
                              ((constraints.maxHeight - collapsedHeight) /
                                      (expandedHeight - collapsedHeight))
                                  .clamp(0.0, 1.0);

                          // Carousel sẽ biến mất HOÀN TOÀN trước khi Header thu vào trạng thái Sticky
                          // t = 1.0 (mở), t = 0.0 (đóng)
                          // Ở đây t > 0.4 Carousel mới hiện, dưới 0.4 là mờ hẳn.
                          final opacity = ((t - 0.4) / 0.6).clamp(0.0, 1.0);

                          return Opacity(
                            opacity: opacity,
                            child: Container(
                              padding: EdgeInsets.only(
                                top: topPadding,
                                bottom: 85,
                              ),
                              child: Center(
                                child: SingleChildScrollView(
                                  physics: const NeverScrollableScrollPhysics(),
                                  child: featuredFilmsAsync.when(
                                    data: (films) => FilmCarousel(
                                      films: films,
                                      autoPlay: !innerBoxIsScrolled,
                                      onActiveFilmChanged: (film) {
                                        if (mounted) {
                                          setState(() {
                                            _currentBackdropUrl =
                                                film.fullThumbUrl;
                                          });
                                        }
                                      },
                                    ),
                                    loading: () =>
                                        const FilmCarouselSkeleton(),
                                    error: (e, s) => const SizedBox(),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottom: PreferredSize(
                      preferredSize: Size.fromHeight(60 + topPadding + 0.5),
                      child: ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: innerBoxIsScrolled ? 40 : 0,
                            sigmaY: innerBoxIsScrolled ? 40 : 0,
                          ),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              // Nền sáng hơn, trong suốt hơn để giữ vẻ sang trọng của Glassmorphism
                              color: innerBoxIsScrolled
                                  ? Colors.black.withValues(alpha: 0.3)
                                  : Colors.transparent,
                              border: Border(
                                bottom: BorderSide(
                                  color: innerBoxIsScrolled
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.transparent,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: topPadding),
                                Container(
                                  height: 60,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: TabBar(
                                    controller: _tabController,
                                    isScrollable: true,
                                    tabAlignment: TabAlignment.start,
                                    indicatorSize: TabBarIndicatorSize.tab,
                                    indicator: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 15,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    dividerColor: Colors.transparent,
                                    labelColor: Colors.white,
                                    unselectedLabelColor: Colors.white
                                        .withValues(alpha: 0.5),
                                    labelStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    tabs: AppConstants.filmTypes.map((type) {
                                      return Tab(
                                        height: 36,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Text(type['title']!),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
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
                                context,
                              ),
                        ),
                        SliverToBoxAdapter(
                          child: FilmTypeTab(typeSlug: type['slug']!),
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

}

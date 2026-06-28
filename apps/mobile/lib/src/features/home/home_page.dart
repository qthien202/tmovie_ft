import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:catalog/catalog.dart';
import 'widgets/cinematic_hero.dart';
import 'widgets/home_tab_view.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
  @override
  Widget build(BuildContext context) {
    // Hero ưu tiên phim Hàn/Trung/Âu Mỹ rating cao của năm nay.
    final featuredFilmsAsync = ref.watch(heroFilmsProvider);

    final heroHeight = MediaQuery.sizeOf(context).height * 0.62;
    const tabBarHeight = 56.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                expandedHeight: heroHeight,
                pinned: true,
                stretch: true,
                // primary:true reserves the status-bar inset so the pinned
                // TabBar clears the notch when collapsed; the hero still
                // bleeds full-screen behind the status bar via flexibleSpace.
                primary: true,
                backgroundColor: AppColors.backgroundColor,
                elevation: 0,
                toolbarHeight: 0,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  stretchModes: const [StretchMode.zoomBackground],
                  background: featuredFilmsAsync.when(
                    data: (films) => films.isEmpty
                        ? const SizedBox()
                        : CinematicHero(
                            films: films,
                            autoPlay: !innerBoxIsScrolled,
                            contentBottomInset: tabBarHeight + AppSpacing.sm,
                          ),
                    loading: () => const _HeroSkeleton(),
                    error: (e, s) => const SizedBox(),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(tabBarHeight),
                  child: Container(
                    height: tabBarHeight,
                    alignment: Alignment.centerLeft,
                    color: innerBoxIsScrolled
                        ? AppColors.backgroundColor
                        : Colors.transparent,
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        color: AppColors.primaryValue,
                      ),
                      indicatorPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                      ),
                      dividerColor: Colors.transparent,
                      labelColor: AppColors.onPrimary,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: AppTypography.labelMedium,
                      unselectedLabelStyle: AppTypography.labelMedium,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      tabs: AppConstants.filmTypes.map((type) {
                        return Tab(
                          height: 38,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(type['title']!),
                          ),
                        );
                      }).toList(),
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
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
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
          // Floating search icon (top-right over the hero) → global search.
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 16,
            child: const _HomeSearchButton(),
          ),
        ],
      ),
    );
  }
}

/// Frosted circular search button shown over the home hero.
class _HomeSearchButton extends StatelessWidget {
  const _HomeSearchButton();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: Colors.black.withValues(alpha: 0.28),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => context.push('/search'),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.search_rounded, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surfaceColor, AppColors.backgroundColor],
        ),
      ),
    );
  }
}

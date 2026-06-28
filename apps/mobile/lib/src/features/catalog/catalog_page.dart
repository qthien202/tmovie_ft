import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:catalog/catalog.dart';

/// Unified **browse + search** screen.
///
/// One page powers three entry points — the *Phim lẻ* root tab, the
/// `/film-list/:typeSlug` "see all" rails, and the global `/search` — so the
/// category and search experiences share a single polished UI and one fancy
/// filter sheet (sort · type · genre · country · year).
class CatalogPage extends ConsumerStatefulWidget {
  /// Type / genre / country slug this page opens on (null = discover/search).
  final String? initialTypeSlug;
  final String title;

  /// Root bottom-nav tabs have nothing to pop, so the back button is hidden.
  final bool isRootTab;

  /// Open with the keyboard up (used by the `/search` entry point).
  final bool autofocusSearch;

  const CatalogPage({
    super.key,
    this.initialTypeSlug,
    required this.title,
    this.isRootTab = false,
    this.autofocusSearch = false,
  });

  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  String? _searchQuery;
  final Set<String> _selectedGenres = {};
  final Set<String> _selectedCountries = {};
  String? _selectedYear;
  String? _selectedSort; // null = mới cập nhật (default)
  String? _selectedType; // null = tất cả (phim-moi-cap-nhat)

  static const _types = <({String name, String? slug})>[
    (name: 'Tất cả', slug: null),
    (name: 'Phim bộ', slug: 'phim-bo'),
    (name: 'Phim lẻ', slug: 'phim-le'),
    (name: 'TV Shows', slug: 'tv-shows'),
    (name: 'Hoạt hình', slug: 'hoat-hinh'),
  ];

  static const _sorts = <({String name, String? slug, IconData icon})>[
    (name: 'Mới cập nhật', slug: null, icon: Icons.schedule_rounded),
    (name: 'Phổ biến', slug: 'view', icon: Icons.local_fire_department_rounded),
    (name: 'Năm mới nhất', slug: 'year', icon: Icons.event_rounded),
  ];

  static const _genres = <({String name, String slug})>[
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

  static const _countries = <({String name, String slug})>[
    (name: 'Trung Quốc', slug: 'trung-quoc'),
    (name: 'Hàn Quốc', slug: 'han-quoc'),
    (name: 'Âu Mỹ', slug: 'au-my'),
    (name: 'Nhật Bản', slug: 'nhat-ban'),
    (name: 'Thái Lan', slug: 'thai-lan'),
    (name: 'Việt Nam', slug: 'viet-nam'),
    (name: 'Hồng Kông', slug: 'hong-kong'),
    (name: 'Đài Loan', slug: 'dai-loan'),
  ];

  late final List<({String name, String slug})> _years = List.generate(
    14,
    (i) {
      final year = DateTime.now().year - i;
      return (name: '$year', slug: '$year');
    },
  );

  @override
  void initState() {
    super.initState();
    final slug = widget.initialTypeSlug;
    if (slug == null) return;
    // Resolve the opening slug into the right filter dimension so a "see all"
    // on a genre/country rail lands pre-filtered.
    if (_genres.any((g) => g.slug == slug)) {
      _selectedGenres.add(slug);
    } else if (_countries.any((c) => c.slug == slug)) {
      _selectedCountries.add(slug);
    } else {
      _selectedType = slug;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = value.trim().isEmpty ? null : value.trim();
        // A typed query takes over — clear structured filters to avoid a
        // confusing mixed state.
        if (_searchQuery != null) {
          _selectedGenres.clear();
          _selectedCountries.clear();
          _selectedYear = null;
        }
      });
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _debounce?.cancel();
    setState(() => _searchQuery = null);
  }

  void _setSort(String? slug) {
    setState(() {
      _selectedSort = slug;
      _searchQuery = null;
      _searchController.clear();
    });
  }

  int get _activeFilterCount =>
      _selectedGenres.length +
      _selectedCountries.length +
      (_selectedYear != null ? 1 : 0) +
      (_selectedType != null ? 1 : 0);

  /// Build the right provider for the current selection (search vs. browse).
  dynamic _resolveProvider() {
    if (_searchQuery != null) {
      return paginatedSearchFilmsProvider(_searchQuery!);
    }
    final int? year = _selectedYear != null
        ? int.tryParse(_selectedYear!)
        : null;

    if (_selectedGenres.length == 1 && _selectedCountries.length <= 1) {
      return paginatedFilmsProvider(
        FilmFilterParams(
          slug: _selectedGenres.first,
          source: PaginatedSource.genre,
          country: _selectedCountries.firstOrNull,
          year: year,
          sortField: _selectedSort,
        ),
      );
    }
    if (_selectedCountries.length == 1 && _selectedGenres.length <= 1) {
      return paginatedFilmsProvider(
        FilmFilterParams(
          slug: _selectedCountries.first,
          source: PaginatedSource.country,
          category: _selectedGenres.firstOrNull,
          year: year,
          sortField: _selectedSort,
        ),
      );
    }
    return paginatedFilmsProvider(
      FilmFilterParams(
        slug: _selectedType ?? 'phim-moi-cap-nhat',
        source: PaginatedSource.type,
        category: _selectedGenres.firstOrNull,
        country: _selectedCountries.firstOrNull,
        year: year,
        sortField: _selectedSort,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = _resolveProvider();
    final state = ref.watch(provider);
    final firstFilm = state.items.isNotEmpty ? state.items.first : null;
    final searching = _searchQuery != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          // Cinematic blurred backdrop pulled from the first result.
          if (firstFilm != null)
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 700),
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
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.backgroundColor.withValues(alpha: 0.72),
                      AppColors.backgroundColor.withValues(alpha: 0.92),
                      AppColors.backgroundColor,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                if (!searching) _buildQuickRow(),
                if (!searching && _activeFilterCount > 0) _buildActiveChips(),
                Expanded(child: _buildResults(provider, state)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header: back · title · search · filter ──────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (!widget.isRootTab) ...[
                _SquareIconButton(
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
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _searchController,
                  hint: 'Tìm phim, diễn viên...',
                  prefixIcon: Icons.search_rounded,
                  autofocus: widget.autofocusSearch,
                  textInputAction: TextInputAction.search,
                  onChanged: (v) {
                    setState(() {});
                    _onSearchChanged(v);
                  },
                  onClear: _searchController.text.isNotEmpty ? _clearSearch : null,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _SquareIconButton(
                icon: Icons.tune_rounded,
                onTap: _openFilterSheet,
                badgeCount: _activeFilterCount,
                highlight: _activeFilterCount > 0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Quick sort row (inline, browse-mode only) ───────────────────────────
  Widget _buildQuickRow() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: _sorts.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, i) {
            final s = _sorts[i];
            return AppChip(
              label: s.name,
              icon: s.icon,
              selected: _selectedSort == s.slug,
              onTap: () => _setSort(s.slug),
            );
          },
        ),
      ),
    );
  }

  // ── Active filter chips (removable) ─────────────────────────────────────
  Widget _buildActiveChips() {
    final chips = <({String label, VoidCallback onRemove})>[];
    if (_selectedType != null) {
      final name = _types.firstWhere((t) => t.slug == _selectedType).name;
      chips.add((
        label: name,
        onRemove: () => setState(() => _selectedType = null),
      ));
    }
    for (final slug in _selectedGenres) {
      final name = _genres.firstWhere((g) => g.slug == slug).name;
      chips.add((
        label: name,
        onRemove: () => setState(() => _selectedGenres.remove(slug)),
      ));
    }
    for (final slug in _selectedCountries) {
      final name = _countries.firstWhere((c) => c.slug == slug).name;
      chips.add((
        label: name,
        onRemove: () => setState(() => _selectedCountries.remove(slug)),
      ));
    }
    if (_selectedYear != null) {
      chips.add((
        label: _selectedYear!,
        onRemove: () => setState(() => _selectedYear = null),
      ));
    }

    return Container(
      height: 46,
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          if (i == chips.length) {
            return TextButton(
              onPressed: () => setState(() {
                _selectedGenres.clear();
                _selectedCountries.clear();
                _selectedYear = null;
                _selectedType = null;
              }),
              child: Text(
                'Xóa hết',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }
          final c = chips[i];
          return _RemovableChip(label: c.label, onRemove: c.onRemove);
        },
      ),
    );
  }

  // ── Results grid ─────────────────────────────────────────────────────────
  Widget _buildResults(dynamic provider, FilmListState state) {
    if (state.items.isEmpty && state.isLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          0,
        ),
        child: FilmGridSkeleton(),
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return _buildErrorState(provider);
    }

    if (state.items.isEmpty) {
      return _buildEmptyState();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollEndNotification &&
            n.metrics.pixels >= n.metrics.maxScrollExtent - 400) {
          ref.read(provider.notifier).loadMore();
        }
        return false;
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: FilmGrid.asSliver(
              films: state.items,
              onFilmTap: (film) => context.push('/detail/${film.slug}'),
            ),
          ),
          if (state.hasMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  0,
                ),
                child: FilmGridSkeleton(count: 3),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 56,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Không tìm thấy nội dung phù hợp',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (_searchQuery != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '"$_searchQuery"',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.primaryValue,
              ),
            ),
          ],
        ],
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
            size: 56,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Có lỗi xảy ra', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Thử lại',
            onPressed: () => ref.read(provider.notifier).loadFirstPage(),
          ),
        ],
      ),
    );
  }

  // ── Filter sheet ─────────────────────────────────────────────────────────
  Future<void> _openFilterSheet() async {
    FocusScope.of(context).unfocus();
    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => _FilterSheet(
        types: _types,
        sorts: _sorts,
        genres: _genres,
        countries: _countries,
        years: _years,
        initialType: _selectedType,
        initialSort: _selectedSort,
        initialGenres: _selectedGenres,
        initialCountries: _selectedCountries,
        initialYear: _selectedYear,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _selectedType = result.type;
      _selectedSort = result.sort;
      _selectedYear = result.year;
      _selectedGenres
        ..clear()
        ..addAll(result.genres);
      _selectedCountries
        ..clear()
        ..addAll(result.countries);
      // Applying structured filters supersedes any typed query.
      _searchQuery = null;
      _searchController.clear();
    });
  }
}

/// Token-styled square icon button used in the header (search/filter/back).
class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;
  final bool highlight;

  const _SquareIconButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: highlight
              ? AppColors.primaryValue.withValues(alpha: 0.16)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: highlight ? AppColors.primaryValue : AppColors.border,
                ),
              ),
              child: Icon(
                icon,
                color: highlight
                    ? AppColors.primaryValue
                    : AppColors.textPrimary,
                size: AppSizes.iconMd,
              ),
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              decoration: BoxDecoration(
                color: AppColors.primaryValue,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.backgroundColor, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                '$badgeCount',
                textAlign: TextAlign.center,
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

/// A teal-tinted removable chip used in the active-filter row.
class _RemovableChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _RemovableChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryValue.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: AppColors.primaryValue.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primaryValue,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.close_rounded,
                size: 15,
                color: AppColors.primaryValue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Selections returned from the filter sheet on "Áp dụng".
class _FilterResult {
  final String? type;
  final String? sort;
  final String? year;
  final Set<String> genres;
  final Set<String> countries;
  const _FilterResult({
    required this.type,
    required this.sort,
    required this.year,
    required this.genres,
    required this.countries,
  });
}

class _FilterSheet extends StatefulWidget {
  final List<({String name, String? slug})> types;
  final List<({String name, String? slug, IconData icon})> sorts;
  final List<({String name, String slug})> genres;
  final List<({String name, String slug})> countries;
  final List<({String name, String slug})> years;
  final String? initialType;
  final String? initialSort;
  final Set<String> initialGenres;
  final Set<String> initialCountries;
  final String? initialYear;

  const _FilterSheet({
    required this.types,
    required this.sorts,
    required this.genres,
    required this.countries,
    required this.years,
    required this.initialType,
    required this.initialSort,
    required this.initialGenres,
    required this.initialCountries,
    required this.initialYear,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _type = widget.initialType;
  late String? _sort = widget.initialSort;
  late String? _year = widget.initialYear;
  late final Set<String> _genres = {...widget.initialGenres};
  late final Set<String> _countries = {...widget.initialCountries};

  int get _count =>
      _genres.length +
      _countries.length +
      (_year != null ? 1 : 0) +
      (_type != null ? 1 : 0);

  void _reset() => setState(() {
    _type = null;
    _sort = null;
    _year = null;
    _genres.clear();
    _countries.clear();
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.md),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Text('Bộ lọc', style: AppTypography.titleLarge),
                if (_count > 0) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryValue.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '$_count',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primaryValue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                TextButton(
                  onPressed: _count == 0 ? null : _reset,
                  child: Text(
                    'Đặt lại',
                    style: AppTypography.labelMedium.copyWith(
                      color: _count == 0
                          ? AppColors.textTertiary
                          : AppColors.primaryValue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('Sắp xếp'),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: widget.sorts.map((s) {
                      return AppChip(
                        label: s.name,
                        icon: s.icon,
                        selected: _sort == s.slug,
                        onTap: () => setState(() => _sort = s.slug),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _SectionLabel('Loại phim'),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: widget.types.map((t) {
                      return AppChip(
                        label: t.name,
                        selected: _type == t.slug,
                        onTap: () => setState(() => _type = t.slug),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _SectionLabel('Thể loại'),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: widget.genres.map((g) {
                      final on = _genres.contains(g.slug);
                      return AppChip(
                        label: g.name,
                        selected: on,
                        onTap: () => setState(() {
                          on ? _genres.remove(g.slug) : _genres.add(g.slug);
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _SectionLabel('Quốc gia'),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: widget.countries.map((c) {
                      final on = _countries.contains(c.slug);
                      return AppChip(
                        label: c.name,
                        selected: on,
                        onTap: () => setState(() {
                          on
                              ? _countries.remove(c.slug)
                              : _countries.add(c.slug);
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _SectionLabel('Năm phát hành'),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: widget.years.map((y) {
                      final on = _year == y.slug;
                      return AppChip(
                        label: y.name,
                        selected: on,
                        onTap: () => setState(() => _year = on ? null : y.slug),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          // Apply
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surfaceColor,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: SafeArea(
              top: false,
              child: AppButton(
                label: _count == 0 ? 'Áp dụng' : 'Áp dụng ($_count)',
                expanded: true,
                size: AppButtonSize.lg,
                onPressed: () => Navigator.pop(
                  context,
                  _FilterResult(
                    type: _type,
                    sort: _sort,
                    year: _year,
                    genres: _genres,
                    countries: _countries,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small section heading with a teal accent bar.
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 15,
            decoration: BoxDecoration(
              color: AppColors.primaryValue,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

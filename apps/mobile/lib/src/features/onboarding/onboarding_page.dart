import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:design_system/design_system.dart';

class _OnboardingSlide {
  final String kicker;
  final String title;
  final String description;
  final String image;
  const _OnboardingSlide({
    required this.kicker,
    required this.title,
    required this.description,
    required this.image,
  });
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _kenBurns;
  int _currentPage = 0;

  static const _slides = <_OnboardingSlide>[
    _OnboardingSlide(
      kicker: 'KHO PHIM KHỔNG LỒ',
      title: 'Cả thế giới điện ảnh\ntrong túi bạn',
      description:
          'Hàng ngàn phim bộ, phim lẻ bom tấn — cập nhật mỗi ngày, sẵn sàng để xem.',
      image: 'assets/onboarding/onboarding_1.png',
    ),
    _OnboardingSlide(
      kicker: 'CHẤT LƯỢNG ĐỈNH CAO',
      title: 'Sắc nét đến\ntừng khung hình',
      description:
          'Hình ảnh 4K, phụ đề mượt mà, trải nghiệm như đang ngồi trong rạp.',
      image: 'assets/onboarding/onboarding_2.png',
    ),
    _OnboardingSlide(
      kicker: 'XEM MỌI LÚC MỌI NƠI',
      title: 'Tiếp tục xem\ntrên mọi thiết bị',
      description:
          'Lịch sử và danh sách yêu thích được đồng bộ — bắt đầu ở đây, xem tiếp ở bất cứ đâu.',
      image: 'assets/onboarding/onboarding_3.png',
    ),
  ];

  bool get _isLast => _currentPage == _slides.length - 1;

  @override
  void initState() {
    super.initState();
    // Slow Ken Burns zoom so the artwork feels alive without being flashy.
    _kenBurns = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _kenBurns.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Mark onboarding as seen so it never shows again, then head to login.
  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (mounted) context.go('/login');
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          // Background artwork with a gentle Ken Burns drift.
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final drift = index.isEven ? Alignment.topCenter : Alignment.bottomCenter;
              return AnimatedBuilder(
                animation: _kenBurns,
                builder: (context, child) {
                  final t = _kenBurns.value;
                  return Transform.scale(
                    scale: 1.05 + 0.08 * t,
                    alignment: drift,
                    child: child,
                  );
                },
                child: Image.asset(_slides[index].image, fit: BoxFit.cover),
              );
            },
          ),

          // Cinematic wash: keep the artwork up top, sink into the brand tone
          // at the bottom so text always reads.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.backgroundColor.withValues(alpha: 0.45),
                    AppColors.backgroundColor.withValues(alpha: 0.92),
                    AppColors.backgroundColor,
                  ],
                  stops: const [0.0, 0.42, 0.74, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand + Skip
                  Row(
                    children: [
                      _BrandMark(),
                      const Spacer(),
                      AnimatedOpacity(
                        opacity: _isLast ? 0 : 1,
                        duration: const Duration(milliseconds: 250),
                        child: TextButton(
                          onPressed: _isLast ? null : _finish,
                          child: Text(
                            'Bỏ qua',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Editorial, left-aligned copy that swaps per slide.
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    switchInCurve: Curves.easeOut,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.06),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Column(
                      key: ValueKey(_currentPage),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 22,
                              height: 2,
                              color: AppColors.primaryValue,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              slide.kicker,
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.primaryValue,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.6,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          slide.title,
                          style: AppTypography.displayLarge.copyWith(
                            fontSize: 34,
                            height: 1.12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          slide.description,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Progress pills
                  Row(
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        height: 4,
                        width: _currentPage == index ? 26 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primaryValue
                              : Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  AppButton(
                    label: _isLast ? 'Bắt đầu ngay' : 'Tiếp tục',
                    size: AppButtonSize.lg,
                    expanded: true,
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.primaryValue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: AppColors.onPrimary,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'TMovie',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

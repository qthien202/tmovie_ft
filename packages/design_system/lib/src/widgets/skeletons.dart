import 'package:flutter/material.dart';
import 'shimmer_loading.dart';

class FilmCardSkeleton extends StatelessWidget {
  const FilmCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: ShimmerLoading(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        ShimmerLoading(
          width: 80,
          height: 12,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        ShimmerLoading(
          width: 50,
          height: 10,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

class FilmGridSkeleton extends StatelessWidget {
  final int count;
  final int crossAxisCount;
  final double childAspectRatio;

  const FilmGridSkeleton({
    super.key,
    this.count = 6,
    this.crossAxisCount = 3,
    this.childAspectRatio = 0.55,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: count,
      itemBuilder: (context, index) => const FilmCardSkeleton(),
    );
  }
}

class FilmSectionSkeleton extends StatelessWidget {
  const FilmSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: ShimmerLoading(
            width: 150,
            height: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) => SizedBox(
              width: 145,
              height: 220,
              child: const FilmCardSkeleton(),
            ),
          ),
        ),
      ],
    );
  }
}

class FilmCarouselSkeleton extends StatelessWidget {
  const FilmCarouselSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final carouselHeight = screenHeight * 0.34;
    final cardWidth = screenWidth * 0.52;

    return Column(
      children: [
        const SizedBox(height: 35),
        // Slider Area
        SizedBox(
          height: carouselHeight,
          child: OverflowBox(
            maxWidth: screenWidth * 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Left Indicator
                Opacity(
                  opacity: 0.1,
                  child: Transform.scale(
                    scale: 0.72,
                    child: Container(
                      width: cardWidth,
                      height: carouselHeight,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                // Center Card
                Container(
                  width: cardWidth,
                  height: carouselHeight,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const ShimmerLoading(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
                // Right Indicator
                Opacity(
                  opacity: 0.1,
                  child: Transform.scale(
                    scale: 0.72,
                    child: Container(
                      width: cardWidth,
                      height: carouselHeight,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Info Section Skeleton
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              ShimmerLoading(
                width: screenWidth * 0.6,
                height: 24,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              ShimmerLoading(
                width: screenWidth * 0.4,
                height: 14,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 20),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ShimmerLoading(
                      height: 48,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShimmerLoading(
                      height: 48,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Indicator dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => Container(
                    width: index == 0 ? 20 : 6,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: Colors.white10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FilmDetailSkeleton extends StatelessWidget {
  const FilmDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoading(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.6,
            borderRadius: BorderRadius.zero,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(
                  width: 200,
                  height: 28,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ShimmerLoading(
                      width: 60,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(width: 12),
                    ShimmerLoading(
                      width: 80,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ShimmerLoading(
                  width: double.infinity,
                  height: 100,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

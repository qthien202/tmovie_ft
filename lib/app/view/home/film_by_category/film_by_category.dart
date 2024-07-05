import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../controller/filter/filter_controller.dart';
import '../../../controller/home/home_controller.dart';
import '../../../widgets/card_cinema/card_cinema.dart';

class FilmByCategory extends StatelessWidget {
  const FilmByCategory({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    return Obx(() {
      final int itemCount = controller.categories.length;

      return SliverList.separated(
        itemCount: itemCount,
        itemBuilder: (context, ind) {
          final PageController pageController =
              PageController(initialPage: 0, viewportFraction: 0.8);
          return Center(
            child: Container(
              color: GlobalColor.backgroundColor,
              width: MediaQuery.of(context).size.width < 600
                  ? MediaQuery.of(context).size.width
                  : MediaQuery.of(context).size.width * .85,
              child: Obx(
                () => Visibility(
                  visible: controller
                          .getFimCategory
                          .value[controller.categories[ind]['id']]
                          ?.pageProps
                          ?.data
                          ?.items
                          ?.isNotEmpty ==
                      true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              controller.categories[ind]['title']
                                  .toString()
                                  .toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            TextButton(
                              onHover: (hasFocus) {
                                controller.isFocusSeeAll.value = hasFocus;
                              },
                              onPressed: () {
                                final filter = Get.put(FilterController());
                                filter.selectedGenre.value =
                                    controller.categories[ind]['slug'] ?? "";
                                filter.selectedCountry.value =
                                    controller.categories[ind]['country'] ?? "";
                                filter.getFilmFilter();
                              },
                              child: const Text(
                                "Xem thêm >",
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.width < 600
                                ? MediaQuery.of(context).size.height * .45
                                : MediaQuery.of(context).size.height * .55,
                            child: Obx(() {
                              final isLoading =
                                  controller.getFimCategory.value.isEmpty ==
                                      true;
                              final items = controller
                                  .getFimCategory
                                  .value[controller.categories[ind]['id']]
                                  ?.pageProps
                                  ?.data
                                  ?.items;
                              return ListView.builder(
                                controller: pageController,
                                shrinkWrap: false,
                                scrollDirection: Axis.horizontal,
                                itemCount: isLoading
                                    ? 6
                                    : (controller
                                                    .getFimCategory
                                                    .value[controller
                                                        .categories[ind]['id']]
                                                    ?.pageProps
                                                    ?.data
                                                    ?.items
                                                    ?.length ??
                                                0) >
                                            10
                                        ? 10
                                        : (controller
                                                .getFimCategory
                                                .value[controller
                                                    .categories[ind]['id']]
                                                ?.pageProps
                                                ?.data
                                                ?.items
                                                ?.length ??
                                            0),
                                itemBuilder: (context, index) {
                                  final data = items?[index];
                                  return Visibility(
                                    visible: !isLoading &&
                                        data?.category?.first.slug != "phim-18",
                                    replacement: Visibility(
                                      visible: data?.category?.first.slug !=
                                          "phim-18",
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        child: SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              .5,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              .15,
                                          child: Shimmer.fromColors(
                                            baseColor: Colors.grey,
                                            highlightColor:
                                                Colors.grey.shade600,
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 10),
                                      child: CardCinema(
                                        nameProduct: data?.name,
                                        imageLink: data?.thumbUrl,
                                        originName: data?.originName,
                                        slug: data?.slug,
                                        path: controller
                                                .getFimCategory
                                                .value[controller
                                                    .categories[ind]['id']]
                                                ?.pageProps
                                                ?.data
                                                ?.typeList ??
                                            "",
                                      ),
                                    ),
                                  );
                                },
                              );
                            }),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.white,
                                  size: 25,
                                ),
                                onPressed: () {
                                  pageController.previousPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.ease);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_ios,
                                    color: Colors.white, size: 25),
                                onPressed: () {
                                  pageController.nextPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.ease);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: 10),
      );
    });
  }
}

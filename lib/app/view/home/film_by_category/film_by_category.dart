import 'package:app_ft_movies/app/view/home/card_cinema/card_cinema.dart';
import 'package:app_ft_movies/app/view/list_movie/list_movie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../controller/home/home_controller.dart';

class FilmByCategory extends StatelessWidget {
  const FilmByCategory({Key? key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    return Obx(() {
      return ListView.separated(
        itemCount: controller.categories.length,
        itemBuilder: (context, ind) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${controller.categories[ind]['title']}",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Obx(() {
                        return InkWell(
                          onFocusChange: (hasFocus) {
                            if (!hasFocus) {
                              controller.isFocusSeeAll.fillRange(
                                  0, controller.isFocusSeeAll.length, false);
                              return;
                            }
                            controller.isFocusSeeAll[ind] = true;

                            // print("isFocus: ${controller.isFocusSeeAll}");
                          },
                          onTap: () {
                            Get.to(ListMovieView(
                              category:
                                  controller.categories[ind]['slug'] ?? "",
                              slug: controller.pathFilm.value,
                              country:
                                  controller.categories[ind]['country'] ?? "",
                            ));
                          },
                          child: Container(
                            // alignment: Alignment.center,
                            // padding: const EdgeInsets.all(1),
                            margin: EdgeInsets.symmetric(horizontal: 10),
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                                color: controller.isFocusSeeAll[ind] == true
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius:
                                    controller.isFocusSeeAll[ind] == true
                                        ? BorderRadius.circular(16)
                                        : null),

                            child: Text(
                              "Xem thêm",
                              style: TextStyle(
                                color: controller.isFocusSeeAll[ind] == true
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                          ),
                        );
                      })
                    ],
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                SizedBox(
                  height: 140,
                  child: Obx(() {
                    final isLoading = controller.getFimCategory
                            .value[controller.categories[ind]['id']] ==
                        null;
                    final items = controller
                        .getFimCategory
                        .value[controller.categories[ind]['id']]
                        ?.pageProps
                        ?.data
                        ?.items;
                    return ListView.separated(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: isLoading
                          ? 8
                          : (controller
                                          .getFimCategory
                                          .value[controller.categories[ind]
                                              ['id']]
                                          ?.pageProps
                                          ?.data
                                          ?.items
                                          ?.length ??
                                      0) >
                                  10
                              ? 10
                              : (controller
                                      .getFimCategory
                                      .value[controller.categories[ind]['id']]
                                      ?.pageProps
                                      ?.data
                                      ?.items
                                      ?.length ??
                                  0),
                      itemBuilder: (context, index) {
                        final data = items?[index];
                        return CardCinema(
                          imageLink: data?.posterUrl ?? "",
                          nameProduct: data?.name,
                          // originName: items?.originName ?? "",
                          slug: data?.slug ?? "",
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(width: 20),
                    );
                  }),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: 5),
      );
    });
  }
}

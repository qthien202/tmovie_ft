import 'package:app_ft_movies/app/view/home/card_cinema/card_cinema.dart';
import 'package:app_ft_movies/app/view/list_movie/list_movie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../../controller/home/home_controller.dart';

class FilmByCategory extends StatelessWidget {
  const FilmByCategory({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    return Obx(() {
      return CustomScrollView(
        slivers: [
          // Lặp qua danh sách categories và tạo một SliverList cho mỗi category
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, ind) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // Tiêu đề danh mục
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${controller.categories[ind]['title']}", // Tiêu đề theo index
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Obx(() {
                            //   return InkWell(
                            //     onFocusChange: (hasFocus) {
                            //       if (!hasFocus) {
                            //         controller.isFocusSeeAll.fillRange(0,
                            //             controller.isFocusSeeAll.length, false);
                            //         return;
                            //       }
                            //       controller.isFocusSeeAll[ind] = true;
                            //     },
                            //     onTap: () {
                            //       Get.to(ListMovieView(
                            //         category: controller.categories[ind]
                            //                 ['slug'] ??
                            //             "",
                            //         slug: controller.pathFilm.value,
                            //         country: controller.categories[ind]
                            //                 ['country'] ??
                            //             "",
                            //       ));
                            //     },
                            //     child: Container(
                            //       margin: const EdgeInsets.symmetric(
                            //           horizontal: 10),
                            //       padding: const EdgeInsets.symmetric(
                            //           horizontal: 8, vertical: 5),
                            //       decoration: BoxDecoration(
                            //         color: controller.isFocusSeeAll[ind] == true
                            //             ? Colors.white
                            //             : Colors.transparent,
                            //         borderRadius:
                            //             controller.isFocusSeeAll[ind] == true
                            //                 ? BorderRadius.circular(16)
                            //                 : null,
                            //       ),
                            //       child: Text(
                            //         "Xem thêm",
                            //         style: TextStyle(
                            //           color:
                            //               controller.isFocusSeeAll[ind] == true
                            //                   ? Colors.black
                            //                   : Colors.white,
                            //         ),
                            //       ),
                            //     ),
                            //   );
                            // }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Danh sách phim dạng ngang
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
                            scrollDirection: Axis.horizontal,
                            itemCount: isLoading ? 8 : (items?.length ?? 0),
                            itemBuilder: (context, index) {
                              final data = items?[index];
                              return Visibility(
                                visible: !isLoading,
                                replacement: SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * .15,
                                  child: Shimmer.fromColors(
                                    baseColor: Colors.grey,
                                    highlightColor: Colors.grey.shade600,
                                    child: Container(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                child: CardCinema(
                                  imageLink: data?.posterUrl ?? "",
                                  nameProduct: data?.name,
                                  slug: data?.slug ?? "",
                                ),
                              );
                            },
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    const SizedBox(width: 20),
                          );
                        }),
                      ),
                    ],
                  ),
                );
              },
              childCount:
                  controller.categories.length, // Duyệt qua tất cả các danh mục
            ),
          ),
        ],
      );
    });
  }
}

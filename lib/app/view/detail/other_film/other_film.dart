
import 'package:app_ft_movies/app/controller/detail/detail_controller.dart';
import 'package:app_ft_movies/app/controller/movie_genre/movie_genre_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/home/card_cinema/card_cinema.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class OtherFilmView extends StatelessWidget {
  OtherFilmView({super.key, });
  

  @override
  Widget build(BuildContext context) {
    final detailController = Get.put(DetailController());
    final GlobalKey<ScaffoldState> key = GlobalKey<ScaffoldState>();
    final controller = Get.put(MovieGenreController());
    controller.getMovieGenre(slug: detailController.filmDetail.value?.pageProps?.data?.item?.category?.first.slug);

    return RefreshIndicator(
        backgroundColor: GlobalColor.backgroundColor,
        color: GlobalColor.primary,
        onRefresh: () async => controller.getMovieGenre(slug: detailController.filmDetail.value?.pageProps?.data?.item?.category?.first.slug),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Phim tương tự",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10,),
            Obx(() {
              final isLoading = controller.movieGenre.value == null;
              final data = controller.movieGenre.value?.pageProps?.data;

              return GridView.builder(
                padding: const EdgeInsets.all(5),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: isLoading ? 16 : data?.items?.length ?? 0,
                itemBuilder: (context, index) {
                  final items = data?.items?[index];
                  return Visibility(
                    visible: !isLoading,
                    replacement: SizedBox(
                        width: MediaQuery.of(context).size.width * .4,
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey,
                          highlightColor: Colors.grey.shade600,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.grey,
                            ),
                          ),
                        )),
                    child: CardCinema(
                      imageLink: items?.thumbUrl ?? "",
                      nameProduct: items?.name,
                      originName: items?.originName ?? "",
                      slug: items?.slug ?? "",
                      path: controller.movieGenre.value?.pageProps?.data?.typeList,
                    ),
                  );
                },
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                 childAspectRatio: MediaQuery.of(context).size.width < 600
                      ? 12 / 33
                      : 5 / 10,
                  crossAxisCount:
                      MediaQuery.of(context).size.width < 600 ? 3 : 6,
                  crossAxisSpacing:
                      MediaQuery.of(context).size.width < 600 ? 8 : 20,
                  mainAxisSpacing:
                      MediaQuery.of(context).size.width < 600 ? 8 : 25,
                ),
              );
            }),
             Obx(() {
                  return Visibility(
                    visible: controller.totalPage.value != 0,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                      child: SizedBox(
                        height: 40,
                        child: ListView.separated(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemCount: controller.totalPage.value ?? 0,
                          itemBuilder: (context, index) {
                            return Obx(() {
                              return InkWell(
                                onHover: (value) {
                                  controller.isFocusPage.value = value;
                                  controller.selectIndex.value = index;
                                },
                                onTap: () async {
                                  detailController.scrollController.jumpTo(100);
                                  controller.selectPage.value = index;
                                  print(
                                      ">>>>>>>>>>>>>${controller.selectIndex.value}");
                                  
                                  await controller.getMovieGenre(slug: detailController.filmDetail.value?.pageProps?.data?.item?.category?.first.slug);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 15),
                                  decoration: BoxDecoration(
                                      //  border: Border.all(color: GlobalColor.primary)
                                      color: const Color(0xff252836),
                                      border: Border.all(
                                          color: controller.selectIndex.value ==
                                                      index &&
                                                  controller.isFocusPage.value
                                              ? GlobalColor.primary
                                              : Colors.transparent)),
                                  child: Text(
                                    "${index + 1}",
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: controller.selectPage.value == index
                                            ? GlobalColor.primary
                                            : Colors.white),
                                  ),
                                ),
                              );
                            });
                          },
                          separatorBuilder: (BuildContext context, int index) {
                            return const SizedBox(
                              width: 20,
                            );
                          },
                        ),
                      ),
                    ),
                  );
                }),
            const SizedBox(
              height: 20,
            ),
          ],
        ));
  }
}

import 'package:tmovie_app/app/view/home/card_cinema/card_cinema.dart';
import 'package:tmovie_app/app/view/list_movie/list_movie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../controller/home/home_controller.dart';

class FilmByCategory extends StatelessWidget {
  const FilmByCategory({Key? key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    final int itemCount = controller.categoryList.length;

    return ListView.separated(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (context, ind) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${controller.categoryList[ind]['title']}",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Get.to(ListMovieView(
                        category: controller.categoryList[ind]['slug'] ?? "",
                        slug: controller.pathFilm.value,
                        country: controller.categoryList[ind]['country'] ?? "",
                      ));
                    },
                    child: Text(
                      "Xem thêm",
                      style: TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white),
                    ),
                  )
                ],
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * .4,
                child: Obx(() {
                  final isLoading = controller.getFimCategory
                          .value[controller.categoryList[ind]['id']] ==
                      null;
                  final items = controller
                      .getFimCategory
                      .value[controller.categoryList[ind]['id']]
                      ?.pageProps
                      ?.data
                      ?.items;
                  return ListView.separated(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: isLoading
                        ? 5
                        : controller
                                .getFimCategory
                                .value[controller.categoryList[ind]['id']]
                                ?.pageProps
                                ?.data
                                ?.items
                                ?.length ??
                            0,
                    itemBuilder: (context, index) {
                      final data = items?[index];
                      return CardCinema(
                        nameProduct: data?.name,
                        imageLink: data?.thumbUrl,
                        originName: data?.originName,
                        slug: data?.slug,
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(width: 8),
                  );
                }),
              ),
            ],
          ),
        );
      },
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 10),
    );
  }
}

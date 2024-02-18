import 'package:app_ft_movies/app/controller/home/home_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/home/card_cinema/card_cinema.dart';
import 'package:app_ft_movies/app/view/list_movie/list_movie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class FilmInHome extends StatelessWidget {
  const FilmInHome({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    final int itemCount = controller.categories.length;

    return Obx(() {
      final isLoading = controller.getFilmData.value == null;
      final data = controller.getFilmData.value?.pageProps?.data;

      return Column(
        children: [
              Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Mới nhất",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onFocusChange: (hasFocus){
                          controller.isFocusSeeAll.value = hasFocus;
                        },
                        onPressed: () {
                          Get.to(ListMovieView(
                            
                            slug:controller.pathFilm.value,
                            
                            
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
          GridView.builder(
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
                ),
              );
            },
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              childAspectRatio: 6 / 13,
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 5,
            ),
          ),
        ],
      );
    });
  }
}

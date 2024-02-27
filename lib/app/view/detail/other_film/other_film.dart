import 'package:app_ft_movies/app/controller/home/home_controller.dart';
import 'package:app_ft_movies/app/controller/list_movie/list_movie_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/home/card_cinema/card_cinema.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class OtherFilmView extends StatelessWidget {
  OtherFilmView({super.key, this.path});
  String? path;

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> key = GlobalKey<ScaffoldState>();
    final controller = Get.put(ListMovieController());
    controller.getListMovie(slug: path ?? "");

    return RefreshIndicator(
        backgroundColor: GlobalColor.backgroundColor,
        color: GlobalColor.primary,
        onRefresh: () async => controller.getListMovie(slug: path ?? ""),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Phim tương tự",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10,),
            Obx(() {
              final isLoading = controller.listMovie.value == null;
              final data = controller.listMovie.value?.pageProps?.data;

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
                      path: controller.listMovie.value?.pageProps?.data?.typeList,
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
            const SizedBox(
              height: 20,
            ),
          ],
        ));
  }
}

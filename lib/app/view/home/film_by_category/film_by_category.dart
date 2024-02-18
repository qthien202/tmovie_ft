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
    final int itemCount = controller.categories.length;
    
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
                        "${controller.categories[ind]['title']}",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onFocusChange: (hasFocus){
                          controller.isFocusSeeAll.value = hasFocus;
                        },
                        onPressed: () {
                          Get.to(ListMovieView(
                            category: controller.categories[ind]['slug']??"",
                            slug:controller.pathFilm.value,
                            country: controller.categories[ind]['country']??"",
                            
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
                    height: MediaQuery.of(context).size.height * .55,
                    child: Obx(() {
                     final isLoading = controller.getFimCategory.value[controller.categories[ind]['id']] == null;
                      final items = controller.getFimCategory.value[controller.categories[ind]['id']]?.pageProps?.data?.items;
                      return ListView.separated(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: isLoading ? 8 : (controller.getFimCategory.value[controller.categories[ind]['id']]?.pageProps?.data?.items?.length ?? 0)>10?10:(controller.getFimCategory.value[controller.categories[ind]['id']]?.pageProps?.data?.items?.length ?? 0),
                        itemBuilder: (context, index) {
                          final data = items?[index];
                          return Visibility(
                            visible: !isLoading && data?.category?.first.slug!="[redacted]",
                            replacement: Visibility(
                              visible: data?.category?.first.slug!="[redacted]",
                              child: SizedBox(
                                height: MediaQuery.of(context).size.height*.5,
              // padding: EdgeInsets.symmetric(vertical: 20),
              width: MediaQuery.of(context).size.width * .15,
                                child: Shimmer.fromColors(
                                  baseColor: Colors.grey,
                                  highlightColor: Colors.grey.shade600,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            child: CardCinema(
                              nameProduct: data?.name,
                              imageLink: data?.thumbUrl,
                              originName: data?.originName,
                              slug: data?.slug,
                            ),
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 20),
                      );
                    }),
                  ),
                ],
              ),
            );
      },
      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 10),
    );
  }
}

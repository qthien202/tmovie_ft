import 'package:app_ft_movies/app/controller/filter/filter_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/widgets/card_cinema/card_cinema.dart';
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
      final int itemCount = controller.categories.length;
    
    return SliverList.separated(
      
      // physics: NeverScrollableScrollPhysics(),
      // shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (context, ind) {
         
        return Center(
          child: Container(
             color: GlobalColor.backgroundColor,
                      width: MediaQuery.of(context).size.width<600?MediaQuery.of(context).size.width:MediaQuery.of(context).size.width * .85,
            child: Obx(() => Visibility(
              visible: controller.getFimCategory.value[controller.categories[ind]['id']]?.pageProps?.data?.items?.isNotEmpty==true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${controller.categories[ind]['title']}",
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onHover: (hasFocus){
                            controller.isFocusSeeAll.value = hasFocus;
                          },
                          onPressed: () {
                            
                            final filter = Get.put(FilterController());
                            filter.selectedGenre.value = controller.categories[ind]['slug']??"";
                            filter.selectedCountry.value = controller.categories[ind]['country']??"";
                            filter.getFilmFilter();
                          },
                          child: const Text(
                            "Xem thêm",
                            style: TextStyle(
                                color: Colors.white,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white),
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.width<600?MediaQuery.of(context).size.height * .45:MediaQuery.of(context).size.height*.55,
                    child: Obx(() {
                     final isLoading = controller.getFimCategory.value.isEmpty == true;
                      final items = controller.getFimCategory.value[controller.categories[ind]['id']]?.pageProps?.data?.items;
                      return ListView.builder(
                        shrinkWrap: false,
                        scrollDirection: Axis.horizontal,
                        
                        itemCount: isLoading ? 6 : (controller.getFimCategory.value[controller.categories[ind]['id']]?.pageProps?.data?.items?.length ?? 0)>10?10:(controller.getFimCategory.value[controller.categories[ind]['id']]?.pageProps?.data?.items?.length ?? 0),
                        itemBuilder: (context, index) {
                          final data = items?[index];
                          return Visibility(
                            visible: !isLoading && data?.category?.first.slug!="[redacted]",
                            replacement: Visibility(
                              visible: data?.category?.first.slug!="[redacted]",
                              child: Padding(
                                padding:  EdgeInsets.symmetric(horizontal: 5,vertical: 10),
                                child: SizedBox(
                                  height: MediaQuery.of(context).size.height*.5,
                                              // padding: EdgeInsets.symmetric(vertical: 20),
                                              width: MediaQuery.of(context).size.width * .15,
                                  child: Shimmer.fromColors(
                                    baseColor: Colors.grey,
                                    highlightColor: Colors.grey.shade600,
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
                              padding:  EdgeInsets.symmetric(horizontal: 5,vertical: 10),
                              child: CardCinema(
                                nameProduct: data?.name,
                                imageLink: data?.thumbUrl,
                                originName: data?.originName,
                                slug: data?.slug,
                                path: controller.getFimCategory.value[controller.categories[ind]['id']]?.pageProps?.data?.typeList??"",
                              ),
                            ),
                          );
                        },
                        
                      );
                    }),
                  ),
                ],
              ),
            ),)
          ),
        );
      },
      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 10),
    );
    });
  }
}

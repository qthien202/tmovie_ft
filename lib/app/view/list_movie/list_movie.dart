import 'package:app_ft_movies/app/controller/filter/filter_controller.dart';
import 'package:app_ft_movies/app/controller/home/home_controller.dart';
import 'package:app_ft_movies/app/controller/list_movie/list_movie_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/detail/detail_view.dart';
import 'package:app_ft_movies/app/view/filter/filter_app.dart';
import 'package:app_ft_movies/app/widgets/card_cinema/card_cinema.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class ListMovieView extends StatelessWidget {
  const ListMovieView({super.key, });
  
  
  
  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> key = GlobalKey<ScaffoldState>();
    final controller = Get.put(ListMovieController());
    controller.getListMovie();
     
   
      return SliverList.list(
      
      children: [

      Center(
        child: Container(
           color: GlobalColor.backgroundColor,
                    width: MediaQuery.of(context).size.width<600?MediaQuery.of(context).size.width:MediaQuery.of(context).size.width * .85,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text("${controller.listMovie.value?.pageProps?.data?.titlePage??"--"}",style: const TextStyle(fontSize: 20,fontWeight: FontWeight.bold),)),
                const SizedBox(height: 10,),
            Obx(() {
              final isLoading = controller.listMovie.value == null;
              final data = controller.listMovie.value?.pageProps?.data;
            
              // if (data?.items == null) {
              //   return Center(
              //     child: CircularProgressIndicator(
              //      color: GlobalColor.primary,
              //   strokeWidth: 5,
              //   backgroundColor: const Color(0xff252836),
              //     ),
              //   );
              // }
              if (data?.items?.isEmpty == true) {
                return const Center(
                  child: Text("Rất tiếc phim bạn tìm kiếm không tồn tại!"),
                );
              }
              if (data?.items?.isEmpty == true) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 100),
                      child: Center(child: Text("Rất tiếc không có phim này!")),
                    );
                  }
            
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
                      ? 13 / 33
                      : 5 / 10,
                  crossAxisCount:
                      MediaQuery.of(context).size.width < 600 ? 3 : 6,
                  crossAxisSpacing:
                      MediaQuery.of(context).size.width < 600 ? 7 : 20,
                  mainAxisSpacing:
                      MediaQuery.of(context).size.width < 600 ? 7 : 25,
                    ),
                  );
                }),
                const SizedBox(
                  height: 20,
                ),
            Obx(() {
              return Visibility(
                visible: controller.totalPage.value != 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  child: SizedBox(
                    height: 40,
                    child: ListView.separated(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: controller.totalPage.value ?? 0,
                      itemBuilder: (context, index) {
                        return Obx(() {
                          return InkWell(
                            
                            onTap: () async {
                              Get.put(HomeController()).scrollController.value?.jumpTo(0);
                              controller.selectIndex.value = index;
                              
                              
                              await Get.put(FilterController()).getFilmFilter(page: (controller.selectIndex.value??0)+1);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 15),
                              decoration: BoxDecoration(
                                  //  border: Border.all(color: GlobalColor.primary)
                                  color: const Color(0xff252836),
                                  border: Border.all(
                                      color: controller.selectIndex.value == index
                                          ? GlobalColor.primary
                                          : Colors.transparent)),
                              child: Text(
                                "${index + 1}",
                                style: TextStyle(
                                    fontSize: 13,
                                    color: controller.selectIndex.value == index
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
            })
              ],
            ),
          ),
        ),
      )
    ]);
  }
}

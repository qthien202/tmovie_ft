import 'package:app_ft_movies/app/controller/detail/detail_controller.dart';
import 'package:app_ft_movies/app/controller/home/home_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/detail/episode/episode.dart';
import 'package:app_ft_movies/app/view/detail/info/info.dart';
import 'package:app_ft_movies/app/view/detail/info_details/info_details.dart';
import 'package:app_ft_movies/app/view/detail/other_film/other_film.dart';
import 'package:app_ft_movies/app/view/header/header_view.dart';
import 'package:app_ft_movies/app/widgets/global_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';


class DetailView extends StatelessWidget {
   DetailView({
    super.key,
  });
  final controller = Get.put(DetailController());
  final homeController = Get.put(HomeController());
  

  @override
  Widget build(BuildContext context) {
    controller.getFilmDetail();
    
    
    return Visibility(
        visible: MediaQuery.of(context).size.width > 600,
        replacement: const ResponsiveApp(),
        child: DefaultTabController(
          length: homeController.tabItem.length,
          initialIndex: homeController.tabIndex.value ?? 0,
          child: Scaffold(
              appBar: const HeaderPage(),
              backgroundColor: GlobalColor.backgroundColor,
              body: Obx(() {
                final data = controller.filmDetail.value?.pageProps?.data?.item;
                if (data == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 5,
                          backgroundColor: GlobalColor.primary,
                          color: Colors.white,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text("Đang tải")
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  backgroundColor: GlobalColor.backgroundColor,
                  color: GlobalColor.primary,
                  onRefresh: () async => controller.getFilmDetail(),
                  child: CustomScrollView(
                    controller: controller.scrollController,
                    slivers: [
                      
                      SliverToBoxAdapter(
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 30),
                            color: GlobalColor.backgroundColor,
                            width: MediaQuery.of(context).size.width * .85,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: GlobalImage(
                                        imageUrl: data.posterUrl,
                                        width:
                                            MediaQuery.of(context).size.width *
                                                .4,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                .5,
                                        boxFit: BoxFit.fill,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 50,
                                    ),
                                    const Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Info(),
                                          SizedBox(
                                            height: 20,
                                          ),
                                          InfoDetail(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Nội dung phim",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20),
                                    ),
                                    const SizedBox(
                                      height: 15,
                                    ),
                                    HtmlWidget("${data.content}")
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Visibility(
                                  visible: data.status != "trailer",
                                  child: const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Chọn server",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20)),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Espisode(),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: 30,
                                ),
                                OtherFilmView()
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                );
              })),
        ),
      );
  }
}

class ResponsiveApp extends StatelessWidget {
  const ResponsiveApp({
    super.key,
    this.slug,
  });
  final String? slug;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DetailController());
    controller.getFilmDetail();
    final homeController = Get.put(HomeController());

    return DefaultTabController(
      length: homeController.tabItem.length,
      initialIndex: homeController.tabIndex.value ?? 0,
      child: Scaffold(
          appBar: const HeaderPage(),
          backgroundColor: GlobalColor.backgroundColor,
          body: Obx(() {
            final data = controller.filmDetail.value?.pageProps?.data?.item;
            if (data == null) {
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  backgroundColor: GlobalColor.primary,
                  color: Colors.white,
                ),
              );
            }
            return RefreshIndicator(
              backgroundColor: GlobalColor.backgroundColor,
              color: GlobalColor.primary,
              onRefresh: () async => controller.getFilmDetail(),
              child: CustomScrollView(
                slivers: [
                  
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 30, horizontal: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: GlobalImage(
                              imageUrl: data.thumbUrl ?? "",
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.height * .6,
                              boxFit: BoxFit.fill,
                            ),
                          ),
                          const Info(),
                          const SizedBox(
                            height: 10,
                          ),
                          const InfoDetail(),
                          const SizedBox(
                            height: 10,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Nội dung phim",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              HtmlWidget("${data.content}")
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Visibility(
                            visible: data.status != "trailer",
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Chọn server",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                SizedBox(
                                  height: 10,
                                ),
                                Espisode(),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          OtherFilmView()
                        ],
                      ),
                    ),
                  )
                ],
              ),
            );
          })),
    );
  }
}

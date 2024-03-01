import 'package:app_ft_movies/app/controller/detail/detail_controller.dart';
import 'package:app_ft_movies/app/controller/home/home_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/detail/episode/episode.dart';
import 'package:app_ft_movies/app/view/detail/info/info.dart';
import 'package:app_ft_movies/app/view/detail/info_details/info_details.dart';
import 'package:app_ft_movies/app/view/detail/other_film/other_film.dart';
import 'package:app_ft_movies/app/view/filter/filter_app.dart';
import 'package:app_ft_movies/app/view/header/header_view.dart';
import 'package:app_ft_movies/app/view/home/film_by_category/film_by_category.dart';
import 'package:app_ft_movies/app/widgets/global_image.dart';

import 'package:app_ft_movies/app/widgets/video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'dart:html' as html;

class DetailView extends StatelessWidget {
  const DetailView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DetailController());
    controller.getFilmDetail();
    return GetBuilder<HomeController>(builder: (homeController) {
      return Visibility(
        visible: MediaQuery.of(context).size.width > 600,
        replacement: const ResponsiveApp(),
        child: DefaultTabController(
          length: homeController.tabItem.length,
          initialIndex: homeController.tabIndex.value??0,
          child: Scaffold(
              extendBody: true,
              extendBodyBehindAppBar: true,
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
                      const HeaderPage(),
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
    });
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

    return WillPopScope(
      onWillPop: () async {
        controller.selectIndexServer.value = 0;
        return true;
      },
      child: Scaffold(
          extendBody: true,
          extendBodyBehindAppBar: true,
          backgroundColor: GlobalColor.backgroundColor,
          // appBar: AppBar(
          //   backgroundColor: GlobalColor.backgroundColor,
          //   centerTitle: true,
          //   title: Text(name??"--",
          //   style: const TextStyle(
          //     color: Colors.white,
          //     fontSize: 16,
          //     fontWeight: FontWeight.bold
          //   ),
          //   ),
          //   foregroundColor: Colors.white,
          // ),
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
                  SliverAppBar(
                    pinned: true,
                    leading: InkWell(
                      onTap: () => Get.back(),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Color(0xff252836)),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    actions: [
                      InkWell(
                        onTap: () {
                          Get.to(const FilterApp(),
                              transition: Transition.rightToLeft);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8.0),
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: Color(0xff252836)),
                          child: const Icon(
                            Icons.filter_alt_outlined,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                    centerTitle: true,
                    foregroundColor: Colors.white,
                    elevation: 0.0,
                    backgroundColor: GlobalColor.backgroundColor,
                    systemOverlayStyle: const SystemUiOverlayStyle(
                        statusBarBrightness: Brightness.dark),
                    expandedHeight: MediaQuery.of(context).size.height * .6,
                    flexibleSpace: FlexibleSpaceBar(
                        background: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlobalImage(
                          imageUrl: data.thumbUrl ?? "",
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height * .6,
                          boxFit: BoxFit.fill,
                        ),
                      ],
                    )),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 2, horizontal: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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

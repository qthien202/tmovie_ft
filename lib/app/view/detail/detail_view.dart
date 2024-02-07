import 'package:app_ft_movies/app/controller/detail/detail_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/detail/espisode/espisode.dart';
import 'package:app_ft_movies/app/view/detail/info/info.dart';
import 'package:app_ft_movies/app/view/detail/info_details/info_details.dart';
import 'package:app_ft_movies/app/view/drawer/drawer_view.dart';
import 'package:app_ft_movies/app/widgets/global_image.dart';
import 'package:app_ft_movies/app/widgets/video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class DetailView extends StatelessWidget {
  const DetailView({super.key, this.slug, this.name});
  final String? slug;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DetailController());
    controller.getFilmDetail(slug: slug ?? "");

    return Scaffold(
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
            onRefresh: () async => controller.getFilmDetail(slug: slug ?? ""),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  actions: [
                    InkWell(
                      onTap: () {
                        Get.to(FilterPage(),
                            transition: Transition.rightToLeft);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: const Icon(
                          Icons.menu,
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
                  expandedHeight: MediaQuery.of(context).size.height * .83,
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

                      const Info(),
                      // const SizedBox(height: 20,),
                      Visibility(
                        visible: data.status != "trailer",
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                            width: MediaQuery.of(context).size.width * .9,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: GlobalColor.primary),
                            child: InkWell(
                              onTap: () {
                                Get.to(ChewieVideoPlayer(
                                  slug: data.slug??"",
                                  fileName: data.name ?? "--",
                                  episode: data.episodes?.first.serverData
                                          ?.first.name ??
                                      "",
                                  videoUrl: data?.episodes?.first.serverData
                                          ?.first.linkM3u8 ??
                                      "",
                                ));
                              },
                              child: Center(
                                  child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    "Xem phim",
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              )),
                            ),
                          ),
                        ),
                      )
                    ],
                  )),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const InfoDetail(),
                        const SizedBox(
                          height: 10,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
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
                        Visibility(
                          visible: data.status != "trailer",
                          replacement: Text("Trạng thái : phim sắp chiếu"),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Tập phim",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(
                                height: 10,
                              ),
                              const Espisode(),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          );
        }));
  }
}

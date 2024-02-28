import 'package:app_ft_movies/app/controller/detail/detail_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/data/repository/get_film_details.dart';
import 'package:app_ft_movies/app/widgets/video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class Espisode extends StatelessWidget {
  const Espisode({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DetailController());
    return Obx(() {
      final data = controller.filmDetail.value?.pageProps?.data?.item;
      return WillPopScope(
        onWillPop: () async {
          controller.selectIndexServer.value = 0;
          return true;
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 45,
              child: ListView.separated(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: data?.episodes?.length ?? 0,
                itemBuilder: (context, index) {
                  final episode = data?.episodes?[index];
                  print(">>>>>>>>>>>>${data?.episodes?.length}");
                  return InkWell(
                      onFocusChange: (hasFocus) {
                        controller.isFocusSever.value = hasFocus;
                        controller.selectIndexServer.value = index;
                        controller.selectTabServer.value = index;
                      },
                      onTap: () => print("a"),
                      child: Obx(() {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 15),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                  color:
                                      controller.selectTabServer.value == index
                                          ? GlobalColor.primary
                                          : Color(0xff252836),
                                  width: 1.5),
                              color:GlobalColor.background2 
                              ),
                          child: Text(
                            data?.episodes?[index].serverName ?? "",
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }));
                },
                separatorBuilder: (BuildContext context, int index) {
                  return const SizedBox(
                    width: 20,
                  );
                },
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            Obx(() => GridView.builder(
                  padding: EdgeInsets.only(bottom: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    childAspectRatio: 40 / 15,
                    crossAxisCount: 6,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  shrinkWrap: true,
                  itemCount: data
                          ?.episodes?[controller.selectTabServer.value ?? 0]
                          .serverData
                          ?.length ??
                      0,
                  itemBuilder: (context, ind) {
                    final episode = data
                        ?.episodes?[controller.selectTabServer.value ?? 0]
                        .serverData?[ind];
                    return InkWell(
                        onFocusChange: (isFocus){
                          controller.selectTab.value =null;
                          controller.isFocusEp.value = isFocus;
                          controller.selectIndex.value = ind;
                        },
                            
                            
                        onTap: () async {
                          controller.selectTab.value = ind;

                          Get.to(ChewieVideoPlayer(
                            videoUrl: episode?.linkM3u8 ?? "",
                            fileName: data?.name ?? "",
                            episode: episode?.name ?? "",
                            slug: data?.slug ?? "",
                          ));
                        },
                        child: Obx(() {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 15),
                            decoration: BoxDecoration(
                              //  border: Border.all(color: GlobalColor.primary)

                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                  color: controller.selectTab.value == ind
                                      ? GlobalColor.primary
                                      : Color(0xff252836),
                                  width: 1.5),
                              color: controller.isFocusEp.value && controller.selectIndex.value == ind
                                  ? GlobalColor.primary
                                  : Color(0xff252836),
                            ),
                            child: Text(
                              episode?.name != "Full"
                                  ? "Tập ${episode?.name}"
                                  : episode?.name ?? "",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white),
                            ),
                          );
                        }));
                  },
                )),
          ],
        ),
      );
    });
  }
}

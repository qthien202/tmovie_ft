import 'package:app_ft_movies/app/controller/detail/detail_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/data/repository/get_film_details.dart';
import 'package:app_ft_movies/app/widgets/video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:html' as html;

class Espisode extends StatelessWidget {
  const Espisode({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DetailController());
    bool isMobile = MediaQuery.of(context).size.width<600;
    return Obx(() {
      final data = controller.filmDetail.value?.pageProps?.data?.item;
      return WillPopScope(
        onWillPop: ()async{
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
                  
                  return InkWell(onHover: (hasFocus) {
                    controller.isFocusEp.value = hasFocus;
                    controller.selectIndex.value = index;
                  }, onTap: () async {
                    controller.selectIndexServer.value = index;
                  }, child: Obx(() {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                         border: Border.all(color: controller.selectIndexServer.value==index?GlobalColor.primary: Color(0xff252836),width: 1.5),
                        
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
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data
                              ?.episodes?[
                                  controller.selectIndexServer.value ?? 0]
                              .serverData
                              ?.length ??
                          0,
                      itemBuilder: (context, ind) {
                        final episode = data?.episodes?[controller.selectIndexServer.value??0].serverData?[ind];
                        return InkWell(onTap: () async {
                          controller.selectTab.value = ind;
                          
                            html.window.open(
                                episode?.linkEmbed ?? "", data?.name ?? "");
                          
                        }, child: Obx(() {
                          return Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                //  border: Border.all(color: GlobalColor.primary)
                                color: Color(0xff252836),
                                border: Border.all(
                                    color: controller.selectTab.value == ind
                                        ? GlobalColor.primary
                                        : Colors.transparent,
                                    width: 2)
                                    ),
                            child: Text(
                              episode?.name != "Full"
                                  ? "Tập ${episode?.name}"
                                  : episode?.name ?? "",
                              style: TextStyle(
                                  color: controller.selectTab.value == ind
                                      ? GlobalColor.primary
                                      : Colors.white),
                            ),
                          );
                        }));
                      },
                     
                      gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
                    childAspectRatio: isMobile?13/8:13/3,
                    crossAxisCount: isMobile?4:6,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                  ),
                    ))
          ],
        ),
      );
    });
  }
}

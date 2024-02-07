import 'package:app_ft_movies/app/controller/detail/detail_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/data/repository/get_film_details.dart';
import 'package:app_ft_movies/app/widgets/video_player.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Espisode extends StatelessWidget {
  const Espisode({super.key, });
  
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DetailController());
    return Obx((){
      final data = controller.filmDetail.value?.pageProps?.data?.item;
      return SizedBox(
        height: 40,
        child: ListView.separated(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemCount: data?.episodes?.first.serverData?.length??0,
          itemBuilder: (context,index){
            final episode =  data?.episodes?.first.serverData?[index];
            return InkWell(
              onTap: (){
                controller.selectTab.value = episode?.name;
                Get.to(ChewieVideoPlayer(slug: data?.slug??"",fileName: data?.name??"",episode: episode?.name??"",videoUrl: episode?.linkM3u8??"",));
              },
              child: Obx((){
                return Container(
                padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 15),
                decoration:  BoxDecoration( 
                  //  border: Border.all(color: GlobalColor.primary)
                  color: Color(0xff252836),
                  border: Border.all(color: controller.selectTab.value == episode?.name?GlobalColor.primary:Colors.transparent)
                ),
                child: Text("${episode?.name}"),
              );
              })
            );
          }, separatorBuilder: (BuildContext context, int index) {  
            return const SizedBox(width: 20,);
          },
           
            
          ),
      );
    });
  }
}
import 'package:app_ft_movies/app/controller/detail/detail_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/data/repository/get_film_details.dart';
import 'package:app_ft_movies/app/widgets/video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:html' as html;
class Espisode extends StatelessWidget {
  const Espisode({super.key, });
  
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DetailController());
    return Obx((){
      final data = controller.filmDetail.value?.pageProps?.data?.item;
      return SizedBox(
        height: 45,
        child: ListView.separated(
          
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemCount: data?.episodes?.first.serverData?.length??0,
          itemBuilder: (context,index){
            final episode =  data?.episodes?.first.serverData?[index];
            return InkWell(
              onHover: (hasFocus){
                controller.isFocusEp.value = hasFocus;
                controller.selectIndex.value = index;
              },
              onTap: ()async{
                controller.selectTab.value = index;
                await controller.createToken(
                                  name: data?.name??"",
                                  description: data?.content??"",
                                  originName: data?.originName??"",
                                  slug: data?.slug??"",
                                  thumbnail: data?.thumbUrl??"",
                                  episode: episode?.name??""
                                  
                                );
                html.window.open(episode?.linkEmbed??"", data?.name??"");
              },
              child: Obx((){
                return Container(
                padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 15),
                decoration:  BoxDecoration( 
                  //  border: Border.all(color: GlobalColor.primary)
                  color: Color(0xff252836),
                  border: Border.all(color:controller.isFocusEp.value && controller.selectIndex.value==index?GlobalColor.primary:Colors.transparent,width: 2)
                ),
                child: Text(episode?.name!="Full"?"Tập ${episode?.name}":episode?.name??"",style: TextStyle(color: controller.selectTab.value==index?GlobalColor.primary:Colors.white),),
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
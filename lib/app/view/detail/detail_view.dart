import 'package:app_ft_movies/app/controller/detail/detail_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/detail/espisode/espisode.dart';
import 'package:app_ft_movies/app/view/detail/info/info.dart';
import 'package:app_ft_movies/app/view/detail/info_details/info_details.dart';
import 'package:app_ft_movies/app/widgets/global_image.dart';
import 'package:app_ft_movies/app/widgets/video_player.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class DetailView extends StatelessWidget {
  const DetailView({super.key, this.slug, this.name});
  final String? slug;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DetailController());
    controller.getFilmDetail(slug: slug??"");
    
      return RefreshIndicator(
        backgroundColor: GlobalColor.backgroundColor,
        onRefresh: ()async=>controller.getFilmDetail(slug: slug??""),
        child: Scaffold(
        backgroundColor: GlobalColor.backgroundColor,
        appBar: AppBar(
          backgroundColor: GlobalColor.backgroundColor,
          centerTitle: true,
          title: Text(name??"--",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold
          ),
          ),
          foregroundColor: Colors.white,
        ),
        body: Obx((){
          final data = controller.filmDetail.value?.pageProps?.data?.item;
          if(data==null){
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 5,
                      backgroundColor: GlobalColor.primary,
                    ),
                  );
                }
          return ListView(
          children: [
            GlobalImage(
              imageUrl:data?.thumbUrl??"",
              width: MediaQuery.of(context).size.width*.4,
              height: 300,
              // fit: BoxFit.fill,
            ),
            const SizedBox(height: 15,),
            const Info(),
            const SizedBox(height: 15,),
            Container(
              padding: EdgeInsets.symmetric(vertical: 10),
              margin: EdgeInsets.symmetric(vertical: 10,horizontal: 30),
              
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: GlobalColor.primary
              ),
              child: InkWell(
                onTap: (){
                  Get.to(ChewieVideoPlayer(fileName: data.name??"--",episode: data.episodes?.first.serverData?.first.name??"",videoUrl: data?.episodes?.first.serverData?.first.linkM3u8??"",));
                },
                child: Center(child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow,color: Colors.white,),
                    const SizedBox(width: 10,),
                    Text("Xem phim",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                  ],
                )),
              ),
            ),
            const InfoDetail(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: const Text("Tập phim",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal:8.0),
              child: const Espisode(),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Nội dung phim",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16),),
                  const SizedBox(height: 10,),
                  HtmlWidget("${data?.content}")
                ],
              ),
            )
          ],
        );
        })
            ),
      );
  }
}
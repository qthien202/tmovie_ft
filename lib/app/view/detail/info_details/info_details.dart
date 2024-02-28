import 'package:app_ft_movies/app/controller/detail/detail_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/widgets/video_player.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InfoDetail extends StatelessWidget {
  const InfoDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DetailController());
    return Obx(() {
      final data = controller.filmDetail.value?.pageProps?.data?.item;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Thông tin phim",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text("Số tập :"),
              const SizedBox(
                width: 10,
              ),
              Text(data?.episodeTotal ?? "--")
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text("Ngôn ngữ :"),
              const SizedBox(
                width: 10,
              ),
              Text(data?.lang ?? "--"),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text("Quốc gia :"),
              const SizedBox(
                width: 10,
              ),
              Text(data?.country?.first.name ?? "--"),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text("Đạo diễn :"),
              const SizedBox(
                width: 10,
              ),
              Row(
                children: (data?.director ?? []).map((director) {
                  return Text(director==""?"chưa biết":"$director, ");
                }).toList(),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.start,
          //   children: [
          //     Text("Diễn viên:"),
          //     const SizedBox(
          //       width: 10,
          //     ),
          //     Row(
          //       children: (data?.actor?? []).map((actor) {
          //         return Text(actor==""?"chưa biết":"$actor, ");
          //       }).toList(),
          //     ),
          //   ],
          // ),
          
          
          InkWell(
            onFocusChange: (isFocus){
              controller.isFocus.value = isFocus;
            },
            onTap: (){
              Get.to(ChewieVideoPlayer(videoUrl: data?.episodes?[controller.selectIndexServer.value??0].serverData?.first.linkM3u8??"", fileName: data?.name??"", episode: data?.episodes?[controller.selectIndexServer.value??0].serverData?.first.name??"", slug: data?.slug??""));
            },
            child:Obx(() => AnimatedContainer(
              duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: controller.isFocus.value ? Matrix4.diagonal3Values(1.05, 1.05, 1) : Matrix4.identity(),
              child: Container(
                width: MediaQuery.of(context).size.width*.2,
                padding: EdgeInsets.symmetric(horizontal: 20,vertical: 10),
                decoration: BoxDecoration(
                  color: controller.isFocus.value?Colors.black:Colors.transparent,
                  border: Border.all(color: controller.isFocus.value?Colors.transparent:Colors.white,),
                  borderRadius: BorderRadius.circular(5)
                ),
                child: Text("XEM NGAY",
                textAlign: TextAlign.center,
                )),
            ),) 
          )
        ],
      );
    });
  }
}
import 'package:app_ft_movies/app/controller/detail/detail_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
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
          Text("Số tập : ${data?.episodeTotal}"),
          
          const SizedBox(
            height: 10,
          ),
          Text("Ngôn ngữ : ${data?.lang}"),
         
          const SizedBox(
            height: 10,
          ),
          Text("Quốc gia : ${data?.country?.first.name}"),
          const SizedBox(
            height: 10,
          ),
         
          Row(
            children: (data?.director ?? []).map((director) {
              return Text(director==""?"Đạo diễn: không có thông tin":"Đạo diễn: $director, ");
            }).toList(),
          ),
          const SizedBox(
            height: 10,
          ),
          
          
          Row(
            children: (data?.actor ?? []).map((actor) {
              return Text(actor==""?"không có thông tin":"$actor, ");
            }).toList(),
          ),
          
          const SizedBox(
            height: 10,
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20,vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black,
              // borderRadius: BorderRadius.circular(5)
            ),
            child: Text(data?.episodeCurrent??""))
        ],
      );
    });
  }
}

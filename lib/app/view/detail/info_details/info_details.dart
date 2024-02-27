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

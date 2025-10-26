import 'package:tmovie_app/app/controller/detail/detail_controller.dart';
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
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text("Số tập :", style: TextStyle(color: Colors.white)),
              const SizedBox(
                width: 10,
              ),
              Text(data?.episodeTotal ?? "--",
                  style: TextStyle(color: Colors.white))
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text("Ngôn ngữ :", style: TextStyle(color: Colors.white)),
              const SizedBox(
                width: 10,
              ),
              Text(data?.lang ?? "--", style: TextStyle(color: Colors.white)),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text("Quốc gia :", style: TextStyle(color: Colors.white)),
              const SizedBox(
                width: 10,
              ),
              Text(data?.country?.first.name ?? "--",
                  style: TextStyle(color: Colors.white)),
            ],
          )
        ],
      );
    });
  }
}

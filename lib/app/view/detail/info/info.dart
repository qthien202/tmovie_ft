import 'package:tmovie_app/app/controller/detail/detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Info extends StatelessWidget {
  const Info({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DetailController());

    return Obx(() {
      final data = controller.filmDetail.value?.pageProps?.data?.item;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${data?.name}  •  ${data?.quality}",
              maxLines: 2,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            Text(
              "${data?.year} • ${data?.category?.first.name} / ${data?.category?.last.name}",
              style: TextStyle(color: Colors.white),
            ),
            Text("${data?.time}", style: TextStyle(color: Colors.white))
          ],
        ),
      );
    });
  }
}

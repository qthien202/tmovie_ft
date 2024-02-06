import 'package:app_ft_movies/app/controller/detail/detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Info extends StatelessWidget {
  const Info({super.key});
  

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DetailController());
    
    return Obx((){
      final data = controller.filmDetail.value?.pageProps?.data?.item;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 15),
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${data?.name}  •  ${data?.quality}",
                maxLines: 2,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold
                ),),
                Text("${data?.year} • ${data?.category?.first.name} / ${data?.category?.last.name}"),
                Text("${data?.time}")

                
              ],
            ),
      );
    });
  }
}
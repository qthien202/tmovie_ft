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
      return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.calendar_today,color: Colors.white,size: 15,),
                  const SizedBox(width: 5,),
                  Text(data?.year.toString()??"--",style: const TextStyle(color: Colors.white,fontSize: 11),),
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 10),
                     child: Container(
                      height: 10,
                      width: 1,
                      color: Colors.white,
                                       ),
                   ),
                  const Icon(Icons.access_time,color: Colors.white,size: 15,),
                  const SizedBox(width: 5,),
                  Text(data?.time.toString()??"--",style: const TextStyle(color: Colors.white,fontSize: 11)),
                  Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 10),
                     child: Container(
                      height: 10,
                      width: 1,
                      color: Colors.white,
                                       ),
                   ),
                  const Icon(Icons.theaters,color: Colors.white,size: 15,),
                  const SizedBox(width: 5,),
                  Text(data?.category?.first.name??"--",style: const TextStyle(color: Colors.white,fontSize: 11),)

                ],
              )
            ],
          );
    });
  }
}
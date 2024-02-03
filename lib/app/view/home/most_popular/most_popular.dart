import 'package:app_ft_movies/app/controller/home/home_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/home/card_cinema/card_cinema.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MostPopular extends StatelessWidget {
  const MostPopular({super.key, });
  

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    return Obx((){
      return Padding(
      padding: const EdgeInsets.symmetric(horizontal:5),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Mới cập nhật",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
              // TextButton(onPressed: (){}, child: Text("Xem thêm",style: TextStyle(color: GlobalColor.primary),)
              // )
            ],
          ),
          const SizedBox(height: 10,),
          SizedBox(
            height: MediaQuery.of(context).size.height*.4,
            child: ListView.separated(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: controller.getNewFilmData.value?.items.length??0,
              itemBuilder: (context,index){
                final data = controller.getNewFilmData.value?.items[index];
                return CardCinema(
                  nameProduct: data?.name,
                  imageLink:data?.posterUrl,
                  originName: data?.originName,
                  slug: data?.slug,
                );
              }, separatorBuilder: (BuildContext context, int index)=>const SizedBox(width: 8,),
            ),
          ),
        ],
      ),
    );
    });
  }
}
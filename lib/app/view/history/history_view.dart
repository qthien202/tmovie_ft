import 'package:app_ft_movies/app/controller/history/history_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/detail/detail_view.dart';
import 'package:app_ft_movies/app/widgets/global_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/get.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HistoryController());
    controller.onReady();
    return Scaffold(
      // appBar: AppBar(
      //   title: Text("Lịch sử"),
      //   backgroundColor: GlobalColor.backgroundColor,
      //   foregroundColor: Colors.white,
      // ),
      backgroundColor: GlobalColor.backgroundColor,
      body: Obx((){
        if(controller.getHistoryData.value?.data.isEmpty==true){
          return Center(
            child: Text("Hiện vẫn chưa có lịch sử xem nhé",style: TextStyle(
              fontSize: 14,fontWeight: FontWeight.bold
            ),),
          );
        };
        return RefreshIndicator(
        onRefresh: ()async=>controller.onReady(),
        backgroundColor: GlobalColor.backgroundColor,
        color: GlobalColor.primary,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30,horizontal: 10),
          child: ListView(
            controller: controller.scrollController,
            children: [
              ListView.separated(
                physics: NeverScrollableScrollPhysics(),
              
              shrinkWrap: true,
              itemCount: controller.getHistoryData.value?.data.length??0,
              itemBuilder: (context, index) {
                final data = controller.getHistoryData.value?.data[index];
                return Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: GlobalColor.background2,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: GlobalImage(
                        imageUrl: data?.thumbnailUrl??"",
                        width: MediaQuery.of(context).size.width*.4,
                          height: MediaQuery.of(context).size.height * .3,
                          boxFit: BoxFit.fill,
                                    ),
                      ),
                      const SizedBox(width: 15,),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${data?.name} • ${data?.episode}",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                            const SizedBox(height: 10,),
                            Text(data?.originName??"",style: TextStyle(fontSize: 14,fontWeight: FontWeight.bold),),
                            const SizedBox(height: 10,),
                             Text("${data?.description}",maxLines: 5,style: TextStyle(overflow: TextOverflow.ellipsis)),
                            const SizedBox(height: 10,),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: GlobalColor.primary),
                              child: InkWell(
                                onTap: () async{
                                 Get.to(DetailView(slug: data?.slug??"",));
                                },
                                child: const Center(
                                    child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      "Xem phim",
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                )),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              }, separatorBuilder: (BuildContext context, int index) { 
                return const SizedBox(height: 15,);
               },
              ),
               const SizedBox(height: 30,),
                  Visibility(
                    visible: controller.limit.value <
                        (controller.getHistoryData.value?.total ??
                            0),
                    replacement: const Center(),
                    child: Center(
                      child: CircularProgressIndicator(
                      color: GlobalColor.primary,
                      )
                    ),
                  ),
            ],
          ),
        ),
      );
      })
    );
  }
}
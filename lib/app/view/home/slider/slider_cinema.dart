import 'package:app_ft_movies/app/controller/home/home_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/core/global_data.dart';
import 'package:app_ft_movies/app/view/detail/detail_view.dart';
import 'package:app_ft_movies/app/widgets/global_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class SliderCinema extends StatelessWidget {
  const SliderCinema({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    return Obx(() {
      final isLoading = controller.getNewFilmData.value==null;
      return Stack(
        alignment: Alignment.topCenter,
        children: [
          CarouselSlider.builder(
            itemCount: isLoading?4:controller.getNewFilmData.value?.items.length ?? 0,
            itemBuilder: (context, index, realIndex) {
              return Visibility(
                visible: !isLoading,
                replacement: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * .5,
                  child: Shimmer.fromColors(
                              baseColor: Colors.grey,
                              highlightColor: Colors.grey.shade600,
                              child: Container(
                                decoration: const BoxDecoration(
                                  
                                  color: Colors.grey,
                                ),
                              ),
                  )
                ),
                child: InkWell(
                  onTap: ()=>Get.to(DetailView(slug: controller.getNewFilmData.value?.items[index].slug,name: controller.getNewFilmData.value?.items[index].name,)),
                  child: GlobalImage(
                    imageUrl:
                        "${controller.getNewFilmData.value?.items[index].thumbUrl}",
                    boxFit: BoxFit.fill,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                  ),
                ),
              );
            },
            options: CarouselOptions(
                aspectRatio: 18 / 24,
                // enlargeCenterPage: true,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 7),
                viewportFraction: 1,
                onPageChanged: (index, reason) {
                  controller.activeIndex.value = index;
                }),
          ),
          const SizedBox(height: 10,),
          Positioned(
            top: MediaQuery.of(context).size.height*.55,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Colors.black,
                    shape: RoundedRectangleBorder(
                      // side: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(25)
                    )
                  ),
                  onPressed: ()async{
                    await controller.watchNow(slug: controller.getNewFilmData.value?.items[controller.activeIndex.value??0].slug??"");
                  },
                   child: const Row(
                     children: [
                      Icon(Icons.play_arrow_rounded,color: Colors.white,size: 20,),
                       Text("Xem ngay",style: TextStyle(color: Colors.white,fontSize: 12),),
                     ],
                   )
                ),
                const SizedBox(width: 15,),
                ElevatedButton(
                   style: ElevatedButton.styleFrom(
                    primary: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(25)
                    )
                  ),
                  onPressed: ()=>Get.to(DetailView(slug: controller.getNewFilmData.value?.items[controller.activeIndex.value??0].slug,name: controller.getNewFilmData.value?.items[controller.activeIndex.value??0].name)),
                   child: const Row(
                     children: [
                      Icon(Icons.info,color: Colors.white,size: 20,),
                      SizedBox(width: 5,),
                       Text("Chi tiết",style: TextStyle(color: Colors.white,fontSize: 12)),
                     ],
                   )
                )
              ],
            ),
          )
          // Center(
          //     // bottom: 2,
          //     child: AnimatedSmoothIndicator(
          //   count: controller.getNewFilmData.value?.items.length ?? 0,
          //   activeIndex: controller.activeIndex.value ?? 0,
          //   effect: ScrollingDotsEffect(
          //     dotWidth: 5,
          //     dotHeight: 5,
          //     dotColor: Colors.grey,
          //     activeDotColor: GlobalColor.primary,
          //   ),
          // )),
        ],
      );
    });
  }
}

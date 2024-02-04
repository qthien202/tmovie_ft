import 'package:app_ft_movies/app/controller/home/home_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/core/global_data.dart';
import 'package:app_ft_movies/app/view/detail/detail_view.dart';
import 'package:app_ft_movies/app/widgets/global_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class SliderCinema extends StatelessWidget {
  const SliderCinema({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            CarouselSlider.builder(
              itemCount: controller.getNewFilmData.value?.items.length ?? 0,
              itemBuilder: (context, index, realIndex) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ClipRRect(
                      // borderRadius: BorderRadius.circular(5),
                      child: InkWell(
                        onTap: ()=>Get.to(DetailView(slug: controller.getNewFilmData.value?.items[index].slug,name: controller.getNewFilmData.value?.items[index].name,)),
                        child: GlobalImage(
                          imageUrl:
                              "${controller.getNewFilmData.value?.items[index].thumbUrl}",
                          boxFit: BoxFit.fill,
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height * .5,
                        ),
                      )),
                );
              },
              options: CarouselOptions(
                  aspectRatio: 24 / 24,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 7),
                  // viewportFraction: 1,
                  onPageChanged: (index, reason) {
                    controller.activeIndex.value = index;
                  }),
            ),
            const SizedBox(height: 10,),
            Center(
                // bottom: 2,
                child: AnimatedSmoothIndicator(
              count: controller.getNewFilmData.value?.items.length ?? 0,
              activeIndex: controller.activeIndex.value ?? 0,
              effect: ScrollingDotsEffect(
                dotWidth: 5,
                dotHeight: 5,
                dotColor: Colors.grey,
                activeDotColor: GlobalColor.primary,
              ),
            )),
          ],
        ),
      );
    });
  }
}

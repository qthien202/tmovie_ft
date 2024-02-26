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
      final isLoading = controller.getFilmData.value == null;
      return Column(
        children: [
          CarouselSlider.builder(
            itemCount: isLoading
                ? 4
                : ((controller.getFilmData.value?.pageProps?.data?.items
                                ?.length ??
                            0) /
                        2)
                    .round(),
            itemBuilder: (context, index, realIndex) {
              final int first = index * 2;
              final int second = first + 1;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [first, second].map((idx) {
                  final data = controller
                      .getFilmData.value?.pageProps?.data?.items?[idx];
                  return Visibility(
                    visible: !isLoading,
                    replacement: Padding(
                     padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 10),
                      child: SizedBox(
                         width: MediaQuery.of(context).size.width * .4,
                                height: MediaQuery.of(context).size.height * .4,
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey,
                            highlightColor: Colors.grey.shade600,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.grey,
                              ),
                            ),
                          )),
                    ),
                    child: InkWell(
                      onTap: () => Get.to(DetailView(
                        slug: data?.slug,
                        name: data?.name,
                        path: controller
                      .getFilmData.value?.pageProps?.data?.typeList??"",
                      )),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 10),
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            GlobalImage(
                              imageUrl: "${data?.posterUrl}",
                              boxFit: BoxFit.fill,
                              width: MediaQuery.of(context).size.width * .4,
                              height: MediaQuery.of(context).size.height * .4,
                            ),
                            Positioned(
                                top: MediaQuery.of(context).size.height * .32,
                                left: 20,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data?.name??"--",style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),
                                    Text(data?.year.toString()??"--")
                                  ],
                                ))
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            options: CarouselOptions(
                autoPlay: true,
                aspectRatio: 4.0,
                enlargeCenterPage: false,
                viewportFraction: 1,
                onPageChanged: (index, reason) {
                  controller.activeIndex.value = index;
                }),
          ),
          // const SizedBox(height: 10,),

          Center(
              // bottom: 2,
              child: AnimatedSmoothIndicator(
            count:
                controller.getFilmData.value?.pageProps?.data?.items?.length ??
                    0,
            activeIndex: controller.activeIndex.value ?? 0,
            effect: ScrollingDotsEffect(
              dotWidth: 7,
              dotHeight: 7,
              dotColor: Colors.grey,
              activeDotColor: GlobalColor.primary,
            ),
          )),
        ],
      );
    });
  }
}

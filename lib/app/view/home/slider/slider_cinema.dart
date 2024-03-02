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
    if(MediaQuery.of(context).size.width<600){
      return const ResponsiveApp();
    }
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [first, second].map((idx) {
                  final data = controller
                      .getFilmData.value?.pageProps?.data?.items?[idx];
                  return Visibility(
                    visible: !isLoading,
                    replacement: Padding(
                     padding: const EdgeInsets.symmetric(
                             vertical: 10),
                      child: SizedBox(
                         width: MediaQuery.of(context).size.width * .42,
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
                      onTap: () => Get.toNamed('/chi-tiet/${data?.slug}'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                             vertical: 10),
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: GlobalImage(
                                imageUrl: "${data?.posterUrl}",
                                boxFit: BoxFit.fill,
                                width: MediaQuery.of(context).size.width * .42,
                                height: MediaQuery.of(context).size.height * .4,
                              ),
                            ),
                            Positioned(
                                top: MediaQuery.of(context).size.height * .32,
                                left: 20,
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                                0.2),
                                            // Màu của box shadow và độ mờ
                                            spreadRadius:
                                            5,
                                            // Điều chỉnh bán kính mở rộng của box shadow
                                            blurRadius:
                                            10,
                                            // Điều chỉnh độ mờ của box shadow
                                            offset: Offset(0,
                                                3), // Điều chỉnh độ dịch chuyển của box shadow
                                          ),
                                ]
                              ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(data?.name??"--",style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),
                                      Text(data?.year.toString()??"--")
                                    ],
                                  ),
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

class ResponsiveApp extends StatelessWidget {
  const ResponsiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    return Obx(() {
      final isLoading = controller.getFilmData.value==null;
      return Column(
        children: [
          CarouselSlider.builder(
            itemCount: isLoading?4:controller.getFilmData.value?.pageProps?.data?.items?.length ?? 0,
            itemBuilder: (context, index, realIndex) {
              final data = controller
                    .getFilmData.value?.pageProps?.data?.items?[index];
              return Visibility(
                visible: !isLoading,
                replacement: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * .3,
                    child: Shimmer.fromColors(
                                baseColor: Colors.grey,
                                highlightColor: Colors.grey.shade600,
                                child: Container(
                                  decoration: BoxDecoration(
                                    
                                    color: Colors.grey,
                                  ),
                                ),
                    )
                  ),
                ),
                child: InkWell(
                  onTap: () =>Get.toNamed('/chi-tiet/${data?.slug}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                         vertical: 10),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: GlobalImage(
                            imageUrl: "${data?.posterUrl}",
                            boxFit: BoxFit.fill,
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height * .35,
                          ),
                        ),
                        Positioned(
                            top: 120,
                            left: 15,
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                                0.2),
                                            // Màu của box shadow và độ mờ
                                            spreadRadius:
                                            5,
                                            // Điều chỉnh bán kính mở rộng của box shadow
                                            blurRadius:
                                            10,
                                            // Điều chỉnh độ mờ của box shadow
                                            offset: Offset(0,
                                                3), // Điều chỉnh độ dịch chuyển của box shadow
                                          ),
                                ]
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data?.name??"--",style: TextStyle(fontSize: 14,fontWeight: FontWeight.bold),),
                                  Text(data?.year.toString()??"--")
                                ],
                              ),
                            ))
                      ],
                    ),
                  ),
                ),
              );
            },
            options: CarouselOptions(
                aspectRatio: 2.0,
                enlargeCenterPage: true,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 7),
                // viewportFraction: 1,
                onPageChanged: (index, reason) {
                  controller.activeIndex.value = index;
                }),
          ),
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

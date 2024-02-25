import 'package:app_ft_movies/app/controller/home/home_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/core/global_data.dart';
import 'package:app_ft_movies/app/view/detail/detail_view.dart';
import 'package:app_ft_movies/app/widgets/global_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class SliderCinema extends StatelessWidget {
  const SliderCinema({Key? key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Obx(() {
      final isLoading = controller.getFilmData.value == null;
      return Stack(
        alignment: Alignment.topCenter,
        children: [
          CarouselSlider.builder(
            itemCount: isLoading
                ? 4
                : controller.getFilmData.value?.pageProps?.data?.items?.length ??
                    0,
            itemBuilder: (context, index, realIndex) {
              return Visibility(
                visible: !isLoading,
                replacement: SizedBox(
                  width: screenWidth,
                  height: screenHeight * 0.6, // Thiết lập chiều cao tối thiểu cho banner
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey,
                    highlightColor: Colors.grey.shade600,
                    child: Container(
                      color: Colors.grey,
                    ),
                  ),
                ),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  width: screenWidth,
                    height: screenHeight * 0.6,
                    decoration: BoxDecoration(
                      border: Border.all(color: controller.isFocusSlider.value && controller.selectTab.value == index?GlobalColor.primary:Colors.transparent,width: 3)
                    ),
                  child: GlobalImage(
                    imageUrl: "${controller.getFilmData.value?.pageProps?.data?.items?[index].posterUrl}",
                    boxFit: BoxFit.fill, // Hiển thị ảnh đúng tỷ lệ
                    width: screenWidth,
                    height: screenHeight * 0.7, // Thiết lập chiều cao tối thiểu cho banner
                  ),
                ),
              );
            },
            options: CarouselOptions(
              aspectRatio: screenWidth / (screenHeight * 0.6), // Tỷ lệ ứng với tỷ lệ màn hình TV
              autoPlay: true,
              enlargeCenterPage: true,
              autoPlayInterval: const Duration(seconds: 5),
              // viewportFraction: 1,
              onPageChanged: (index, reason) {
                controller.activeIndex.value = index;
              },
            ),
          ),
          SizedBox(height: 10),
          // Positioned(
          //   top: screenHeight * 0.5,
          //   child: Column(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
                
          //     ],
          //   ),
          // ),
        ],
      );
    });
  }
}

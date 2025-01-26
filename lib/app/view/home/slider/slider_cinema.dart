import 'package:app_ft_movies/app/controller/home/home_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/core/global_data.dart';
import 'package:app_ft_movies/app/view/detail/detail_view.dart';
import 'package:app_ft_movies/app/view/home/film_in_home/film_in_home.dart';
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
        clipBehavior: Clip.none,
        // alignment: Alignment.bottomCenter,
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
                  height: screenHeight, // Thiết lập chiều cao tối thiểu cho banner
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey,
                    highlightColor: Colors.grey.shade600,
                    child: Container(
                      color: Colors.grey,
                    ),
                  ),
                ),
                child: Container(
                  width: screenWidth,
                    height: screenHeight,
                    decoration: BoxDecoration(
                      border: Border.all(color: controller.isFocusSlider.value && controller.selectTab.value == index?GlobalColor.primary:Colors.transparent,width: 3)
                    ),
                  child: GlobalImage(
                    imageUrl: "${controller.getFilmData.value?.pageProps?.data?.items?[index].posterUrl}",
                    boxFit: BoxFit.cover, // Hiển thị ảnh đúng tỷ lệ
                    width: screenWidth,
                    height: screenHeight, // Thiết lập chiều cao tối thiểu cho banner
                  ),
                ),
              );
            },
            options: CarouselOptions(
              aspectRatio: 22/10, // Tỷ lệ ứng với tỷ lệ màn hình TV
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 10),
              viewportFraction: 1,
              onPageChanged: (index, reason) {
                controller.activeIndex.value = index;
              },
            ),
          ),
          // Positioned.fill(
          //     top: 350,
          //     child: FilmInHome())

          // Column(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     Text(controller.getFilmData.value?.pageProps?.data?.items?[controller.activeIndex.value??0].name,style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),)
          //   ],
          // ),
        ],
      );
    });
  }
}

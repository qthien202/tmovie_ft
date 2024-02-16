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
                child: InkWell(
                  onTap: () => Get.to(
                    DetailView(
                      slug: controller.getFilmData.value?.pageProps?.data?.items?[index].slug ?? "",
                      name: controller.getFilmData.value?.pageProps?.data?.items?[index].name ?? "",
                    ),
                  ),
                  child: GlobalImage(
                    imageUrl: "${controller.getFilmData.value?.pageProps?.data?.items?[index].posterUrl}",
                    boxFit: BoxFit.fill, // Hiển thị ảnh đúng tỷ lệ
                    width: screenWidth,
                    height: screenHeight * 0.6, // Thiết lập chiều cao tối thiểu cho banner
                  ),
                ),
              );
            },
            options: CarouselOptions(
              aspectRatio: screenWidth / (screenHeight * 0.6), // Tỷ lệ ứng với tỷ lệ màn hình TV
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              viewportFraction: 1,
              onPageChanged: (index, reason) {
                controller.activeIndex.value = index;
              },
            ),
          ),
          SizedBox(height: 10),
          // Positioned(
          //   top: screenHeight * 0.5,
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       Visibility(
          //         visible:
          //             controller.getFilmData.value?.pageProps?.data?.items?[controller.activeIndex.value ?? 0].episodeCurrent != "Trailer",
          //         child: ElevatedButton(
          //           style: ElevatedButton.styleFrom(
          //             primary: GlobalColor.primary,
          //             shape: RoundedRectangleBorder(
          //               borderRadius: BorderRadius.circular(25),
          //               side: BorderSide(color: controller.isFocusWatch.value?Colors.white:Colors.transparent,width: 3)
          //             ),
          //           ),
          //           onFocusChange: (hasFocus){
          //             controller.isFocusWatch.value = hasFocus;
          //           },
          //           onPressed: () async {
          //             await controller.watchNow(
          //               slug: controller.getFilmData.value?.pageProps?.data?.items?[controller.activeIndex.value ?? 0].slug ?? "",
          //             );
          //           },
          //           child: Row(
          //             children: const [
          //               Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
          //               Text("Xem ngay", style: TextStyle(color: Colors.white, fontSize: 12)),
          //             ],
          //           ),
          //         ),
          //       ),
          //       SizedBox(width: 15),
          //       ElevatedButton(
          //         style: ElevatedButton.styleFrom(
          //           primary: Colors.transparent,
          //           shape: RoundedRectangleBorder(
          //             side: const BorderSide(color: Colors.white),
          //             borderRadius: BorderRadius.circular(25),
          //           ),
          //         ),
          //         onPressed: () => Get.to(
          //           DetailView(
          //             slug: controller.getFilmData.value?.pageProps?.data?.items?[controller.activeIndex.value ?? 0].slug ?? "",
          //             name: controller.getNewFilmData.value?.items[controller.activeIndex.value ?? 0].name ?? "",
          //           ),
          //         ),
          //         child: Row(
          //           children: const [
          //             Icon(Icons.info, color: Colors.white, size: 20),
          //             SizedBox(width: 5),
          //             Text("Chi tiết", style: TextStyle(color: Colors.white, fontSize: 12)),
          //           ],
          //         ),
          //       )
          //     ],
          //   ),
          // ),
        ],
      );
    });
  }
}

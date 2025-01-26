import 'package:app_ft_movies/app/controller/home/home_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/core/global_data.dart';
import 'package:app_ft_movies/app/view/detail/detail_view.dart';
import 'package:app_ft_movies/app/view/home/film_in_home/film_in_home.dart';
import 'package:app_ft_movies/app/widgets/global_image.dart';
import 'package:app_ft_movies/app/widgets/video_player.dart';
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
      final items = controller.getFilmData.value?.pageProps?.data?.items;
      return Stack(
        clipBehavior: Clip.none,
        // alignment: Alignment.bottomCenter,
        children: [
          CarouselSlider.builder(
            itemCount: isLoading ? 4 : items?.length ?? 0,
            itemBuilder: (context, index, realIndex) {
              final item = items?[index];
              return Visibility(
                visible: !isLoading,
                replacement: SizedBox(
                  width: screenWidth,
                  height:
                      screenHeight, // Thiết lập chiều cao tối thiểu cho banner
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
                      border: Border.all(
                          color: controller.isFocusSlider.value &&
                                  controller.selectTab.value == index
                              ? GlobalColor.primary
                              : Colors.transparent,
                          width: 3)),
                  child: GlobalImage(
                    imageUrl: "${item?.posterUrl}",
                    boxFit: BoxFit.cover, // Hiển thị ảnh đúng tỷ lệ
                    width: screenWidth,
                    height:
                        screenHeight, // Thiết lập chiều cao tối thiểu cho banner
                  ),
                ),
              );
            },
            options: CarouselOptions(
              aspectRatio: 22 / 10, // Tỷ lệ ứng với tỷ lệ màn hình TV
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 10),
              viewportFraction: 1,
              onPageChanged: (index, reason) {
                controller.activeIndex.value = index;
              },
            ),
          ),
          Positioned.fill(
              top: 150,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Visibility(
                  visible: items != null,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${items?[controller.activeIndex.value ?? 0].name}  •  ${items?[controller.activeIndex.value ?? 0].quality}",
                              maxLines: 2,
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    offset: Offset(
                                        2.0, 2.0), // Độ lệch của bóng (x, y)
                                    blurRadius: 4.0, // Độ mờ của bóng
                                    color: Colors.black54, // Màu sắc của bóng
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "${items?[controller.activeIndex.value ?? 0].year} • ${items?[controller.activeIndex.value ?? 0].category?.first.name} / ${items?[controller.activeIndex.value ?? 0].category?.last.name}",
                              style: TextStyle(
                                shadows: [
                                  Shadow(
                                    offset: Offset(
                                        2.0, 2.0), // Độ lệch của bóng (x, y)
                                    blurRadius: 4.0, // Độ mờ của bóng
                                    color: Colors.black54, // Màu sắc của bóng
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "${items?[controller.activeIndex.value ?? 0].time}",
                              style: TextStyle(
                                shadows: [
                                  Shadow(
                                    offset: Offset(
                                        2.0, 2.0), // Độ lệch của bóng (x, y)
                                    blurRadius: 4.0, // Độ mờ của bóng
                                    color: Colors.black54, // Màu sắc của bóng
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            InkWell(
                                onFocusChange: (isFocus) {
                                  controller.isFocus.value = isFocus;
                                },
                                onTap: () {
                                  Get.to(DetailView(
                                    slug: items?[
                                            controller.activeIndex.value ?? 0]
                                        .slug,
                                    name: items?[
                                            controller.activeIndex.value ?? 0]
                                        .name,
                                  ));
                                },
                                child: Obx(
                                  () => AnimatedContainer(
                                    duration: Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                    transform: controller.isFocus.value
                                        ? Matrix4.diagonal3Values(1.05, 1.05, 1)
                                        : Matrix4.identity(),
                                    child: Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                .2,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 10),
                                        decoration: BoxDecoration(
                                            color: controller.isFocus.value
                                                ? Colors.black
                                                : Colors.transparent,
                                            border: Border.all(
                                              color: controller.isFocus.value
                                                  ? Colors.transparent
                                                  : Colors.white,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        child: Text(
                                          "XEM NGAY",
                                          textAlign: TextAlign.center,
                                        )),
                                  ),
                                ))
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            Container(
                              height: 100,
                              width: MediaQuery.of(context).size.width * .3,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ))
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

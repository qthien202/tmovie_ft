import 'package:app_ft_movies/app/controller/search/search_widget_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/filter/filter_page.dart';
import 'package:app_ft_movies/app/view/home/card_cinema/card_cinema.dart';
import 'package:app_ft_movies/app/view/home/card_cinema/card_thumbnail.dart';
import 'package:app_ft_movies/app/widgets/search_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SearchWidgetController());
    return RefreshIndicator(
      backgroundColor: GlobalColor.backgroundColor,
      color: GlobalColor.primary,
      onRefresh: () async => controller.onReady(),
      child: Scaffold(
        appBar: AppBar(
          foregroundColor: Colors.white,
          centerTitle: true,
          backgroundColor: GlobalColor.backgroundColor,
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SizedBox(
                width: MediaQuery.of(context).size.width * .4,
                child: const SearchWidget()),
          ),
          actions: [
            Obx(
              () => InkWell(
                onFocusChange: (hasFocus) {
                  controller.isFocusMenu.value = hasFocus;
                  print(">>>>>>>>>>>>>>>>>$hasFocus");
                },
                onTap: () {
                  Get.to(const FilterPage(),
                      transition: Transition.rightToLeft);
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: AnimatedContainer(
                    duration: Duration(seconds: 200),
                    curve: Curves.easeInOut,
                    child: Transform.scale(
                      scale: controller.isFocusMenu.value ? 1.2 : 1,
                      child: Container(
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: controller.isFocusMenu.value
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2)),
                        child: Icon(
                          Icons.menu,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
        backgroundColor: GlobalColor.backgroundColor,
        body: ListView(
          children: [
            const SizedBox(
              height: 10,
            ),
            Obx(() {
              final isLoading = controller.search.value == null;
              final data = controller.search.value?.pageProps?.data;

              // if (data?.items == null) {
              //   return Center(
              //     child: CircularProgressIndicator(
              //       strokeWidth: 5,
              //       backgroundColor: GlobalColor.primary,
              //     ),
              //   );
              // }
              if (data?.items?.isEmpty == true) {
                return const Center(
                  child: Text("Rất tiếc phim bạn tìm kiếm không tồn tại!"),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(5),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: isLoading ? 16 : data?.items?.length ?? 0,
                itemBuilder: (context, index) {
                  final items = data?.items?[index];
                  return Visibility(
                    visible: !isLoading,
                    replacement: SizedBox(
                        width: MediaQuery.of(context).size.width * .4,
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey,
                          highlightColor: Colors.grey.shade600,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.grey,
                            ),
                          ),
                        )),
                    child: CardThumbnail(
                      imageLink: items?.thumbUrl ?? "",
                      nameProduct: items?.name,
                      originName: items?.originName ?? "",
                      slug: items?.slug ?? "",
                    ),
                  );
                },
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  childAspectRatio: 6 / 13,
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 5,
                ),
              );
            }),
            const SizedBox(
              height: 20,
            ),
            Obx(() {
              final data =
                  controller.search.value?.pageProps?.data?.params?.pagination;
              return Visibility(
                visible: controller.totalPage.value != 0,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  child: SizedBox(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Nút "Previous"
                        IconButton(
                          icon: Icon(Icons.arrow_back),
                          onPressed: (data?.currentPage ?? 0) > 0
                              ? () async {
                                  await controller.getSearch(
                                      page: controller.currentPage.value + 1);
                                }
                              : null, // Disable if it's the first page
                        ),
                        // Các số trang
                        ListView.builder(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemCount: controller.totalPage.value,
                          itemBuilder: (context, index) {
                            return Obx(() {
                              return InkWell(
                                onFocusChange: (hasFocus) {
                                  controller.isFocusPage.value = hasFocus;
                                  controller.selectIndex.value = index;
                                },
                                onTap: () async {
                                  controller.selectIndex.value = index;
                                  await controller.getSearch(page: index + 1);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 15),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff252836),
                                    border: Border.all(
                                      color: controller.selectIndex.value ==
                                                  index &&
                                              controller.isFocusPage.value
                                          ? GlobalColor.primary
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Text(
                                    "${index + 1}",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          controller.selectPage.value == index
                                              ? GlobalColor.primary
                                              : Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            });
                          },
                        ),
                        // Nút "Next"
                        IconButton(
                          icon: Icon(Icons.arrow_forward),
                          onPressed: controller.currentPage.value <
                                  (controller.totalPage.value ?? 0) - 1
                              ? () async {
                                  controller.currentPage.value++;
                                  await controller.getSearch(
                                      page: controller.currentPage.value + 1);
                                }
                              : null, // Disable if it's the last page
                        ),
                      ],
                    ),
                  ),
                ),
              );
            })
          ],
        ),
      ),
    );
  }
}

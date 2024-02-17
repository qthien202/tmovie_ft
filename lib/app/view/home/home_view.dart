import 'package:app_ft_movies/app/controller/home/home_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/home/film_by_category/film_by_category.dart';
import 'package:app_ft_movies/app/view/home/slider/slider_cinema.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> listFilm = [
      {"slug": "phim-bo", "title": "Phim bộ"},
      {"slug": "phim-le", "title": "Phim lẻ"},
      {"slug": "tv-shows", "title": "TV Shows"},
      {"slug": "hoat-hinh", "title": "Hoạt hình"},
      {"slug": "phim-vietsub", "title": "Phim vietsub"},
      {"slug": "phim-thuyet-minh", "title": "Phim thuyết minh"},
      {"slug": "phim-long-tieng", "title": "Phim lồng tiếng"},
      {"slug": "phim-bo-dang-chieu", "title": "Phim bộ đang chiếu"},
      {"slug": "phim-hoan-thanh", "title": "Phim trọn bộ"},
      {"slug": "phim-sap-chieu", "title": "Phim sắp chiếu"}
    ];

    final controller = Get.put(HomeController());
    ScrollController scrollController = ScrollController();

    // Hàm xử lý khi chuyển tab
    void _handleTabChange(int newIndex) async {
      controller.pathFilm.value = listFilm[newIndex]['slug'];
      controller.tabIndex.value = newIndex;
      scrollController.jumpTo(0);
       controller.getFilm(slug: listFilm[newIndex]['slug']);
      controller.getFilmByCategory(slug: listFilm[newIndex]['slug']);

      // Thực hiện animate khi chuyển tab
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: GlobalColor.backgroundColor,
      body: RefreshIndicator(
        backgroundColor: GlobalColor.backgroundColor,
        color: GlobalColor.primary,
        onRefresh: () async {
          scrollController.jumpTo(0);
          await controller.getFilm(
              slug: listFilm[controller.tabIndex.value ?? 0]['slug']);
          controller.getFilmByCategory(
              slug: listFilm[controller.tabIndex.value ?? 0]['slug']);
        },
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverAppBar(
              pinned: true,
              centerTitle: false,
              title: Shortcuts(
                  shortcuts: <LogicalKeySet, Intent>{
                    LogicalKeySet(LogicalKeyboardKey.select):
                        const ActivateIntent(),
                  },
                  child: SizedBox(
                    height: 50,
                    child: ListView.separated(
                      // shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: listFilm.length,
                      itemBuilder: (context, index) {
                        return InkWell(
                            onFocusChange: (hasFocus) {
                              setState(() {
                                controller.tabIndex.value = index;
                                controller.isFocusTab.value = hasFocus;
                                print(
                                    ">>>>>>>>>>>>>${controller.isFocusTab.value}");
                                // _handleTabChange(index);
                              });
                            },
                            onTap: () {
                              controller.selectTab.value = index;
                              _handleTabChange(index);
                            },
                            child: AnimatedContainer(
                              duration: Duration(
                                  milliseconds: 200), // Thời gian hiệu ứng
                              curve: Curves.easeInOut,
                              transform: controller.isFocusTab.value
                                  ? Matrix4.identity() *
                                      Matrix4.diagonal3Values(1.1, 1.1, 1.0)
                                  : Matrix4.identity(),
                              child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    border: Border(
                                      bottom: BorderSide(
                                          color: controller.isFocusTab.value &&
                                                  controller.tabIndex.value ==
                                                      index
                                              ? GlobalColor.primary
                                              : Colors.transparent,
                                          width: 7),
                                    ),
                                  ),
                                  child: Text(
                                    listFilm[index]["title"],
                                    style: TextStyle(
                                        color: controller.tabIndex.value == index||
                                                controller.selectTab.value ==
                                                    index
                                            ? Colors.white
                                            : Colors.grey,
                                        fontSize: controller.isFocusTab.value &&
                                                controller.tabIndex.value ==
                                                    index
                                            ? 20
                                            : 16,
                                        fontWeight: FontWeight.bold),
                                  )),
                            ));
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return const SizedBox(
                          width: 20,
                        );
                      },
                    ),
                  )),
              elevation: 0.0,
              backgroundColor: GlobalColor.backgroundColor,
              expandedHeight: MediaQuery.of(context).size.height * .6,
              flexibleSpace: const FlexibleSpaceBar(
                background: SliderCinema(),
              ),
            ),
            const SliverToBoxAdapter(
              child: FilmByCategory(),
            )
          ],
        ),
      ),
    );
  }
}

import 'package:app_ft_movies/app/controller/home/home_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/filter/filter_page.dart';
import 'package:app_ft_movies/app/view/home/film_by_category/film_by_category.dart';
import 'package:app_ft_movies/app/view/home/slider/slider_cinema.dart';
import 'package:app_ft_movies/app/view/search/search_view.dart';
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
    List<Map<String, dynamic>> categories = [
      {"slug": "phim-bo", "title": "Phim bộ"},
      {"slug": "phim-le", "title": "Phim lẻ"},
      {"slug": "tv-shows", "title": "TV Shows"},
      {"slug": "hoat-hinh", "title": "Hoạt hình"},
    ];

    // List<Map<String,dynamic>> tabs =[
    //   {
    //     "title":"Trang chủ",
    //     'action':
    //   }
    // ]

    final controller = Get.put(HomeController());
    ScrollController scrollController = ScrollController();

    // Hàm xử lý khi chuyển tab
    void _handleTabChange(int newIndex) async {
      controller.pathFilm.value = categories[newIndex]['slug'];
      controller.tabIndex.value = newIndex;
      scrollController.jumpTo(0);
      controller.getFilm(slug: categories[newIndex]['slug']);
      controller.getFilmByCategory(slug: categories[newIndex]['slug']);

      // Thực hiện animate khi chuyển tab
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        backgroundColor: GlobalColor.backgroundColor,
        color: GlobalColor.primary,
        onRefresh: () async {
          scrollController.jumpTo(0);
          await controller.getFilm(
              slug: categories[controller.tabIndex.value ?? 0]['slug']);
        },
        child: Stack(
          alignment: Alignment.bottomCenter,
          // clipBehavior: Clip.none,
          children: [
            CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverAppBar(
                  // pinned: true,

                  centerTitle: false,

                  title: Shortcuts(
                      shortcuts: <LogicalKeySet, Intent>{
                        LogicalKeySet(LogicalKeyboardKey.select):
                            const ActivateIntent(),
                      },
                      child: SizedBox(
                          height: 50,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Image.asset(
                                    "assets/images/logo_app.png",
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                  Text(
                                    "TMOVIE",
                                    style: TextStyle(
                                        color: GlobalColor.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  ...categories.asMap().entries.map((entry) {
                                    final category = entry.value;
                                    final index = entry.key;
                                    bool hasFocus =
                                        controller.isFocusTab.value &&
                                            controller.tabIndex.value == index;
                                    return InkWell(
                                        onFocusChange: (hasFocus) {
                                          setState(() {
                                            controller.tabIndex.value = index;
                                            controller.isFocusTab.value =
                                                hasFocus;
                                            // print(
                                            //     ">>>>>>>>>>>>>${controller.isFocusTab.value}");
                                            // _handleTabChange(index);
                                          });
                                        },
                                        onTap: () {
                                          controller.selectTab.value = index;
                                          _handleTabChange(index);
                                        },
                                        child: Container(
                                            // alignment: Alignment.center,
                                            // padding: const EdgeInsets.all(1),
                                            margin: EdgeInsets.symmetric(
                                                horizontal: 10),
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 5),
                                            decoration: BoxDecoration(
                                                color: hasFocus
                                                    ? Colors.white
                                                    : Colors.transparent,
                                                borderRadius: hasFocus
                                                    ? BorderRadius.circular(16)
                                                    : null),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5),
                                              child: Text(
                                                category["title"],
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: hasFocus
                                                        ? Colors.black
                                                        : Colors.white,
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            )));
                                  }).toList()
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                      onPressed: () => Get.to(SearchView()),
                                      icon: Icon(
                                        Icons.search,
                                        color: Colors.white,
                                      )),
                                  Obx(
                                    () => InkWell(
                                      onFocusChange: (hasFocus) {
                                        controller.isFocusMenu.value = hasFocus;
                                        // print(">>>>>>>>>>>>>>>>>$hasFocus");
                                      },
                                      onTap: () {
                                        Get.to(const FilterPage(),
                                            transition: Transition.rightToLeft);
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: Transform.scale(
                                          scale: controller.isFocusMenu.value
                                              ? 1.2
                                              : 1,
                                          child: Icon(
                                            Icons.menu,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ))),
                  elevation: 0.0,
                  backgroundColor: GlobalColor.backgroundColor,
                  expandedHeight: MediaQuery.of(context).size.height,
                  flexibleSpace: const FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: SliderCinema(),
                    stretchModes: [StretchMode.blurBackground],
                  ),
                ),
              ],
            ),
            const Positioned.fill(top: 350, child: FilmByCategory())
          ],
        ),
      ),
    );
  }
}

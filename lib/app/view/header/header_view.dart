import 'package:app_ft_movies/app/controller/filter/filter_controller.dart';
import 'package:app_ft_movies/app/controller/home/home_controller.dart';
import 'package:app_ft_movies/app/controller/search/search_widget_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/filter/filter_app.dart';
import 'package:app_ft_movies/app/view/home/home_view.dart';
import 'package:app_ft_movies/app/widgets/search_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HeaderPage extends StatelessWidget {
  const HeaderPage({super.key, });
  

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    final searchController = Get.put(SearchWidgetController());
    final filterController = Get.put(FilterController());
    return SliverAppBar(
      pinned: false,
      centerTitle: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Visibility(
            visible: MediaQuery.of(context).size.width > 600,
            child: InkWell(
              onTap: () => Get.toNamed('/'),
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Text(
                  "TMOVIE",
                  style: TextStyle(
                      fontSize: 25,
                      color: GlobalColor.primary,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          Expanded(
            flex: MediaQuery.of(context).size.width > 600 ? 3 : 1,
            child: TabBar(
              tabAlignment: TabAlignment.start,
              // indicatorWeight: 1,
              isScrollable: true,
              dividerColor: Colors.transparent,
              indicatorColor: Colors.transparent,
              unselectedLabelColor: Colors.grey,
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
              labelColor: Colors.white,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              onTap: (ind) async {
                searchController.onStop();
                filterController.onStop();
                controller.pathFilm.value = controller.tabItem[ind]['slug'];
                controller.tabIndex.value = ind;
                controller.scrollController.value?.jumpTo(0);
                Get.toNamed('/');
                await controller.getFilm(slug: controller.tabItem[ind]['slug']);
                controller.getFilmByCategory(slug: controller.tabItem[ind]['slug']);
              },
              tabs: List<Widget>.generate(controller.tabItem.length ?? 0, (int index) {
                return Tab(
                  text: controller.tabItem[index]["title"],
                );
              }),
            ),
          ),
          MediaQuery.of(context).size.width >= 800
              ? const Expanded(
                flex: 1,
                  child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SearchWidget(),
                ))
              : const SizedBox(),
        ],
      ),

      // actions: [
      //   Visibility(
      //     visible: MediaQuery.of(context).size.width > 600,
      //     child: IconButton(
      //         onPressed: () => Get.to(const FilterApp()),
      //         icon: const Icon(
      //           Icons.filter_alt_outlined,
      //           color: Colors.white,
      //         )),
      //   )
      // ],
      bottom: MediaQuery.of(context).size.width < 800
          ? PreferredSize(
              preferredSize: Size.fromHeight(56.0),
              child: Row(
                children: [
                  const Expanded(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                      child: SearchWidget(),
                    ),
                  ),
                  IconButton(
                      onPressed: () => Get.to(const FilterApp()),
                      icon: const Icon(
                        Icons.filter_alt_outlined,
                        color: Colors.white,
                      )),
                ],
              ),
            )
          : null,
      // elevation: 0.0,
      backgroundColor: GlobalColor.backgroundColor,
      // systemOverlayStyle: const SystemUiOverlayStyle(
      //     statusBarBrightness: Brightness.dark),
      // expandedHeight: MediaQuery.of(context).size.height * .8,
      // flexibleSpace: const FlexibleSpaceBar(
      //   background: SliderCinema(),
      // ),
    );
  }
}
